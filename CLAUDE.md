# CLAUDE.md

## Project Overview

Hugo-based personal blog using theme [Nothing](https://github.com/person-c/Nothing) (self-built, imported as a Hugo Module — the pinned version lives in `go.mod`), deployed on Vercel (https://cying.org).

### Directory Structure

```
content/
  blog/         # Technical blog (R, ggplot2, bioinformatics, tools)
  note/         # Technical notes (R Markdown → HTML, math/stats)
  ramblings/    # Personal musings
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

Deterministic checks and preview (what they enforce is in the review directives):

```sh
Rscript scripts/check-math.R content/note      # math litedown will not protect
Rscript scripts/check-meta.R content/note      # YAML front matter
sh scripts/preview.sh content/note/foo.Rmd     # reuse or start the litedown preview server
```

Pipeline facts worth remembering:

- Notes are rendered by **litedown** (`litedown::fuse()` — knitr + markdown in one step), **not** Quarto or rmarkdown: its chunk options and global defaults (`litedown::reactor()`) are its own, so Quarto's equivalents are silently ignored. Everything litedown-specific — option and device rules, code folding, the math-protection rules that decide whether a formula renders at all, the plotly JS route, `<input>__files/` — is in **`docs/litedown.md`**: read it when rendering a note or touching math or figures. The source clone is at `reference/litedown/` (gitignored; re-clone from https://github.com/yihui/litedown if missing).
- `hugo.toml` sets `ignoreFiles = ["\\.Rmd$"]`: the `.Rmd` is never built, so the rendered **`.html` is the published page and has to be committed**. Editing the `.Rmd` alone changes nothing online until it is re-rendered.
- Production builds run on Vercel, with the Hugo version pinned in `vercel.json`. `hugo mod get -u` upgrades every module including the theme; the pinned version lives in `go.mod`, not here.

---

## Git conventions

- **One commit per task that can be verified or reverted on its own.** Split by task, not by file: when one file's changes belong to two tasks, stage at hunk level — build a patch holding only the target hunks, `git apply --cached` it, then check the split with `git diff --cached --stat` against `git diff --stat`.
- **A commit message carries its own acceptance evidence.** First line `type: <Chinese summary>` (`fix` / `docs` / `chore` / `content` …); the body states what changed, **how it was verified** (commands, counts, render or preview results) and what is left open, so the commit can be reviewed or reverted from the message alone. AI-authored commits end with `Co-Authored-By: Claude Code <noreply@anthropic.com>`.
- **Order: everything outside `content/` first, notes and logs after.** Tools, scripts, CI and this file go in first; notes, logs and articles under `content/` get commits of their own — a re-rendered `.html` runs to thousands of diff lines and buries whatever it is mixed with. Run `git status --short` first so generated output (`public/`, `<input>__files/`) and scratch files stay out.
- **A note's `.Rmd` and its `.html` go in the same commit.** `hugo.toml` ignores the `.Rmd`, so the `.html` is what the site publishes; committing one without the other leaves source and site disagreeing. Run `scripts/check-math.R` and `scripts/check-meta.R` first, and `scripts/preview.sh` when the look matters.
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
