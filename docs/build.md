# build, checks and this checkout's quirks

Reference material for how this repo is built and checked. `AGENTS.md` keeps the
project-level rules and points here; the detail behind those rules — the Makefile
targets, what each checker can and cannot see, and the environment problems this
particular checkout has — lives here.

litedown itself is a separate subject: rendering rules, chunk options, the
math-protection rules and their gotchas are in `docs/litedown.md`.

## Makefile

```
make check           the four deterministic checks CI runs
make check-all       check + check-fresh
make check-fresh     re-render every .Rmd and compare with the committed .html
make render          re-render the .Rmd that are newer than their .html
make render-force    re-render every .Rmd regardless of timestamps
make serve           hugo server, no cache, no fast render
make site            production build
make versions        tool versions this checkout is built with
make clean           remove public/
```

`scripts/run.R` holds the work: every recipe is a single command with no `cd`,
`echo`, globs or line continuations, because `make` hands recipes to a different
shell depending on the platform (sh on Unix, cmd.exe or PowerShell on Windows).
Keeping the recipes shell-free is what makes `make check` work from PowerShell,
where `sh` is not on PATH at all.

### Windows: which shell make picks

Measured here, `make -p` reports:

```
SHELL := C:/rtools45/usr/bin/sh.exe
```

That is Rtools' sh, inherited from the Rtools PATH. If it cannot start, **every
target fails before any recipe runs** — the error is

```
sh.exe: *** fatal error - couldn't create signal pipe, Win32 error 5
make: *** [Makefile:NN: target] Error -1073741502
```

which reads like a Makefile problem but is not. Point make at cmd instead; the
recipes need no shell syntax, so this is enough:

```
make SHELL=cmd.exe check
set MAKESHELL=cmd.exe && make check        (cmd.exe, for the whole session)
```

Verified this way on 2026-10-10: `check`, `versions`, `render`, `render-force`,
`site`, `clean` and `check-fresh` all ran to completion, and `render-force`
reproduced all five products byte-for-byte (their blob hashes matched `HEAD`).
The one path not exercised is a real `/bin/sh`.

## The checks

CI (`.github/workflows/content-checks.yml`) runs the first four on every push and
pull request; they are hard gates. The fifth re-renders, so it is local-only.

| script | what it sees | where |
| --- | --- | --- |
| `check-math.R` | formulas litedown will not protect, so they never typeset in the browser | CI |
| `check-meta.R` | YAML front matter: title, date, draft, tags | CI |
| `check-products.R` | every committed `.html` built by the same litedown, and not behind the installed one | CI |
| `check-repo.R` | `layout:` names, the dead `paginate` key, workflow YAML, static assets | CI |
| `check-fresh.R` | whether each committed `.html` is what its `.Rmd` renders to right now | local |
| `check-render.R` | the rendered page: TeX that will not parse, a `$` left in text, figure/caption balance, TOC presence and depth, a dead `@fold-details` | on demand |

`check-render.R` is not in `make check` or CI — it reads the rendered `.html`, so it
only helps after a render. The article-review workflow runs it in Step 0
(`.agents/skills/review-article/SKILL.md`); run it by hand after editing a formula.
It lints the TeX KaTeX actually receives, which is the only place a missing brace or
a `\left` without `\right` shows up: KaTeX runs in the browser, so a broken formula
is invisible in the `.html` file itself.

### Why two different product checks

Because they cover different halves of the same failure, and only one of them is
cheap.

`check-products.R` reads the litedown version each page records in its
`<meta name="generator">`, and reports two things:

- **versions differing between products** — always a fault. It means some pages
  were re-rendered and others were not. This is the state that was actually found
  here: 0.7, 0.9 and 0.11 in one tree.
- **the common version against the installed one** — a product ahead of the
  installed litedown is impossible; a product behind it means the tree is due for
  a re-render.

It deliberately does **not** compare against CRAN. CI installs whatever CRAN
ships, so a new CRAN release while the tree sits at an older version is exactly
the drift worth hearing about, not a false positive.

What it cannot see is a `.Rmd` edited without a re-render — the version stamp is
unchanged by that. Only a real render can tell, and that is `check-fresh.R`.

`check-fresh.R` is expensive and awkward by necessity:

- It must render **in place**. A note's image paths are relative to its own
  directory (the linear-algebra note embeds `../../static/images-note/...`), so
  rendering from a scratch directory fails to embed them.
- It copies each `.html` aside first and restores in a `finally`, so the working
  tree survives even a failed or interrupted run (verified by killing it
  mid-render: all five products came back with their `HEAD` blob hashes).
- Two differences are inherent to a re-render and are normalised away rather than
  reported: the date evaluated from `` `{r} Sys.Date()` `` and the litedown
  version itself. See `docs/litedown.md`, "Two things every re-render rewrites".

Because it renders in place, **commit or stash before running it**: an
uncommitted `.Rmd` is rendered and compared, then reset to its `HEAD` content
along with everything else.

### A note's variables leak into the notes rendered after it

`check-fresh.R` and `render-force` render every `.Rmd` **in one R process**, so
whatever a note's chunks assign is still in the session for the notes that
follow. Shadowing a name base R already uses therefore breaks *another* note,
and the report names the victim, not the culprit:

```
2025-02-02-statistics.Rmd                            OK  (litedown 0.11)
2025-09-02-introduction-to-linear-algebra.Rmd        RENDER FAILED
     'to' must be of length 1
1 of 5 product(s) need attention
Re-render and commit the .html together with its .Rmd.
```

Measured 2026-10-11: the statistics note had assigned `pi` (a data frame from
`predict()`), so the linear-algebra note's eigen figure ran
`th <- seq(0, 2 * pi, length.out = 200)` with `pi` no longer the constant and
`seq()`'s `to` came out with three elements. `beta` and `outer` were shadowed in
the same batch. Before touching the note that failed, check the names the
earlier ones assign:

```r
x  <- readLines(f)
x  <- x[grepl("^[[:space:]]*[a-zA-Z_.][a-zA-Z0-9_.]*[[:space:]]*<-", x)]
nm <- unique(sub("^[[:space:]]*([a-zA-Z_.][a-zA-Z0-9_.]*)[[:space:]]*<-.*", "\\1", x))
intersect(nm, c(ls(baseenv()), ls("package:stats"), ls("package:graphics"),
                ls("package:grDevices")))
```

In practice: avoid `pi`, `T`, `F` and the short function names (`beta`, `outer`,
`df`, `dt`, `t`, `c`, `I`). Renaming changes nothing in the output — variable
names never reach the page, and a note with `echo = FALSE` does not print its
code — so the fix is a `.Rmd`-only edit, after which `check-fresh` reports every
product OK.

## `content/ramblings` is a gitlink, not a directory

Git records it as a submodule commit, not as files:

```
$ git ls-files -s content/ramblings
160000 1b7da2079f54063fadaaf373434c87edeeea3bf3 0	content/ramblings
```

There is **no `.gitmodules`**. It was deleted on 2025-06-15 by `9ab3741`
("Migrate theme from Git Submodule to Hugo Modules"), and that file had only ever
declared `themes/Nothing` — never this path. So the gitlink has no submodule
configuration behind it at all, and `git submodule status` prints nothing because
without `.gitmodules` git does not treat the path as a submodule.

Consequences, all verified:

- `git archive HEAD` and a fresh clone carry **nothing** for that path — it comes
  out as an empty directory. So the 22 files are not in this repository; they
  exist only in a working copy that still has the submodule.
- The recorded commit is `1b7da20`. Inside the submodule, local `main` and
  `origin/main` match, so it was pushed at some point.
- The declared remote is `https://github.com/person-c/daily_life.git`, which
  returned 404 on 2026-10-10 — an unauthenticated 404 cannot distinguish
  "deleted" from "made private".

Two further reasons nothing shows up on the live site: the section is absent from
`hugo.toml`'s `[menu]` (the fallback branch in `layouts/partials/header.html` that
would add it only runs when `Site.Menus.main` is empty, which it is not), and
`_default/single.html` renders it as empty under `hugo.IsProduction`.

Do not edit files under that path expecting this repository to track the change:
commit inside the submodule, or convert it to ordinary content first.

## This checkout cannot write git's index

The D: volume this repo sits on refuses to unlink files, so git cannot create or
remove `.git/index.lock`:

```
warning: unable to unlink '.git/index.lock': Invalid argument
fatal: unable to write new index file
```

`git add` and `git commit` then fail with "Another git process seems to be
running in this repository", which is misleading — there is no other process; a
zero-byte or stale lock simply cannot be removed.

Working around it, if it bites:

```powershell
# commit with the index kept off this volume
$env:GIT_INDEX_FILE = "$env:TEMP\dsh-index"
git read-tree HEAD
git add -- <paths>
git update-ref refs/heads/main (git commit-tree (git write-tree) -p HEAD -F msg.txt)
```

`git commit-tree` + `git update-ref` produce an ordinary commit; the tree is
identical to what `git commit` would have written. Afterwards `git reset --mixed
HEAD` re-syncs the real index so `git status` is accurate again.
