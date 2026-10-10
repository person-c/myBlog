#!/usr/bin/env Rscript

# Check .Rmd files for math that litedown will not protect, and that therefore
# will not render in the browser.  See docs/litedown.md, "Math protection".
#
# Usage: Rscript scripts/check-math.R [file-or-dir ...]      (default: content)
# Exit status: 0 = clean, 1 = findings.

args <- commandArgs(trailingOnly = TRUE)
targets <- if (length(args) > 0) args else "content"

if (!requireNamespace("xfun", quietly = TRUE)) {
  stop("the xfun package is required (it ships with litedown)")
}

files <- character()
for (t in targets) {
  if (dir.exists(t)) {
    files <- c(files, list.files(t, pattern = "[.]Rmd$", recursive = TRUE, full.names = TRUE))
  } else if (file.exists(t)) {
    files <- c(files, t)
  } else {
    warning("skipping missing path: ", t, call. = FALSE)
  }
}
files <- sort(unique(files))
if (length(files) == 0) {
  cat("no .Rmd files to check\n")
  quit(status = 0)
}

n_inline <- 0L
n_display <- 0L

for (f in files) {
  x <- xfun::read_utf8(f)

  # Inline math: after xfun::protect_math() the delimiters of every formula it
  # protects are rewritten, so any single '$' still left in the prose is a
  # formula litedown will hand to the Markdown parser.  prose_index() keeps the
  # R code chunks out, where '$' is the extract operator.
  prose <- xfun::prose_index(x)
  protected <- xfun::protect_math(x)
  left <- gsub("[$][$]", "", protected[prose])
  hit <- which(grepl("[$]", left))
  if (length(hit) > 0) {
    lines <- prose[hit]
    n_inline <- n_inline + length(lines)
    cat(sprintf("%s: %d line(s) with unprotected inline math\n", f, length(lines)))
    for (i in lines) cat(sprintf("  line %d: %s\n", i, trimws(x[i])))
  }

  # Display math: a '$$' alone on its own line is never protected, because the
  # delimiters must be glued to the content on their lines.
  bare <- grep("^[[:space:]]*[$][$][[:space:]]*$", x)
  if (length(bare) > 0) {
    blocks <- length(bare) %/% 2L
    n_display <- n_display + blocks
    cat(sprintf("%s: %d display block(s) delimited by a bare '$$' line\n", f, blocks))
    for (k in seq_len(blocks)) {
      cat(sprintf("  lines %d-%d\n", bare[2L * k - 1L], bare[2L * k]))
    }
    if (length(bare) %% 2L == 1L) {
      cat(sprintf("  ! unpaired '$$' on line %d\n", bare[length(bare)]))
    }
  }
}

cat(sprintf(
  "\n%d unprotected inline formula(s), %d unprotected display block(s) in %d file(s)\n",
  n_inline, n_display, length(files)
))
if (n_inline + n_display > 0) {
  cat("Fix the .Rmd (see docs/litedown.md), then re-render with litedown::fuse().\n")
  quit(status = 1)
}
cat("all clear\n")
