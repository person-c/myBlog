# Local checks and build for this blog.
#
# CI (.github/workflows/) runs only the deterministic, cheap checks.  The ones
# that need a real render -- `check-fresh`, `render-force` -- live here.
#
# Every recipe is a single command: no `cd`, no `echo`, no globs, no `&&`, and no
# line continuations inside a quoted argument.  That matters because `make` hands
# recipes to a different shell depending on the platform -- sh on Unix, cmd.exe or
# PowerShell on Windows -- and a multi-line R expression survives some of those
# and not others.  The work lives in scripts/run.R instead.
#
# Needs: hugo and Rscript (with litedown, xfun, yaml).
#
# Windows note: `make` still needs *a* shell to launch those commands, and the
# one it picks by default here is C:/rtools45/usr/bin/sh.exe, inherited from the
# Rtools PATH.  If that sh cannot start, every target fails with
# "couldn't create signal pipe" before any recipe runs.  Point make at cmd
# instead -- the recipes were written so that this is enough:
#
#   make SHELL=cmd.exe check
#   set MAKESHELL=cmd.exe && make check        (cmd.exe, for the whole session)

CONTENT := content

.PHONY: help check check-all check-math check-meta check-products check-repo \
        check-fresh render render-force serve site versions clean

help:
	@Rscript scripts/run.R help

# ---------------------------------------------------------------- deterministic

check:
	@Rscript scripts/check-math.R $(CONTENT)
	@Rscript scripts/check-meta.R $(CONTENT)
	@Rscript scripts/check-products.R $(CONTENT)
	@Rscript scripts/check-repo.R
	@Rscript -e "cat('\nall deterministic checks passed\n')"

check-all: check check-fresh
	@Rscript -e "cat('\neverything passed\n')"

check-math:
	@Rscript scripts/check-math.R $(CONTENT)

check-meta:
	@Rscript scripts/check-meta.R $(CONTENT)

# version drift: every page records the litedown that built it
check-products:
	@Rscript scripts/check-products.R $(CONTENT)

# layout names, the dead `paginate` key, workflow YAML, static assets
check-repo:
	@Rscript scripts/check-repo.R

# The expensive one: render, compare, restore.  See the warning in `make help`.
check-fresh:
	@Rscript scripts/check-fresh.R $(CONTENT)

# ------------------------------------------------------------------- rendering

render:
	@Rscript scripts/run.R render

render-force:
	@Rscript scripts/run.R render-force

# ----------------------------------------------------------------------- build

serve:
	@Rscript scripts/run.R serve

site:
	@Rscript scripts/run.R site

versions:
	@Rscript scripts/run.R versions

clean:
	@Rscript scripts/run.R clean
