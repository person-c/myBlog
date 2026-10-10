# CLAUDE.md

## Project Overview

Hugo-based personal blog using theme [Nothing](https://github.com/person-c/Nothing) (self-built, imported as a Hugo Module — the pinned version lives in `go.mod`), deployed on Vercel (https://cying.org).

### Directory Structure

```
content/
  blog/         # Technical blog (R, ggplot2, bioinformatics, tools)
  note/         # Technical notes (R Markdown → HTML, math/stats)
  ramblings/    # Personal musings — NOT a normal directory, see below
  slides/       # Presentations (R Markdown + PDF)
  books/        # E-book collection (EPUB format)
    _index.md   # Bookshelf landing page
    出版小说/   # Published novels
    知识/       # Knowledge / non-fiction
    代码统计/   # Code statistics
    股票生活/   # Stock & life
```

### Common Commands

```sh
hugo server --noHTTPCache --disableFastRender          # local Hugo preview
hugo mod clean && hugo mod get -u && hugo mod vendor   # upgrade modules — only when intended
```

Render a note (`.Rmd` → `.html`) **in the file's own directory** — image paths in the `.Rmd` are relative to it:

```sh
cd content/note && Rscript -e 'litedown::fuse("2025-09-02-introduction-to-linear-algebra.Rmd")'
```

**PowerShell eats the inner double quotes** — the command above fails there with
`Error: object '…Rmd' not found` (measured 2026-10-10). Swap the quoting:

```powershell
cd content/note; Rscript -e "litedown::fuse('2025-09-02-introduction-to-linear-algebra.Rmd')"
```

Deterministic checks and preview (what they enforce is in the review directives):

```sh
make check                                     # the four deterministic checks CI runs
make check-all                                 # + check-fresh (re-renders; read below)
sh scripts/preview.sh content/note/foo.Rmd     # reuse or start the litedown preview server
```

On Windows, `make` may pick up Rtools' `sh.exe` as its shell (measured here: `make -p`
reports `SHELL := C:/rtools45/usr/bin/sh.exe`). The recipes are written to need no shell
syntax at all, so pointing make at cmd is enough if that sh misbehaves:

```powershell
make SHELL=cmd.exe check
```

The individual scripts, if you want one at a time:

```sh
Rscript scripts/check-math.R content           # math litedown will not protect
Rscript scripts/check-meta.R content           # YAML front matter
Rscript scripts/check-products.R content       # every .html built by the same litedown
Rscript scripts/check-repo.R                   # layout names, paginate key, workflow YAML
Rscript scripts/check-fresh.R content          # re-render and compare (expensive, local)
```

Pipeline facts worth remembering:

- Notes are rendered by **litedown** (`litedown::fuse()` — knitr + markdown in one step), **not** Quarto or rmarkdown: its chunk options and global defaults (`litedown::reactor()`) are its own, so Quarto's equivalents are silently ignored. Everything litedown-specific — option and device rules, code folding, the math-protection rules that decide whether a formula renders at all, the plotly JS route, `<input>__files/` — is in **`docs/litedown.md`**: read it when rendering a note or touching math or figures. The source clone is at `reference/litedown/` (gitignored; re-clone from https://github.com/yihui/litedown if missing).
- `hugo.toml` sets `ignoreFiles = ["\\.Rmd$"]`: the `.Rmd` is never built, so the rendered **`.html` is the published page and has to be committed**. Editing the `.Rmd` alone changes nothing online until it is re-rendered.
- **Source and product drift have their own checks, and they only cover what they can see.** `check-products.R` (in CI) reads the litedown version each page recorded in its `<meta name="generator">` — it catches pages left behind by a version bump, and pages re-rendered out of step with each other, but it cannot see a `.Rmd` edited without a re-render. That needs a real render: `make check-fresh`, which is local-only because it re-renders all five sources. **It renders in place and then restores what it found**, so commit (or stash) first — an uncommitted `.Rmd` is rendered, compared, then reset to its HEAD content along with everything else.
- Production builds run on Vercel, with the Hugo version pinned in `vercel.json`. `hugo mod get -u` upgrades every module including the theme; the pinned version lives in `go.mod`, not here.
- **`content/ramblings/` is a gitlink, not a directory.** Git records it as `160000 … content/ramblings` — a submodule commit — and there is **no `.gitmodules`**: that file was deleted on 2025-06-15 (commit `9ab3741`, "Migrate theme from Git Submodule to Hugo Modules"), and it had only ever declared `themes/Nothing`, never this path. Consequences: `git archive HEAD` and a fresh clone carry nothing for that path (verified), so the 22 files exist only in a working copy that still has the submodule; the recorded commit is `1b7da20`; the declared remote is `https://github.com/person-c/daily_life.git`, whose page returns 404 as of 2026-10-10. `git submodule status` prints nothing, because without `.gitmodules` git does not treat it as a submodule at all. Do not edit files under it expecting the change to be tracked by this repository — commit inside it, or convert it to ordinary content first.

---

## Git conventions

- **One commit per task that can be verified or reverted on its own.** Split by task, not by file: when one file's changes belong to two tasks, stage at hunk level — build a patch holding only the target hunks, `git apply --cached` it, then check the split with `git diff --cached --stat` against `git diff --stat`.
- **A commit message carries its own acceptance evidence.** First line `type: <Chinese summary>` (`fix` / `docs` / `chore` / `content` …); the body states what changed, **how it was verified** (commands, counts, render or preview results) and what is left open, so the commit can be reviewed or reverted from the message alone. AI-authored commits end with `Co-Authored-By: Claude Code <noreply@anthropic.com>`.
- **Order: everything outside `content/` first, notes and logs after.** Tools, scripts, CI and this file go in first; notes, logs and articles under `content/` get commits of their own — a re-rendered `.html` runs to thousands of diff lines and buries whatever it is mixed with. Run `git status --short` first so generated output (`public/`, `<input>__files/`) and scratch files stay out.
- **A note's `.Rmd` and its `.html` go in the same commit.** `hugo.toml` ignores the `.Rmd`, so the `.html` is what the site publishes; committing one without the other leaves source and site disagreeing. Run `make check` first — it is the same set CI runs — and `make check-fresh` when a `.Rmd` changed, since only a render can tell whether its `.html` caught up. `scripts/preview.sh` when the look matters.
- **Say in the message when review annotations are left in on purpose** (how many, in which file): publishing them is the policy above, and saying so keeps a later reader from taking them for missed cleanup.
- **Do not push unasked.** A push to `main` triggers the Vercel production build (cying.org) — an outward-facing action. Accumulating several local commits is normal. To check the whole site before a push, use `hugo server --noHTTPCache --disableFastRender`.

---

## Writing conventions

### Site conventions

- **Annotation language: Chinese.** Annotation blocks and the review summary are written in Chinese; quoted source text stays as it is.
- **Notation: consistent within an article — and an article that is already self-consistent keeps its own choice** (see the convention note in `.claude/skills/review-article/references/sources.md`). Do not rewrite notation wholesale; flag mixing as `[Clarity]` and name both forms.
- **Annotations** carry `class="review-note"`, and publishing them is intentional — some articles are meant to show the review notes so readers can judge the author's and the AI's views side by side. Raw HTML passes through litedown untouched (verified), so an annotation in a `.Rmd` reaches the page as soon as that `.Rmd` is re-rendered, and in a `.md` file Hugo renders it via `unsafe = true` — either way, a committed annotation is a published one. Use `scripts/clear-review-notes.sh` when the clean version is wanted; `.github/workflows/annotation-guard.yml` just reports what is public.

| Convention | Adopted form |
| --- | --- |
| Transpose | `A^{\mathrm{T}}` — upright superscript T (ISO 80000-2: transpose is a superscript T; descriptive superscripts are upright, italics are reserved for variables). The three linear-algebra notes were unified on 2026-10-10 |
| Vectors | `\mathbf{x}` (already uniform in the body text — keep it) |
| Technical terms | Follow 全国科学技术名词审定委员会 (China National Committee for Terms in Sciences and Technologies), e.g. 若尔当标准形, 奇异值分解 |

Record further decisions in this table.

---

## Article Review

Triggered by `/review-article <path>`, "审查文章", "review", or an article file path. Use the **`review-article`** skill — `.claude/skills/review-article/SKILL.md` carries the workflow, the annotation and summary templates, the review-intensity table, and the R/Python/metadata checklists, with the citation protocol under its `references/`. Read that file if the skill is not loaded.

One rule applies whether or not the skill is loaded: **every critique is evidence-based** — cite the canonical source, or downgrade to `[Suggestion]` (see `.claude/skills/review-article/references/sources.md`).
