#!/usr/bin/env Rscript

# Repository-level invariants that a typo would otherwise hide until a push.
#
# Each of these guards something that fails *silently* -- Hugo and the theme
# simply fall back to a default, so nothing looks wrong until you know what to
# look for:
#
#   * a `layout:` naming no template -> Hugo renders _default/list.html instead
#   * the dead `paginate` config key -> Hugo ignores it and uses its own default
#   * a malformed workflow YAML -> only discovered when GitHub runs it
#   * a missing robots.txt -> the sitemap goes undeclared
#   * a broken AGENTS.md import -> a coding agent silently gets no project rules
#
# Usage: Rscript scripts/check-repo.R
# Exit status: 0 = all invariants hold, 1 = findings.

root <- "."
if (!file.exists("hugo.toml")) stop("run from the repository root")

n_bad <- 0L
n_warn <- 0L
fail <- function(...) { cat("   ", ..., "\n", sep = ""); n_bad <<- n_bad + 1L }
warn <- function(...) { cat("   ", ..., "\n", sep = ""); n_warn <<- n_warn + 1L }
ok <- function(...) cat("   ", ..., " ok\n", sep = "")

# content/ramblings is a gitlink whose files are not in this repository at all
# (see AGENTS.md).  Its _index.md only exists in a working copy that still has the
# submodule, and the section is excluded from production builds -- so a dead
# layout there is reported, not failed, until the submodule question is settled.
SUBMODULE_PATHS <- "content/ramblings"

sections <- c(
  "content/blog/_index.md", "content/note/_index.md", "content/ramblings/_index.md",
  "content/slides/_index.md", "content/search/_index.md", "content/books/_index.md"
)

# ---- layout: names a template that exists -----------------------------------
cat("== layout: names resolve to a template ==\n")
theme <- "_vendor/github.com/person-c/Nothing/layouts"
for (f in sections) {
  if (!file.exists(f)) next
  x <- xfun::read_utf8(f)
  hit <- grep("^layout:", x, value = TRUE)
  if (length(hit) == 0) { cat("   ", f, " (no layout)\n", sep = ""); next }
  v <- trimws(gsub('"', "", sub("^layout:", "", hit[1])))
  found <- file.exists(file.path(theme, v, "list.html")) ||
    file.exists(file.path(theme, v, "single.html")) ||
    file.exists(file.path(theme, "_default", paste0(v, ".html"))) ||
    file.exists(file.path(theme, paste0(v, ".html")))
  if (found) {
    ok(f, " -> ", v)
  } else if (startsWith(f, SUBMODULE_PATHS)) {
    warn(f, " -> ", v, " names no template (known: this file is in the ramblings submodule,"
         , " and the section is excluded from production builds)")
  } else {
    fail(f, " -> ", v, " NAMES NO TEMPLATE (Hugo silently uses _default/list.html)")
  }
}

# ---- pagination config ------------------------------------------------------
cat("== hugo.toml pagination ==\n")
cfg <- xfun::read_utf8("hugo.toml")
if (any(grepl("^[[:space:]]*paginate[[:space:]]*=", cfg))) {
  fail("dead key 'paginate' present -- Hugo v0.128+ accepts and ignores it; use [pagination] pagerSize")
} else ok("no dead 'paginate' key")
if (any(grepl("^\\[pagination\\]", cfg)) && any(grepl("pagerSize[[:space:]]*=", cfg))) {
  ok("[pagination] pagerSize is set")
} else fail("[pagination] pagerSize missing -- the pager silently uses Hugo's own default")

# ---- workflow YAML ----------------------------------------------------------
cat("== workflow YAML parses and has the expected shape ==\n")
wf <- list.files(".github/workflows", "[.]ya?ml$", full.names = TRUE)
if (length(wf) == 0) fail("no workflows found")
for (f in sort(wf)) {
  y <- tryCatch(yaml::read_yaml(f), error = function(e) e)
  if (inherits(y, "error")) { fail(basename(f), " INVALID YAML: ", conditionMessage(y)); next }
  # YAML 1.1 (R's yaml, and the spec GitHub follows) reads a bare `on:` as TRUE
  trig <- y[[setdiff(names(y), c("name", "jobs"))]]
  if (is.null(trig) || is.null(y[["jobs"]])) { fail(basename(f), " lacks on: or jobs:"); next }
  ok(basename(f), " (", paste(names(trig), collapse = ", "), "; ", length(y[["jobs"]]), " job)")
}
if (!file.exists(".github/workflows/content-checks.yml")) fail("content-checks.yml is missing")

# ---- static assets ----------------------------------------------------------
cat("== static assets ==\n")
if (file.exists("static/robots.txt")) ok("static/robots.txt") else fail("static/robots.txt missing (sitemap undeclared)")

# ---- agent instruction files ------------------------------------------------
# AGENTS.md is the single source of truth.  CLAUDE.md is a thin adapter that
# imports it, and the review workflow lives in .agents/skills/ so every agent
# can find it.  A broken pointer is silent: the tool simply loads no
# project rules, which looks the same as a project that has none.
cat("== agent instruction files (AGENTS.md is the source of truth) ==\n")
rd <- function(f) if (file.exists(f)) xfun::read_utf8(f) else character()
for (f in c("AGENTS.md", "CLAUDE.md")) {
  if (length(rd(f)) > 0) ok(f, " exists") else fail(f, " MISSING or empty")
}
if (any(grepl("^@AGENTS\\.md[[:space:]]*$", rd("CLAUDE.md")))) {
  ok("CLAUDE.md imports @AGENTS.md")
} else fail("CLAUDE.md does not import @AGENTS.md -- Claude Code would miss the shared rules")
skill <- ".agents/skills/review-article/SKILL.md"
sk <- rd(skill)
if (length(sk) > 0 &&
    any(grepl("^name:[[:space:]]*review-article[[:space:]]*$", sk)) &&
    any(grepl("^description:", sk))) {
  ok(skill, " (name/description front matter)")
} else fail(skill, " MISSING or lacks the required name/description front matter")
if (any(grepl(".agents/skills/review-article/SKILL.md", rd("AGENTS.md"), fixed = TRUE))) {
  ok("AGENTS.md points at the review workflow")
} else fail("AGENTS.md does not point at .agents/skills/review-article/SKILL.md")

cat(sprintf("\n%d invariant(s) broken, %d warning(s)\n", n_bad, n_warn))
if (n_bad > 0) quit(status = 1)
cat("all repository invariants hold\n")
