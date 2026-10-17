# AGENTS.md

> **Agent instruction files.** This file is the single source of truth and is read natively by most coding agents (Codex, Cursor, GitHub Copilot, Windsurf, Aider, …). `CLAUDE.md` (Claude Code) is a thin adapter that imports it. The article-review workflow lives in `.agents/skills/review-article/` (Open Agent Skills format), so any agent can discover and follow it. Edit the rules here — never duplicate them into the adapters.

## Project Overview

Hugo-based personal blog using theme [Nothing](https://github.com/person-c/Nothing) (self-built, imported as a Hugo Module — the pinned version lives in `go.mod`), deployed on Vercel (https://cying.org).

### Directory Structure

```
content/
  blog/         # Technical blog (R, ggplot2, bioinformatics, tools)
  note/         # Technical notes (R Markdown → HTML, math/stats)
  ramblings/    # Personal musings — a gitlink, not files in this repo (docs/build.md)
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

Render a note (`.Rmd` → `.html`) **in the file's own directory** — image paths in the `.Rmd` are relative to it. PowerShell eats the inner double quotes of the form below (`Error: object '…Rmd' not found`), so swap the quoting there: `Rscript -e "litedown::fuse('foo.Rmd')"`.

```sh
cd content/note && Rscript -e 'litedown::fuse("2025-09-02-introduction-to-linear-algebra.Rmd")'
```

Deterministic checks and preview. `make` on Windows may need `make SHELL=cmd.exe` (see docs/build.md):

```sh
make check                                     # the four checks CI runs
make check-fresh                               # re-renders to compare; commit first
sh scripts/preview.sh content/note/foo.Rmd     # reuse or start the litedown preview server
```

Pipeline facts worth remembering:

- Notes are rendered by **litedown** (`litedown::fuse()` — knitr + markdown in one step), **not** Quarto or rmarkdown: its chunk options and global defaults (`litedown::reactor()`) are its own, so Quarto's equivalents are silently ignored. Everything litedown-specific — option and device rules, code folding, the math-protection rules that decide whether a formula renders at all, the plotly JS route, `<input>__files/` — is in **`docs/litedown.md`**: read it when rendering a note or touching math or figures. The source clone is at `reference/litedown/` (gitignored; re-clone from https://github.com/yihui/litedown if missing).
- `hugo.toml` sets `ignoreFiles = ["\\.Rmd$"]`: the `.Rmd` is never built, so the rendered **`.html` is the published page and has to be committed**. Editing the `.Rmd` alone changes nothing online until it is re-rendered. The two can drift without any source-level check noticing, which is why the checks exist and what each one can see is in **`docs/build.md`**.
- Production builds run on Vercel, with the Hugo version pinned in `vercel.json`. `hugo mod get -u` upgrades every module including the theme; the pinned version lives in `go.mod`, not here.

---

## Git conventions

- **A task ends with a report, not a commit — the user reviews first.** Do the work and its verification, then report what changed, how it was verified and what is left open, and stop. `git add` / `git commit` wait for an explicit go-ahead (「提交」): do not run them on your own, and do not close a report by asking whether to commit. Read-only inspection, renders and the checks are still yours to run on your own — only the commit gate belongs to the user.
- **One commit per task that can be verified or reverted on its own.** Split by task, not by file: when one file's changes belong to two tasks, stage at hunk level — build a patch holding only the target hunks, `git apply --cached` it, then check the split with `git diff --cached --stat` against `git diff --stat`.
- **A commit message carries its own acceptance evidence.** First line `type: <Chinese summary>` (`fix` / `docs` / `chore` / `content` …); the body states what changed, **how it was verified** (commands, counts, render or preview results) and what is left open, so the commit can be reviewed or reverted from the message alone. AI-authored commits carry **no `Co-Authored-By:` trailer at all** — neither the model name nor the tool name belongs in the message; the evidence in the body is what makes the commit reviewable.
- **Order: everything outside `content/` first, notes and logs after.** Tools, scripts, CI and this file go in first; notes, logs and articles under `content/` get commits of their own — a re-rendered `.html` runs to thousands of diff lines and buries whatever it is mixed with. Run `git status --short` first so generated output (`public/`, `<input>__files/`) and scratch files stay out.
- **A note's `.Rmd` and its `.html` go in the same commit.** `hugo.toml` ignores the `.Rmd`, so the `.html` is what the site publishes; committing one without the other leaves source and site disagreeing. Run `make check` first — it is the same set CI runs — and `make check-fresh` when a `.Rmd` changed, since only a render can tell whether its `.html` caught up. **`check-fresh` renders in place and restores what it found, so commit or stash first** — an uncommitted `.Rmd` is rendered and then reset to its committed content. `scripts/preview.sh` when the look matters.
- **Say in the message when review annotations are left in on purpose** (how many, in which file): publishing them is the policy above, and saying so keeps a later reader from taking them for missed cleanup.
- **Do not push unasked.** A push to `main` triggers the Vercel production build (cying.org) — an outward-facing action. Accumulating several local commits is normal. To check the whole site before a push, use `hugo server --noHTTPCache --disableFastRender`.

---

## Writing conventions

### Site conventions

- **Annotation language: Chinese.** Annotation blocks and the review summary are written in Chinese; quoted source text stays as it is.
- **Notation: consistent within an article — and an article that is already self-consistent keeps its own choice** (see the convention note in `.agents/skills/review-article/references/sources.md`). Do not rewrite notation wholesale; flag mixing as `[Clarity]` and name both forms.
- **Annotations** carry `class="review-note"`, and publishing them is intentional — some articles are meant to show the review notes so readers can judge the author's and the AI's views side by side. Raw HTML passes through litedown untouched (verified), so an annotation in a `.Rmd` reaches the page as soon as that `.Rmd` is re-rendered, and in a `.md` file Hugo renders it via `unsafe = true` — either way, a committed annotation is a published one. Use `scripts/clear-review-notes.sh` when the clean version is wanted; `.github/workflows/annotation-guard.yml` just reports what is public.
- **Math in annotations:** Formulas intended to be rendered by KaTeX must be written as standard `$formula$` or `$$...$$` with proper whitespace protection, **never** wrapped in code backticks (e.g. write `$c = \binom{k}{2}$`, never `` `$c = \binom{k}{2}$` `` — backticks compile to `<code>`, which KaTeX skips, leaving raw LaTeX in the browser). Reserve code backticks strictly for quoting broken/malformed snippets (e.g. `` `t_b \pm` ``).

| Convention | Adopted form |
| --- | --- |
| Transpose | `A^{\mathrm{T}}` — upright superscript T (ISO 80000-2: transpose is a superscript T; descriptive superscripts are upright, italics are reserved for variables). The three linear-algebra notes were unified on 2026-10-10 |
| Vectors | `\mathbf{x}` (already uniform in the body text — keep it) |
| Technical terms | Follow 全国科学技术名词审定委员会 (China National Committee for Terms in Sciences and Technologies), e.g. 若尔当标准形, 奇异值分解 |

Record further decisions in this table.

---

## Article Review

Triggered by "审查文章", "审稿", "review", or an article file path. Follow **`.agents/skills/review-article/SKILL.md`** — it is the canonical, tool-neutral workflow (Open Agent Skills format): the annotation and summary templates, the review-intensity table, and the R/Python/metadata checklists, with the citation protocol under its `references/`. Any agent can read it; no vendor-specific skill mechanism is required.

One rule applies whether or not the workflow file is loaded: **every critique is evidence-based** — an `[Accuracy]` or `[Render]` claim carries Run, Quote, or Derivation evidence, or it is downgraded to `[Question]` / `[Suggestion]` (see `.agents/skills/review-article/references/verification.md`); the citation protocol is in `references/sources.md`.
