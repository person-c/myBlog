#!/usr/bin/env Rscript

# Check a litedown product against its rendered page: the failures a source-level
# lint cannot see and that a browser would only reveal by eye.
#
#   * TeX that reaches KaTeX but cannot parse: unbalanced braces, unbalanced
#     \left / \right, or \begin{x} ... \end{y} that do not match.  KaTeX runs in
#     the browser, so a broken formula here is invisible in the .html file itself.
#   * math the renderer failed to protect: a '$' left in visible text (check-math
#     catches this at the source; this is the end-to-end confirmation).
#   * a figure without a caption, or a caption without a figure.
#   * a TOC the YAML asked for but the page lacks, or one deeper than toc.depth.
#   * a page that still loads @fold-details with no code block to fold.
#   * how many review-note annotations the page publishes (informational).
#
# litedown emits inline math as \(...\) and display math as $$...$$; both are
# delimiters KaTeX consumes in the browser, so both are linted here.
#
# Usage: Rscript scripts/check-render.R [file-or-dir ...]      (default: content)
# Exit status: 0 = clean, 1 = findings, 2 = a page that would not render at all.

args <- commandArgs(trailingOnly = TRUE)
targets <- if (length(args) > 0) args else "content"

if (!requireNamespace("xfun", quietly = TRUE)) {
  stop("the xfun package is required (it ships with litedown)")
}

files <- character()
for (t in targets) {
  if (dir.exists(t)) {
    files <- c(
      files,
      list.files(t, pattern = "[.]Rmd$", recursive = TRUE, full.names = TRUE)
    )
  } else if (file.exists(t)) {
    files <- c(files, t)
  } else {
    warning("skipping missing path: ", t, call. = FALSE)
  }
}
files <- sort(unique(files))
not_rmd <- files[!grepl("[.]Rmd$", files)]
if (length(not_rmd) > 0) {
  cat(sprintf(
    "skipping %d non-.Rmd input(s): blog .md files have no rendered product\n",
    length(not_rmd)
  ))
}
files <- files[grepl("[.]Rmd$", files)]
if (length(files) == 0) {
  cat("no .Rmd files to check\n")
  quit(status = 0)
}

rd <- function(f) {
  paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

yaml_block <- function(f) {
  x <- readLines(f, warn = FALSE, encoding = "UTF-8")
  if (length(x) == 0 || trimws(x[1]) != "---") {
    return("")
  }
  end <- which(trimws(x) == "---")
  end <- end[end > 1]
  if (length(end) == 0) {
    return("")
  }
  paste(x[2:(end[1] - 1)], collapse = "\n")
}

# Code spans quote TeX without being math: an annotation that shows the rule
# (`$...$` again) must not be linted as a formula.
strip_code <- function(h) {
  gsub("(?s)<(script|style|pre|code)[^>]*>.*?</\\1>", " ", h, perl = TRUE)
}

decode_entities <- function(s) {
  s <- gsub("&amp;", "&", s, fixed = TRUE)
  s <- gsub("&lt;", "<", s, fixed = TRUE)
  s <- gsub("&gt;", ">", s, fixed = TRUE)
  s <- gsub("&quot;", "\"", s, fixed = TRUE)
  s
}

# The formulas KaTeX will see: \(...\) inline and $$...$$ display.
math_in <- function(h) {
  h <- strip_code(h)
  out <- character()

  parts <- strsplit(h, "$$", fixed = TRUE)[[1]]
  if (length(parts) >= 3) {
    for (i in seq(2, length(parts) - 1, by = 2)) {
      tex <- parts[i]
      if (nchar(tex) < 20000) out <- c(out, decode_entities(tex))
    }
  }
  parts <- strsplit(h, "\\(", fixed = TRUE)[[1]]
  if (length(parts) >= 2) {
    for (p in parts[-1]) {
      tex <- strsplit(p, "\\)", fixed = TRUE)[[1]][1]
      if (nchar(tex) < 5000) out <- c(out, decode_entities(tex))
    }
  }
  out
}

lint_tex <- function(tex) {
  bad <- character()
  if (trimws(tex) == "") {
    bad <- c(bad, "empty formula")
  }

  s <- gsub("\\\\[{}]", "", tex) # escaped braces are literals
  n_open <- lengths(regmatches(s, gregexpr("\\{", s)))[1]
  n_close <- lengths(regmatches(s, gregexpr("\\}", s)))[1]
  if (is.na(n_open)) {
    n_open <- 0L
  }
  if (is.na(n_close)) {
    n_close <- 0L
  }
  if (n_open != n_close) {
    bad <- c(
      bad,
      sprintf("unbalanced braces (%d '{' vs %d '}')", n_open, n_close)
    )
  }

  n_left <- lengths(regmatches(
    tex,
    gregexpr("\\\\left(?![A-Za-z])", tex, perl = TRUE)
  ))[1]
  n_right <- lengths(regmatches(
    tex,
    gregexpr("\\\\right(?![A-Za-z])", tex, perl = TRUE)
  ))[1]
  if (is.na(n_left)) {
    n_left <- 0L
  }
  if (is.na(n_right)) {
    n_right <- 0L
  }
  if (n_left != n_right) {
    bad <- c(
      bad,
      sprintf("unbalanced \\left (%d) and \\right (%d)", n_left, n_right)
    )
  }

  toks <- regmatches(
    tex,
    gregexpr("\\\\(begin|end)\\{[A-Za-z*]+\\}", tex, perl = TRUE)
  )
  toks <- if (length(toks)) toks[[1]] else character()
  if (length(toks)) {
    stack <- character()
    for (tok in toks) {
      name <- sub("^\\\\(begin|end)\\{", "", sub("\\}$", "", tok))
      if (startsWith(tok, "\\begin")) {
        stack <- c(stack, name)
      } else {
        top <- if (length(stack)) stack[length(stack)] else NA_character_
        if (is.na(top) || !identical(top, name)) {
          bad <- c(
            bad,
            sprintf(
              "\\end{%s} does not close \\begin{%s}",
              name,
              ifelse(is.na(top), "?", top)
            )
          )
          break
        }
        stack <- stack[-length(stack)]
      }
    }
    if (length(stack)) {
      bad <- c(bad, sprintf("unclosed \\begin{%s}", stack[length(stack)]))
    }
  }
  bad
}

toc_depth <- function(h) {
  i <- regexpr('id="TOC"', h, fixed = TRUE)
  if (i < 0) {
    return(NA_integer_)
  }
  b <- substr(h, i, nchar(h))
  j <- regexpr("<h[1-6][ >]", b)
  if (j > 0) {
    b <- substr(b, 1, j - 1)
  }
  toks <- regmatches(b, gregexpr("<ul[ >]|</ul>", b))[[1]]
  depth <- 0L
  mx <- 0L
  for (tok in toks) {
    if (startsWith(tok, "<ul")) {
      depth <- depth + 1L
      mx <- max(mx, depth)
    } else {
      depth <- depth - 1L
    }
  }
  mx
}

n_fail <- 0L
n_warn <- 0L

for (f in files) {
  html <- file.path(dirname(f), paste0(xfun::sans_ext(basename(f)), ".html"))
  if (!file.exists(html)) {
    cat(sprintf(
      "%-52s no rendered page (.html); run litedown::fuse()\n",
      basename(f)
    ))
    n_warn <- n_warn + 1L
    next
  }

  h <- rd(html)
  y <- yaml_block(f)
  fails <- character()
  warns <- character()
  info <- character()

  tex <- math_in(h)
  for (i in seq_along(tex)) {
    bad <- lint_tex(tex[i])
    if (length(bad)) {
      snip <- gsub("[[:space:]]+", " ", substr(tex[i], 1, 90))
      fails <- c(
        fails,
        sprintf(
          "formula %d will not parse: %s -- %s",
          i,
          paste(bad, collapse = "; "),
          snip
        )
      )
    }
  }

  # Inline math is emitted as \(...\), so a single '$' left in visible text is
  # math the protection step missed (display math's '$$' is legitimate).
  vis <- strip_code(h)
  vis <- gsub("$$", " ", vis, fixed = TRUE)
  vis <- gsub("\\(", " ", vis, fixed = TRUE)
  vis <- gsub("\\)", " ", vis, fixed = TRUE)
  vis <- gsub("<[^>]*>", " ", vis, perl = TRUE)
  vis <- gsub("&[a-zA-Z#0-9]+;", " ", vis, perl = TRUE)
  n_dollar <- lengths(regmatches(vis, gregexpr("$", vis, fixed = TRUE)))[1]
  if (is.na(n_dollar)) {
    n_dollar <- 0L
  }
  if (n_dollar > 0) {
    ctx <- strsplit(vis, "$", fixed = TRUE)[[1]]
    ctx <- utils::head(trimws(gsub("[[:space:]]+", " ", ctx)), 4)
    fails <- c(
      fails,
      sprintf(
        "%d '$' left in visible text (inline math protection failed): %s",
        n_dollar,
        paste(utils::head(ctx, 3), collapse = " | ")
      )
    )
  }

  n_fig <- lengths(regmatches(h, gregexpr('class="figure"', h, fixed = TRUE)))[
    1
  ]
  n_cap <- lengths(regmatches(h, gregexpr('class="caption"', h, fixed = TRUE)))[
    1
  ]
  if (!is.na(n_fig) && !is.na(n_cap) && n_fig != n_cap) {
    warns <- c(warns, sprintf("%d figure(s) but %d caption(s)", n_fig, n_cap))
  }

  toc_wanted <- any(grepl(
    "^[[:space:]]*toc:",
    strsplit(y, "\n", fixed = TRUE)[[1]]
  ))
  toc_d <- toc_depth(h)
  if (toc_wanted && is.na(toc_d)) {
    fails <- c(fails, "YAML asks for a TOC but the page has none")
  } else if (toc_wanted && !is.na(toc_d)) {
    m <- regexpr("depth:[[:space:]]*[0-9]+", y)
    if (m > 0) {
      want <- as.integer(sub(".*depth:[[:space:]]*", "", regmatches(y, m)))
      if (toc_d > want) {
        fails <- c(
          fails,
          sprintf("TOC is %d level(s) deep but toc.depth is %d", toc_d, want)
        )
      }
    }
  }

  n_pre <- lengths(regmatches(h, gregexpr("<pre", h, fixed = TRUE)))[1]
  if (!is.na(n_pre) && n_pre == 0 && grepl("@fold-details", y, fixed = TRUE)) {
    warns <- c(
      warns,
      "YAML loads @fold-details but the page has no <pre> to fold"
    )
  }

  n_note <- lengths(regmatches(
    h,
    gregexpr('class="review-note"', h, fixed = TRUE)
  ))[1]
  if (!is.na(n_note) && n_note > 0) {
    info <- c(info, sprintf("%d review-note block(s) published", n_note))
  }
  if (file.info(html)$mtime < file.info(f)$mtime) {
    warns <- c(
      warns,
      "the .html is older than the .Rmd (check-fresh confirms drift)"
    )
  }

  cat(sprintf(
    "%-52s %3d formula(s), %2d figure(s); %s\n",
    basename(f),
    length(tex),
    if (is.na(n_fig)) 0L else n_fig,
    if (length(info)) paste(info, collapse = "; ") else "no annotations"
  ))
  for (m in unique(fails)) {
    cat("  FAIL ", m, "\n")
  }
  for (m in unique(warns)) {
    cat("  warn ", m, "\n")
  }
  n_fail <- n_fail + length(unique(fails))
  n_warn <- n_warn + length(unique(warns))
}

cat(sprintf(
  "\n%d render finding(s), %d warning(s) in %d file(s)\n",
  n_fail,
  n_warn,
  length(files)
))
if (n_fail > 0) {
  cat(
    "A formula that does not parse will not typeset; fix the .Rmd, then re-render.\n"
  )
  quit(status = 1)
}
cat("no render findings\n")
