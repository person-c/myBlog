#!/usr/bin/env Rscript

# Is each committed .html what its .Rmd renders to right now?
#
# The expensive half of the product check.  `scripts/check-products.R` compares
# only the litedown version recorded in each page; this one re-renders and
# compares the result, so it also catches a .Rmd that was edited without being
# re-rendered -- the failure that left the statistics note broken on the site.
#
# It renders **in place**, because a note's image paths are relative to its own
# directory (the linear-algebra note embeds ../../static/images-note/...), and
# copies each .html aside first so the working tree is restored even on failure.
# That means: commit or stash your work before running this, or a pre-existing
# uncommitted .Rmd will be rendered, compared and then restored to its committed
# content along with everything else.
#
# Two differences are inherent to a re-render and are normalised away, not
# reported: the date evaluated from `{r} Sys.Date()` (see docs/litedown.md) and
# the litedown version itself.
#
# Usage: Rscript scripts/check-fresh.R [dir ...]      (default: content)
# Exit status: 0 = every product is up to date, 1 = drift or a render failure.

args <- commandArgs(trailingOnly = TRUE)
targets <- if (length(args) > 0) args else "content"

if (!requireNamespace("litedown", quietly = TRUE)) {
  stop("the litedown package is required")
}

dirs <- targets[dir.exists(targets)]
rmds <- character()
for (d in dirs) {
  rmds <- c(rmds, list.files(d, pattern = "[.]Rmd$", recursive = TRUE, full.names = TRUE))
}
rmds <- sort(unique(rmds))
# `hugo.toml` ignores .Rmd, so every .Rmd here is a product source
if (length(rmds) == 0) {
  cat("no .Rmd files to check\n")
  quit(status = 0)
}

backup <- file.path(tempdir(), "dsh-fresh-backup")
unlink(backup, recursive = TRUE)
dir.create(backup, recursive = TRUE, showWarnings = FALSE)

html_of <- function(rmd) file.path(dirname(rmd), paste0(xfun::sans_ext(basename(rmd)), ".html"))
hashes <- function(f) if (file.exists(f)) unname(tools::md5sum(f)) else NA_character_

# copy the originals aside before touching anything
present <- rmds[file.exists(html_of(rmds))]
for (f in present) file.copy(html_of(f), file.path(backup, basename(html_of(f))), overwrite = TRUE)
before <- vapply(present, function(f) hashes(html_of(f)), "")

restore <- function() {
  for (f in present) {
    b <- file.path(backup, basename(html_of(f)))
    if (file.exists(b)) file.copy(b, html_of(f), overwrite = TRUE)
  }
  bad <- present[vapply(present, function(f) !identical(hashes(html_of(f)), before[[f]]), TRUE)]
  if (length(bad) > 0) {
    cat("\n!! could not restore byte-exactly:", paste(basename(html_of(bad)), collapse = ", "), "\n")
    cat("!! originals are in", backup, "-- restore them by hand\n")
  }
  invisible(NULL)
}

rd <- function(f) paste(xfun::read_utf8(f), collapse = "\n")
body <- function(h) {
  b <- sub("(?s).*?<body[^>]*>", "", h, perl = TRUE)
  sub("(?s)</body>.*", "", b, perl = TRUE)
}
generator <- function(h) {
  m <- regmatches(h, regexpr('name="generator" content="[^"]*"', h))
  if (length(m)) sub('.*content="', "", sub('"$', "", m)) else "(none)"
}
normalise <- function(b) {
  t <- gsub("(?s)<(script|style)[^>]*>.*?</\\1>", " ", b, perl = TRUE)
  t <- gsub("<[^>]*>", " ", t, perl = TRUE)
  t <- gsub("&[a-zA-Z#0-9]+;", " ", t, perl = TRUE)
  t <- gsub("[0-9]{4}-[0-9]{2}-[0-9]{2}", " <DATE> ", t)   # `{r} Sys.Date()`
  t <- gsub("[[:space:]]+", " ", t)
  trimws(t)
}

n_bad <- 0L
fails <- character()
res <- tryCatch(
  {
    cat(sprintf("re-rendering %d source(s) in place, then restoring\n\n", length(rmds)))
    for (rmd in rmds) {
      w <- character()
      # fuse() must run in the note's own directory: image paths in the .Rmd are
      # relative to it, and rendering from elsewhere fails to embed them.
      here <- getwd()
      ok <- withCallingHandlers(
        tryCatch({
          setwd(dirname(rmd))
          litedown::fuse(basename(rmd), output = FALSE)
          TRUE
        }, error = function(e) { w <<- c(w, conditionMessage(e)); FALSE }),
        warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") }
      )
      setwd(here)
      if (!ok) {
        cat(sprintf("%-52s RENDER FAILED\n", basename(rmd)))
        for (m in unique(w)) cat("    ", m, "\n")
        fails <- c(fails, basename(rmd))
        n_bad <- n_bad + 1L
        next
      }
      old_f <- file.path(backup, basename(html_of(rmd)))
      new_f <- html_of(rmd)
      if (!file.exists(old_f)) {
        cat(sprintf("%-52s NEW PRODUCT (was not committed)\n", basename(rmd)))
        n_bad <- n_bad + 1L
        next
      }
      co <- rd(old_f); fr <- rd(new_f)
      same_body <- identical(normalise(body(co)), normalise(body(fr)))
      same_gen <- identical(generator(co), generator(fr))
      if (same_body && same_gen) {
        cat(sprintf("%-52s OK  (%s)\n", basename(rmd), generator(co)))
      } else {
        n_bad <- n_bad + 1L
        cat(sprintf("%-52s DRIFT (%s)\n", basename(rmd),
                    if (!same_body) "body" else "generator version"))
        if (!same_body) {
          to <- normalise(body(co)); tf <- normalise(body(fr))
          k <- 1L; m <- min(nchar(to), nchar(tf))
          while (k <= m && substr(to, k, k) == substr(tf, k, k)) k <- k + 1L
          cat("    committed: ...", substr(to, max(1, k - 60), min(nchar(to), k + 80)), "...\n", sep = "")
          cat("    fresh    : ...", substr(tf, max(1, k - 60), min(nchar(tf), k + 80)), "...\n", sep = "")
        }
        if (!same_gen) cat(sprintf("    %s -> %s\n", generator(co), generator(fr)))
      }
      if (length(w) > 0) for (m in unique(w)) cat("    note:", m, "\n")
    }
    n_bad
  },
  finally = restore()
)

cat(sprintf("\n%d of %d product(s) need attention\n", res, length(rmds)))
if (res > 0) {
  cat("Re-render and commit the .html together with its .Rmd.\n")
  quit(status = 1)
}
cat("every committed product is what its source renders to\n")
