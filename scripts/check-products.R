#!/usr/bin/env Rscript

# Did every committed .html come from the same litedown, and is that the one
# installed here?
#
# The .Rmd is not read by Hugo (hugo.toml ignoreFiles), so the committed .html is
# what the site publishes.  When source and product fall behind each other the
# published page is simply wrong, and no source-level check notices -- the
# statistics note sat broken for weeks that way.  Version drift is the cheap,
# deterministic half: each page records the litedown that built it in its
# <meta name="generator">.
#
# Two rules, both precise:
#
#   * Mixed versions across products.  Always a fault -- it means some pages were
#     re-rendered and others were not.  This is the failure that was found here:
#     0.7, 0.9 and 0.11 in the same tree.
#   * The common version differs from the installed one.  A product ahead of the
#     installed litedown is impossible; a product behind it means the tree is due
#     for a re-render (`make render-force`).  Note this deliberately does not
#     compare against CRAN: CI installs whatever CRAN ships, and a new release
#     there while the tree is at an older version is exactly the drift worth
#     hearing about.
#
# This cannot see content drift -- editing a .Rmd and not re-rendering -- which
# needs a real render: `make check-fresh`, locally.
#
# Usage: Rscript scripts/check-products.R [dir ...]      (default: content)
# Exit status: 0 = consistent, 1 = findings.

args <- commandArgs(trailingOnly = TRUE)
targets <- if (length(args) > 0) args else "content"

if (!requireNamespace("litedown", quietly = TRUE)) {
  stop("the litedown package is required")
}
installed <- as.character(packageVersion("litedown"))

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
# __files/ holds plot fragments, not pages
files <- files[!grepl("__files[/\\\\]", files)]

# Only a .html with a sibling .Rmd is a litedown product; a hand-written .html or
# one copied from static/ carries no generator meta and is not this check's business.
paired <- vapply(files, function(f) {
  file.exists(file.path(dirname(f), paste0(xfun::sans_ext(basename(f)), ".Rmd")))
}, TRUE)
files <- sort(unique(files[paired]))

if (length(files) == 0) {
  cat("no .Rmd/.html pairs to check\n")
  quit(status = 0)
}

n_bad <- 0L
versions <- character()
for (f in files) {
  x <- xfun::read_utf8(f)
  hit <- grep('name="generator"', x, value = TRUE)
  if (length(hit) == 0) {
    cat(sprintf("%-58s no generator meta -- cannot tell which litedown built it\n", basename(f)))
    n_bad <- n_bad + 1L
    next
  }
  v <- sub('.*content="litedown ([^"]*)".*', "\\1", hit[1])
  versions[basename(f)] <- v
  cat(sprintf("%-58s %s\n", basename(f), v))
}

cat(sprintf("\ninstalled litedown: %s\n", installed))

if (length(versions) > 0) {
  uniq <- unique(versions)
  cat("versions in the tree:", paste(sort(uniq), collapse = ", "), "\n\n")

  if (length(uniq) > 1L) {
    cat("MIXED VERSIONS -- some pages were re-rendered and others were not:\n")
    for (v in sort(uniq)) {
      cat(sprintf("   %-8s %s\n", v, paste(names(versions)[versions == v], collapse = ", ")))
    }
    cat("   All of them must be re-rendered: make render-force\n")
    n_bad <- n_bad + length(uniq) - 1L
  } else {
    common <- uniq[1]
    if (identical(common, installed)) {
      cat(sprintf("all %d product(s) built by the installed litedown %s\n", length(versions), installed))
    } else if (utils::compareVersion(common, installed) > 0) {
      cat(sprintf("IMPOSSIBLE: products claim litedown %s but only %s is installed\n", common, installed))
      n_bad <- n_bad + 1L
    } else {
      cat(sprintf("STALE: products were built by litedown %s, %s is installed\n", common, installed))
      cat("   Re-render: make render-force  (then commit each .html with its .Rmd)\n")
      n_bad <- n_bad + 1L
    }
  }
}

if (n_bad > 0) quit(status = 1)
cat("products are consistent\n")
