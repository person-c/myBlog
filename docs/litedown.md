# litedown: rendering notes and slides

Reference material for this repo's notes (`content/note/*.Rmd` → `.html`) and slide decks. `CLAUDE.md` keeps the project-level rules and points here; everything litedown-specific — its option rules, the math-protection rules, recipes and gotchas — lives here. Read it when rendering a note or fixing a formula.

Authoritative source: the source clone at `reference/litedown/` (gitignored; re-clone from https://github.com/yihui/litedown if missing).

| Topic | Where in the clone |
| --- | --- |
| Chunk options, devices, `fig.path` | `docs/02-fuse.Rmd` |
| Assets, code folding | `docs/05-assets.Rmd` |
| HTML widgets (plotly, dygraphs) | `docs/06-widgets.Rmd` |
| Working recipes | `examples/`, e.g. `examples/022-dygraphs.Rmd` |

## Chunk options and global defaults

- Options are litedown's own and dotted — `fig.cap`, `fig.width`, `fig.height`. Quarto's `fig-cap:`, `code-fold:`, `fig-format:` are silently ignored; do not introduce them.
- Global defaults go through `litedown::reactor()`, **not** `knitr::opts_chunk$set()` — litedown never consults the latter.
- The device is set with `reactor(dev = "svg")`.
- Code folding is `meta: js: ["@fold-details"]` in the YAML header.
- `fig.align` does not exist; figures are centred by default.

## Math protection

litedown delegates math protection to `xfun::protect_math()`, which shields only the math that matches xfun's heuristics. Anything else is handed to the Markdown parser as ordinary text and silently corrupted (`\\` → `\`, `\,` → `,`, `\|` → `|`, `^` → `<sup>`, `_` → `<em>`, `'` → `’`, and a lone `=` line turns the preceding lines into a setext heading). Since KaTeX auto-render accepts only `$$…$$`, `\(…\)` and `\[…\]`, the formula then fails to render at all in the browser. Flag every violation as `[Render]`.

- Inline `$...$`: the opening `$` must be preceded by whitespace, an ASCII `(`, or the start of a line. Flag as `[Render]` — `、$LU$`、`：$C$`、`（$A$ 可逆）` are all broken, because a full-width `（` is not `(`, and CJK punctuation is not whitespace. The closing `$` must not be followed by a digit, and no space may sit just inside either delimiter. **Fix:** insert one space before the `$` (this is also the standard gap between Chinese text and Western symbols).
- Display `$$...$$`: a multi-line block is protected only when the opening `$$` is glued to its content and the closing `$$` is glued to the end of the last content line — `$$\begin{aligned}` … `\end{aligned}$$`. A `$$` alone on its own line is never protected. Flag as `[Render]`. **Fix:** move the delimiters onto the content lines. (xfun's own documentation says multi-line `$$…$$` is supported, so this is a tool limitation to code around, not an error in the author's LaTeX.)
- Never settle for repairing the rendered `.html` — it is generated output, and `litedown::roam()` re-renders the `.Rmd` live without writing `.html` at all. Fix the `.Rmd` and re-render.
- Exact check: `Rscript scripts/check-math.R <file>` — the same rule, computed with `xfun::protect_math()` + `xfun::prose_index()`, plus the display blocks whose `$$` sits alone on its line.
- Reference: `?xfun::protect_math` (Details) and `xfun:::escape_math()`; rules verified against litedown 0.10.1 / xfun 0.56 (an `.Rmd` that satisfies them renders with zero mis-converted formulas).

## Output files

Plot files land in `<input>__files/` (the default `fig.path`), e.g. `content/note/foo__files/fig-bar-1.svg`. They are **inlined** into the `.html` — nothing in the page points at that directory — so it is generated output, and `*__files/` is gitignored. A page's `<img>` tags are likewise inlined local images as data URIs (e.g. `static/images-note/four_subspace.png`).

## Preview with roam

`litedown::roam(<dir>)` serves the files in that directory over HTTP (port 4321 by default, incrementing when it is busy) and re-renders the `.Rmd` live — no `.html` is written. `scripts/preview.sh <file-or-dir>` reuses a running server that already covers the target, otherwise starts one.

## plotly

litedown has no htmlwidgets support, so plotly figures use the documented JS route — recipe in `examples/022-dygraphs.Rmd`, prose in `docs/06-widgets.Rmd`:

1. An R chunk loads the library: `litedown::vest(js = '@npm/plotly.js@<ver>/dist/plotly.min.js')`.
2. An R chunk draws the figure and ends with `spec <- plotly::plotly_build(fig)$x[c("data", "layout")]`.
3. A `{js, type = 'module', echo = FALSE, fill = xfun::tojson}` chunk emits the spec through `` const spec = `{ spec }` `` and runs `Plotly.newPlot(document.getElementById(<id>), spec.data, spec.layout, {responsive: true})`.
4. The container is a fenced div `::: {#<id> style="width: 100%; height: <h>px;"}` placed **after** that chunk — module scripts are deferred, so the element must exist by then.

Verified on 2026-10-10: both figures in `content/note/2025-09-02-introduction-to-linear-algebra.html` render in headless Chrome (`.main-svg` present in both containers, no JS errors).

`vest()` resolves the npm alias and caches the file locally; the page still links the jsdelivr URL by default — add `embed_resources: "all"` to inline the library instead (+4.5 MB).
