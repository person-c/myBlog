# Local checks and build for this blog.
#
# CI (.github/workflows/) runs only the deterministic, cheap checks.  The ones
# that need a real render -- `check-fresh`, `render-all` -- live here.
#
# Needs: hugo, Rscript (with litedown, xfun, yaml).  Every check is an Rscript,
# so `make check` works from PowerShell too; only `render-all`/`serve` need a
# shell.  On Windows this repository's D: checkout cannot delete files, and git
# needs that to write its own index -- see CLAUDE.md.

.POSIX:
SHELL := /bin/sh

CONTENT   := content
NOTE_DIR  := content/note
SLIDE_DIR := content/slides

# every litedown source, and the page each one publishes
RMDS     := $(wildcard $(NOTE_DIR)/*.Rmd) $(wildcard $(SLIDE_DIR)/*.Rmd)
PRODUCTS := $(RMDS:.Rmd=.html)

.PHONY: help check check-all check-math check-meta check-products check-repo \
        check-fresh render render-force serve site versions clean

help:
	@echo "myBlog"
	@echo
	@echo "  make check           deterministic checks (the same set CI runs)"
	@echo "  make check-all       check + check-fresh"
	@echo "  make check-fresh     re-render every .Rmd and compare with the committed .html"
	@echo "  make render          re-render the .Rmd that are newer than their .html"
	@echo "  make render-force    re-render every .Rmd regardless of timestamps"
	@echo "  make serve           hugo server, no cache, no fast render"
	@echo "  make site            production build into public/"
	@echo "  make versions        tool versions this checkout is built with"
	@echo "  make clean           remove public/"
	@echo
	@echo "  check-fresh renders in place, then restores what it found.  Commit first:"
	@echo "  an uncommitted .Rmd is rendered, compared, then restored to HEAD content."
	@echo "  Note: because it restores, make render afterwards sees .html newer than"
	@echo "  .Rmd and does nothing -- use render-force to re-render anyway."

# ---------------------------------------------------------------- deterministic

check: check-math check-meta check-products check-repo
	@echo
	@echo "all deterministic checks passed"

check-all: check check-fresh
	@echo
	@echo "everything passed"

check-math:
	@echo "== math litedown will not protect =="
	@Rscript scripts/check-math.R $(CONTENT)

check-meta:
	@echo "== front matter =="
	@Rscript scripts/check-meta.R $(CONTENT)

# version drift: a page carries the litedown that built it
check-products:
	@echo "== committed .html built by the installed litedown =="
	@Rscript scripts/check-products.R $(CONTENT)

# layout names, the dead `paginate` key, workflow YAML, static assets
check-repo:
	@echo "== repository invariants =="
	@Rscript scripts/check-repo.R

# ------------------------------------------------------------------- rendering

# The expensive check.  Rendering must happen inside the file's own directory:
# image paths in a .Rmd are relative to it (the linear-algebra note embeds
# ../../static/images-note/...), so this re-renders in place and restores.
check-fresh:
	@echo "== does each committed .html match its current .Rmd? =="
	@Rscript scripts/check-fresh.R $(CONTENT)

$(NOTE_DIR)/%.html: $(NOTE_DIR)/%.Rmd
	@echo "render $<"
	@cd $(@D) && Rscript -e "litedown::fuse('$(notdir $<)')"

$(SLIDE_DIR)/%.html: $(SLIDE_DIR)/%.Rmd
	@echo "render $<"
	@cd $(@D) && Rscript -e "litedown::fuse('$(notdir $<)')"

render: $(PRODUCTS)
	@echo
	@echo "up to date; commit each .html with its .Rmd"

# Force: the pattern rules above are timestamp-driven, and check-fresh restores
# the .html it compared -- which makes every product look newer than its source.
# -B re-runs the same recipes unconditionally rather than duplicating them.
render-force:
	@$(MAKE) -B --no-print-directory render
	@echo
	@echo "re-rendered $(words $(PRODUCTS)) product(s); commit each .html with its .Rmd"

# ----------------------------------------------------------------------- build

serve:
	hugo server --noHTTPCache --disableFastRender

site:
	hugo --gc --minify

versions:
	@echo "hugo     $$(hugo version | sed 's/ .*//;s/^hugo v//')"
	@Rscript -e 'cat("R        ", R.version.string, "\n", sep = ""); \
	  for (p in c("litedown", "xfun", "knitr", "yaml")) \
	    cat(sprintf("%-9s%s\n", p, tryCatch(as.character(packageVersion(p)), error = function(e) "not installed")))'

clean:
	rm -rf public
