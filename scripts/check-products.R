#!/usr/bin/env Rscript

# Are the committed .html products built by the litedown that is installed here?
#
# The .Rmd is not read by Hugo (hugo.toml ignoreFiles), so the committed .html is
# what the site publishes.  When the two fall behind each other the published page
# is simply wrong, and no source-level check notices -- the statistics note sat
# broken for weeks that way.  Version drift is the cheap, deterministic half of
# that class: a page rendered by an older litedown carries that version in its
# <meta name="generator">, so a mismatch against the installed version means the
# product predates a re-render.
#
# This only catches the version half.  Content drift -- editing a .Rmd and not
# re-rendering -- needs a real render; that is `make check-fresh` locally.
#
# Usage: Rscript scripts/check-products.R [dir ...]      (default: content)
# Exit status: 0 = every product matches, 1 = findings.

args <- commandArgs(trailingOnly = TRUE)
targets <- if (length(args) > 0) args else "content"

want <- as.character(packageVersion("litedown"))

files <- character()
for (t in targets) {
  if (dir.exists(t)) {
    files <- c(files, list.files(t, pattern = "[.]html$", recursive = TRUE, full.names = TRUE))
  } else if (file.exists(t)) {
    files <- c(files, t)
  } else {
    warning("skipping missing path: ", t, call. = FALSE)
  }
}
# __files/ holds plot fragments, not pages; a page is named like its .Rmd
files <- files[!grepl("__files[/\\\\]", files)]
files <- sort(unique(files))

# Only a .html that has a sibling .Rmd is a litedown product.  A hand-written
# .html (or one Hugo copied from static/) carries no generator meta and is not
# this check's business.
paired <- vapply(files, function(f) {
  file.exists(file.path(dirname(f), paste0(xfun::sans_ext(basename(f)), ".Rmd")))
}, TRUE)
files <- files[paired]

if (length(files) == 0) {
  cat("no .Rmd/.html pairs to check\n")
  quit(status = 0)
}

cat(sprintf("installed litedown: %s\n\n", want))

n_bad <- 0L
for (f in files) {
  x <- xfun::read_utf8(f)
  hit <- grep('name="generator"', x, value = TRUE)
  if (length(hit) == 0) {
    cat(sprintf("%s: no generator meta -- cannot confirm which litedown built it\n", f))
    n_bad <- n_bad + 1L
    next
  }
  got <- sub('.*content="litedown ([^"]*)".*', "\\1", hit[1])
  if (identical(got, want)) {
    cat(sprintf("%-58s %s\n", basename(f), got))
  } else {
    cat(sprintf("%-58s %s  != %s  STALE\n", basename(f), got, want))
    n_bad <- n_bad + 1L
  }
}

cat(sprintf("\n%d of %d product(s) not built by litedown %s\n", n_bad, length(files), want))
if (n_bad > 0) {
  cat("Re-render: make render-all  (then commit the .html with its .Rmd)\n")
  quit(status = 1)
}
cat("all products match the installed litedown\n")
