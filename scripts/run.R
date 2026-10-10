#!/usr/bin/env Rscript

# Internals behind the Makefile's shell-free targets.
#
# make on Windows may hand a recipe to a POSIX sh, to cmd.exe, or to PowerShell,
# depending on which make is installed.  Keeping the recipes free of `cd`, `echo`
# and globs means it does not matter which one runs them -- and it also means
# `make check` works from PowerShell, where `sh` is not on PATH at all.
#
# Every subcommand here is also runnable on its own:
#   Rscript scripts/run.R serve
#   Rscript scripts/run.R site
#   Rscript scripts/run.R render          # the .Rmd newer than their .html
#   Rscript scripts/run.R render-force    # all of them
#
# Exit status propagates from whatever it runs.

argv <- commandArgs(trailingOnly = TRUE)
task <- if (length(argv) > 0) argv[1] else ""
args <- if (length(argv) > 1) argv[-1] else character()

# the sources and the page each one publishes
products <- function() {
  rmd <- character()
  for (d in c("content/note", "content/slides")) {
    if (dir.exists(d)) rmd <- c(rmd, list.files(d, pattern = "[.]Rmd$", full.names = TRUE))
  }
  sort(rmd)
}

run <- function(cmd, a) {
  status <- system2(cmd, a)
  if (status != 0L) quit(status = status)
  invisible(status)
}

render_one <- function(rmd) {
  cat("render", rmd, "\n")
  here <- getwd()
  on.exit(setwd(here))
  # fuse() must run in the file's own directory: image paths in a .Rmd are
  # relative to it
  setwd(dirname(rmd))
  litedown::fuse(basename(rmd))
}

switch(task,
  serve = run("hugo", c("server", "--noHTTPCache", "--disableFastRender")),

  site = run("hugo", c("--gc", "--minify")),

  help = {
    cat("myBlog\n\n",
      "  make check           deterministic checks (the same set CI runs)\n",
      "  make check-all       check + check-fresh\n",
      "  make check-fresh     re-render every .Rmd and compare with the committed .html\n",
      "  make render          re-render the .Rmd that are newer than their .html\n",
      "  make render-force    re-render every .Rmd regardless of timestamps\n",
      "  make serve           hugo server, no cache, no fast render\n",
      "  make site            production build into public/\n",
      "  make versions        tool versions this checkout is built with\n",
      "  make clean           remove public/\n\n",
      "  check-fresh renders in place, then restores what it found.  Commit first:\n",
      "  an uncommitted .Rmd is rendered, compared, then restored to HEAD content.\n",
      sep = "")
  },

  versions = {
    v <- tryCatch(system2("hugo", "version", stdout = TRUE), error = function(e) character())
    v <- if (length(v) > 0) strsplit(trimws(v[1]), "[[:space:]]+")[[1]][2] else "(hugo not found)"
    cat(sprintf("%-9s%s\n", "hugo", v))
    cat(sprintf("%-9s%s\n", "R", R.version.string))
    for (p in c("litedown", "xfun", "knitr", "yaml")) {
      cat(sprintf("%-9s%s\n", p,
                  tryCatch(as.character(packageVersion(p)), error = function(e) "not installed")))
    }
  },

  clean = {
    unlink("public", recursive = TRUE)
    cat("removed public/\n")
  },

  # timestamp-driven: only what changed since its .html
  render = {
    rmds <- products()
    if (length(rmds) == 0) { cat("no .Rmd found\n"); quit(status = 0) }
    todo <- rmds[vapply(rmds, function(f) {
      html <- file.path(dirname(f), paste0(xfun::sans_ext(basename(f)), ".html"))
      !file.exists(html) || file.mtime(f) > file.mtime(html)
    }, TRUE)]
    if (length(todo) == 0) {
      cat("up to date; commit each .html with its .Rmd\n")
    } else {
      for (f in todo) render_one(f)
      cat("\nrendered", length(todo), "of", length(rmds), "product(s)\n")
    }
  },

  # every source, regardless of timestamps.  Needed because check-fresh restores
  # the .html it compared, which makes every product look newer than its source.
  `render-force` = {
    rmds <- products()
    if (length(rmds) == 0) { cat("no .Rmd found\n"); quit(status = 0) }
    for (f in rmds) render_one(f)
    cat("\nre-rendered", length(rmds), "product(s); commit each .html with its .Rmd\n")
  },

  {
    cat("usage: Rscript scripts/run.R <help|serve|site|versions|clean|render|render-force>\n")
    quit(status = 2)
  }
)
