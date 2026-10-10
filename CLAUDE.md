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
cd content/note && Rscript -e 'litedown::fuse("2025-09-02-introduction-to-linear-algebra.Rmd")'
```

Deterministic checks and preview (what they enforce is in the review directives):

```sh
Rscript scripts/check-math.R content/note      # math litedown will not protect
Rscript scripts/check-meta.R content/note      # YAML front matter
sh scripts/preview.sh content/note/foo.Rmd     # reuse or start the litedown preview server
```

Pipeline facts worth remembering:

- Notes are rendered by **litedown** (`litedown::fuse()` — knitr + markdown in one step), **not** Quarto or rmarkdown. The authoritative reference is the source clone at `reference/litedown/` (gitignored; re-clone from https://github.com/yihui/litedown if missing) — see `reference/litedown/docs/02-fuse.Rmd` (chunk options, devices), `05-assets.Rmd` (assets, code folding), `06-widgets.Rmd` (plotly). Facts that cost time to learn: chunk options are litedown's own and dotted (`fig.cap`, `fig.width`; Quarto's `fig-cap:`, `code-fold:`, `fig-format:` are silently ignored); global defaults go through `litedown::reactor()`, **not** `knitr::opts_chunk$set()`; the device is set with `reactor(dev = "svg")`; code folding is `meta: js: ["@fold-details"]`; `fig.align` does not exist (figures are centred by default). Plot files land in `<input>__files/` (the default `fig.path`) and are inlined into the page, so that directory is generated output and is gitignored.
- **plotly**: litedown has no htmlwidgets support, so the figures use the documented JS route (recipe in `reference/litedown/examples/022-dygraphs.Rmd`, prose in `docs/06-widgets.Rmd`): an R chunk with `litedown::vest(js = '@npm/plotly.js@<ver>/dist/plotly.min.js')` loads the library, a second R chunk ends with `spec <- plotly::plotly_build(fig)$x[c("data", "layout")]`, then a `{js, type = 'module', echo = FALSE, fill = xfun::tojson}` chunk runs `Plotly.newPlot(document.getElementById(<id>), spec.data, spec.layout, {responsive: true})`, and the container is a fenced div `::: {#<id> style="width: 100%; height: <h>px;"}` placed **after** that chunk (module scripts are deferred). Both figures verified rendering in headless Chrome (`.main-svg` present in both containers, no JS errors). `vest()` resolves the npm alias and caches the file; by default the page still links the jsdelivr URL — add `embed_resources: "all"` to inline it (+4.5 MB).
- `hugo.toml` sets `ignoreFiles = ["\\.Rmd$"]`: the `.Rmd` is never built, so the rendered **`.html` is the published page and has to be committed**. Editing the `.Rmd` alone changes nothing online until it is re-rendered.
- `hugo mod get -u` upgrades every module, the theme included. The pinned version is in `go.mod`; do not copy version numbers into this file.
- Production builds run on Vercel, with the Hugo version pinned in `vercel.json`.

---

## Git conventions

- **一个可独立验收或回滚的 task 一个提交。** 按 task 拆，不按文件拆：一个文件的改动若分属两个 task，用 hunk 级暂存分开（拆出只含目标 hunk 的部分补丁，`git apply --cached` 入索引，再用 `git diff --cached --stat` 对 `git diff --stat` 核对切分是否干净）。
- **提交信息自带验收依据。** 首行 `type: 中文摘要`（`fix` / `docs` / `chore` / `content` …），正文用中文要点写清：改了什么、**怎么验证的**（命令、计数、渲染或预览结果）、还有什么遗留。任何一条提交都应能凭信息本身复核或回滚。AI 生成的提交以 `Co-Authored-By: Claude Code <noreply@anthropic.com>` 结尾。
- **顺序：非 `content/` 先行，笔记/日志随后。** 工具、脚本、CI、CLAUDE.md 这类小改动先提交；`content/` 下的笔记、日志、文章正文单独成提交——重渲染过的 `.html` diff 动辄数千行，混在一起就没法单独回滚了。提交前用 `git status --short` 过一遍，别把生成产物（`public/`、`<input>__files/`）或临时文件带上。
- **笔记的 `.Rmd` 与它的 `.html` 必须同一提交。** `hugo.toml` 忽略 `.Rmd`，线上页面就是那个 `.html`；只提交一边会让源文件与线上不一致。提交前跑 `scripts/check-math.R`、`scripts/check-meta.R`，需要看效果时用 `scripts/preview.sh`。
- **有意保留的发布态批注要在提交信息里写明**（几块、在哪个文件）：批注是发布策略（见上文），写明才不会被后人误当成漏清理。
- **不主动 push。** push 到 `main` 会触发 Vercel 生产发布（cying.org），属对外动作，等明确要求再做；本地先累积几个提交是常态。push 前想复核整站，用 `hugo server --noHTTPCache --disableFastRender`。

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
