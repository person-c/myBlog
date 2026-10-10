#!/usr/bin/env Rscript

# Check the YAML front matter of content files (.md for Hugo, .Rmd for litedown).
# See .claude/skills/review-article/references/code-checks.md (front matter rules).
#
# Usage: Rscript scripts/check-meta.R [file-or-dir ...]      (default: content)
# Exit status: 0 = no errors, 1 = errors.  Informational notes do not fail.
# (lastmod is not checked: it comes from git via enableGitInfo.)

args <- commandArgs(trailingOnly = TRUE)
targets <- if (length(args) > 0) args else "content"

if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("the yaml package is required")
}

files <- character()
for (t in targets) {
  if (dir.exists(t)) {
    files <- c(files, list.files(t, pattern = "[.](md|Rmd)$", recursive = TRUE, full.names = TRUE))
  } else if (file.exists(t)) {
    files <- c(files, t)
  } else {
    warning("skipping missing path: ", t, call. = FALSE)
  }
}
files <- sort(unique(files))
if (length(files) == 0) {
  cat("no .md/.Rmd files to check\n")
  quit(status = 0)
}

# Fields Hugo itself defines; anything else is reported for the reviewer to judge.
known <- c(
  "title", "linkTitle", "subtitle", "date", "lastmod", "publishDate", "expiryDate",
  "draft", "categories", "tags", "keywords", "series", "description", "summary",
  "slug", "url", "aliases", "weight", "type", "layout", "menu", "params", "cascade",
  "outputs", "markup", "toc", "headless", "_build", "hidden", "lang", "format",
  "images", "cover", "license", "comment", "featured",
  "translationKey", "math", "bibliography", "csl"
)

n_err <- 0L
n_note <- 0L
err <- function(f, msg) {
  cat(sprintf("%s: %s\n", f, msg))
  n_err <<- n_err + 1L
}
note <- function(f, msg) {
  cat(sprintf("%s: note: %s\n", f, msg))
  n_note <<- n_note + 1L
}

for (f in files) {
  x <- xfun::read_utf8(f)

  first <- which(nzchar(trimws(x)))[1]
  if (is.na(first) || trimws(x[first]) != "---") {
    err(f, "no YAML front matter")
    next
  }
  ends <- which(trimws(x) == "---")
  end <- ends[ends > first][1]
  if (is.na(end)) {
    err(f, "unterminated YAML front matter")
    next
  }
  meta <- tryCatch(
    yaml::yaml.load(paste(x[(first + 1L):(end - 1L)], collapse = "\n")),
    error = function(e) e
  )
  if (inherits(meta, "error")) {
    err(f, paste("invalid YAML:", conditionMessage(meta)))
    next
  }

  # title
  if (is.null(meta$title) || !nzchar(trimws(as.character(meta$title)))) {
    err(f, "missing or empty 'title'")
  }

  # date: present, ISO 8601 YYYY-MM-DD, and matching the filename prefix
  d <- meta$date
  ds <- NULL
  if (is.null(d)) {
    err(f, "missing 'date'")
  } else {
    ds <- if (inherits(d, "Date")) format(d, "%Y-%m-%d") else as.character(d)
    if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", ds) || is.na(suppressWarnings(as.Date(ds)))) {
      err(f, sprintf("'date' is not ISO 8601 (YYYY-MM-DD): %s", ds))
      ds <- NULL
    }
  }
  m <- regmatches(basename(f), regexpr("^[0-9]{4}-[0-9]{2}-[0-9]{2}", basename(f)))
  if (length(m) == 1 && !is.null(ds) && m != ds) {
    err(f, sprintf("'date' (%s) does not match the filename (%s)", ds, m))
  }

  # draft: must be a real boolean, not the string "true"
  if (!is.null(meta$draft) && !is.logical(meta$draft)) {
    err(f, sprintf("'draft' must be an unquoted true/false (found: %s)", deparse(meta$draft)))
  }

  # categories / tags: must be lists, not comma-separated strings
  for (k in c("categories", "tags")) {
    v <- meta[[k]]
    if (is.null(v)) next
    if (is.character(v) && length(v) == 1 && grepl(",", v)) {
      err(f, sprintf("'%s' looks like a comma-separated string: use a YAML list", k))
    } else if (is.character(v) && length(v) == 1) {
      note(f, sprintf("'%s' is a single value: a YAML list is the usual form", k))
    }
  }

  # anything Hugo does not define
  extra <- setdiff(names(meta), known)
  if (length(extra) > 0) {
    note(f, sprintf("field(s) not defined by Hugo: %s", paste(extra, collapse = ", ")))
  }
}

cat(sprintf("\n%d error(s), %d note(s) in %d file(s)\n", n_err, n_note, length(files)))
if (n_err > 0) quit(status = 1)
cat("all clear\n")
