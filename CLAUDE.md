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

Render a note (`.Rmd` → `.html`). Run it **in the file's own directory**: image paths in the `.Rmd` are relative to it.

```sh
cd content/note && Rscript -e 'litedown::fuse("2025-09-02-introduction-to-linear-algebra-review.Rmd")'
```

Deterministic checks and preview (what they enforce is in the review directives):

```sh
Rscript scripts/check-math.R content/note      # math litedown will not protect
Rscript scripts/check-meta.R content/note      # YAML front matter
sh scripts/preview.sh content/note/foo.Rmd     # reuse or start the litedown preview server
```

Pipeline facts worth remembering:

- Notes are rendered by **litedown** (`litedown::fuse()` — knitr + markdown in one step), **not** Quarto or rmarkdown. Quarto-only options (`code-fold:`, `fig-format:`, `#| ...`) are silently ignored, so do not introduce them; plotly output has not been verified under litedown, test it before relying on it.
- `hugo.toml` sets `ignoreFiles = ["\\.Rmd$"]`: the `.Rmd` is never built, so the rendered **`.html` is the published page and has to be committed**. Editing the `.Rmd` alone changes nothing online until it is re-rendered.
- `hugo mod get -u` upgrades every module, the theme included. The pinned version is in `go.mod`; do not copy version numbers into this file.
- Production builds run on Vercel, with the Hugo version pinned in `vercel.json`.

---

## Writing conventions

### litedown math rules (`.Rmd`)

litedown delegates math protection to `xfun::protect_math()`, which shields only the math that matches xfun's heuristics. Anything else is handed to the Markdown parser as ordinary text and silently corrupted (`\\` → `\`, `\,` → `,`, `\|` → `|`, `^` → `<sup>`, `_` → `<em>`, `'` → `’`, and a lone `=` line turns the preceding lines into a setext heading). Since KaTeX auto-render accepts only `$$…$$`, `\(…\)` and `\[…\]`, the formula then fails to render at all in the browser. Flag every violation as `[Render]`.

- Inline `$...$`: the opening `$` must be preceded by whitespace, an ASCII `(`, or the start of a line. Flag as `[Render]` — `、$LU$`、`：$C$`、`（$A$ 可逆）` are all broken, because a full-width `（` is not `(`, and CJK punctuation is not whitespace. The closing `$` must not be followed by a digit, and no space may sit just inside either delimiter. **Fix:** insert one space before the `$` (this is also the standard gap between Chinese text and Western symbols).
- Display `$$...$$`: a multi-line block is protected only when the opening `$$` is glued to its content and the closing `$$` is glued to the end of the last content line — `$$\begin{aligned}` … `\end{aligned}$$`. A `$$` alone on its own line is never protected. Flag as `[Render]`. **Fix:** move the delimiters onto the content lines. (xfun's own documentation says multi-line `$$…$$` is supported, so this is a tool limitation to code around, not an error in the author's LaTeX.)
- Never settle for repairing the rendered `.html` — it is generated output, and `litedown::roam()` re-renders the `.Rmd` live without writing `.html` at all. Fix the `.Rmd` and re-render.
- Reference: `?xfun::protect_math` (Details) and `xfun:::escape_math()`; rules verified against litedown 0.10.1 / xfun 0.56 (an `.Rmd` that satisfies them renders with zero mis-converted formulas).

- Exact check: `Rscript scripts/check-math.R <file>` — the same rule, computed with `xfun::protect_math()` + `xfun::prose_index()`, plus the display blocks whose `$$` sits alone on its line.

### Site conventions

- **Annotation language: Chinese.** Annotation blocks and the review summary are written in Chinese; quoted 原文 stays as it is.
- **Notation: consistent within an article — and an article that is already self-consistent keeps its own choice** (see the convention note in `.claude/skills/review-article/references/sources.md`). Do not rewrite notation wholesale; flag mixing as `[Clarity]` and name both forms.
- **Annotations** carry `class="review-note"`, and publishing them is intentional — some articles are meant to show the review notes so readers can judge the author's and the AI's views side by side. Raw HTML passes through litedown untouched (verified), so an annotation in a `.Rmd` reaches the page as soon as that `.Rmd` is re-rendered, and in a `.md` file Hugo renders it via `unsafe = true` — either way, a committed annotation is a published one. Use `scripts/clear-review-notes.sh` when the clean version is wanted; `.github/workflows/annotation-guard.yml` just reports what is public.

| Convention | Adopted form |
| --- | --- |
| 转置 | `A^{\mathrm{T}}` —— 正体上标 T（依据 ISO 80000-2：转置即上标 T；描述性上标用正体，斜体留给变量）。三份线代笔记已于 2026-10-10 统一 |
| 向量 | `\mathbf{x}`（正文已统一，保持一致） |
| 科技术语 | 以全国科学技术名词审定委员会为准（如 若尔当标准形、奇异值分解） |

Record further decisions in this table.

---

## Article Review

Triggered by `/review-article <path>`, "审查文章", "review", or an article file path. Use the **`review-article`** skill — `.claude/skills/review-article/SKILL.md` carries the workflow, the annotation and summary templates, the review-intensity table, and the R/Python/metadata checklists, with the citation protocol under its `references/`. Read that file if the skill is not loaded.

One rule applies whether or not the skill is loaded: **every critique is evidence-based** — cite the canonical source, or downgrade to `[Suggestion]` (see `.claude/skills/review-article/references/sources.md`).
