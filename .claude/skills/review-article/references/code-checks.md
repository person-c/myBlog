# Code and metadata checks

Applies to every `.md`/`.Rmd` that contains code or front matter.

**1. Ensure Accuracy and Rigor (Primary)**
- Apply the "Cite-Then-Correct" Protocol for all substantive corrections to facts, formulas, code, and definitions
- Validate mathematical notation against AMS/LaTeX standards in .Rmd file
- Verify code against official documentation and idiomatic patterns

## R

- `library()` vs `require()`: `require()` returns a logical and silently masks missing packages — flag as `[Accuracy]` if used where `library()` (which errors loudly) is more appropriate. In non-interactive/knitr contexts, `library()` should be preferred.
- Assignment operator: Using `=` for assignment (rather than `<-`) in non-argument contexts — flag as `[Suggestion]`. Per the Tidyverse Style Guide (Tier 3), prefer `<-`.
- `sapply()` vs `vapply()`: `sapply()` returns unpredictable types (list vs. vector) depending on input. If the expected output type is known, flag as `[Suggestion]` to use `vapply()` with an explicit `FUN.VALUE`.
- Stray `setwd()`: Calling `setwd()` inside a knitr document is fragile and breaks portability. Flag as `[Repro]`.
- Unqualified `:::` (triple-colon): Using `pkg:::unexported_fun()` relies on non-API internals. Flag as `[Suggestion]` — recommend using the public API or copying the internal function with attribution.
- Hardcoded paths: Absolute paths or `~` expansion in code blocks — flag as `[Repro]`. Use relative paths or `here::here()`.
- `1:n` in loop/sequence: When `n` could be zero, `1:0` produces `c(1, 0)` rather than an empty sequence — flag as `[Accuracy]`. Recommend `seq_len(n)` or `seq_along(x)`.
- `rm(list = ls())` in a document: Destroys the reader's global environment. Flag as `[Repro]` — remove or replace with a scoped alternative.
- Missing `messages = FALSE` / `results = 'hide'` on chatty chunk options when the output is irrelevant to the narrative. Flag as `[Suggestion]`.


## Python

- Mutable default arguments: `def f(x=[])` or `def f(x={})` — the same mutable object is shared across all calls. Flag as `[Accuracy]`. Use `None` + guard: `def f(x=None): x = x or []`.
- Bare `except:` clause: `except:` without a type catches `KeyboardInterrupt` and `SystemExit`, making the program unkillable with Ctrl+C. Flag as `[Accuracy]`. Catch specific exceptions: `except ValueError:`.
- `is` vs `==`: Using `is` for value equality (e.g., `x is 5`, `x is "hello"`) relies on CPython interning — not guaranteed by the language spec. Flag as `[Accuracy]`. Reserve `is` for `None`, booleans, and identity checks.
- Late-binding closures: In a loop creating lambdas, variables are captured by name, not value — `[lambda: i for i in range(3)]` produces three functions all returning 2. Flag as `[Accuracy]`. Use `lambda i=i: i` to bind by value.
- `assert` for input validation: `assert` statements are stripped under `python -O`, so production code must not depend on them for validation. Flag as `[Accuracy]` in non-tutorial code.
- `time.time()` for measuring duration: returns wall-clock time subject to DST/NTP jumps. Flag as `[Suggestion]`. Use `time.monotonic()` or `time.perf_counter()`.
- pandas chain-assignment: `df[df.a > 0]["b"] = 1`. Under pandas ≥ 3.0 (Copy-on-Write is the only mode) it silently does nothing and `SettingWithCopyWarning` no longer exists; under 2.x it warns and the outcome is undefined. Flag as `[Suggestion]`, and say which of the two applies. Use `.loc`: `df.loc[df.a > 0, "b"] = 1`.
- `inplace=True` in pandas: still present in 3.0 — value-changing methods now return `self` instead of `None`; deprecated in 3.1, with removal planned for 4.0, shape-changing methods first (PDEP-8). Flag as `[Suggestion]`. Use explicit assignment: `df = df.drop(...)`.
- `os.system()` / `os.popen()`: passes input through the shell, risking command injection. Flag as `[Accuracy]`. Use `subprocess.run()` with `shell=False` (the default).
- Top-level mutable module state: assigning to imported module attributes (`mymodule.x = 5`) breaks composability and testability. Flag as `[Suggestion]`.
- Missing encoding on `open()`: `open("file")` uses locale-dependent encoding on Windows. Flag as `[Suggestion]`. Always specify `encoding="utf-8"`.

## Metadata (front matter)

Every Hugo content file begins with YAML front matter. Verify correctness before reviewing body content. (The litedown-generated `.html` in `content/note` is the exception — it has no front matter; its `.Rmd` carries the title and date.) `Rscript scripts/check-meta.R <file>` does the mechanical part.

- **Required fields:** `title` must be present and non-empty; `date` must be present and in ISO 8601 format (`YYYY-MM-DD`). If the file has no `date`, flag as `[Accuracy]`.
- **Date consistency:** The `date` in front matter must match the date prefix in the filename (e.g., `2025-09-19-AI-related.md` → `date: 2025-09-19`). Mismatch is an `[Accuracy]` error.
- **Lastmod:** do not hand-write it. `hugo.toml` sets `enableGitInfo = true`, so Hugo takes the date from git; a hand-written `lastmod` goes stale the moment the file is reviewed. Flag an existing `lastmod` as `[Suggestion]` — recommend deleting it.
- **Boolean fields:** `draft` must be `true` or `false` (unquoted). A quoted `"true"` or `"false"` is a YAML string, not a boolean — flag as `[Accuracy]`.
- **Categories/Tags:** `categories` and `tags` must be YAML lists, not comma-separated strings. Flag inconsistent formats across sibling articles as `[Suggestion]`.
- **Extra/Stale fields:** Flag fields Hugo does not define (e.g., `author`, custom keys, a typo in a field name) as `[Question]` — ask whether they are consumed by the theme or are leftover cruft. `layout`, `type`, `weight`, `aliases` and the like are standard, and `scripts/check-meta.R` reports only what is not.


## litedown math

The rules are in `docs/litedown.md`, section "Math protection" — read it when a formula may not render; not duplicated here. `Rscript scripts/check-math.R <file>` runs the mechanical check.
