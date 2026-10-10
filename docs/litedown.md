# litedown: rendering notes and slides

Reference material for this repo's notes (`content/note/*.Rmd` → `.html`) and slide decks. `CLAUDE.md` keeps the rules; the recipes and gotchas live here.

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

## Output files

Plot files land in `<input>__files/` (the default `fig.path`), e.g. `content/note/foo__files/fig-bar-1.svg`. They are **inlined** into the `.html` — nothing in the page points at that directory — so it is generated output, and `*__files/` is gitignored. A page's `<img>` tags are likewise inlined local images as data URIs (e.g. `static/images-note/four_subspace.png`).

## plotly

litedown has no htmlwidgets support, so plotly figures use the documented JS route — recipe in `examples/022-dygraphs.Rmd`, prose in `docs/06-widgets.Rmd`:

1. An R chunk loads the library: `litedown::vest(js = '@npm/plotly.js@<ver>/dist/plotly.min.js')`.
2. An R chunk draws the figure and ends with `spec <- plotly::plotly_build(fig)$x[c("data", "layout")]`.
3. A `{js, type = 'module', echo = FALSE, fill = xfun::tojson}` chunk emits the spec through `` const spec = `{ spec }` `` and runs `Plotly.newPlot(document.getElementById(<id>), spec.data, spec.layout, {responsive: true})`.
4. The container is a fenced div `::: {#<id> style="width: 100%; height: <h>px;"}` placed **after** that chunk — module scripts are deferred, so the element must exist by then.

Verified on 2026-10-10: both figures in `content/note/2025-09-02-introduction-to-linear-algebra.html` render in headless Chrome (`.main-svg` present in both containers, no JS errors).

`vest()` resolves the npm alias and caches the file locally; the page still links the jsdelivr URL by default — add `embed_resources: "all"` to inline the library instead (+4.5 MB).
