---
title: miscellaneous tricks in r
date: 2024-02-12
lastmod: 2026-07-22
---

<div style="border-left: 4px solid #2b6cb0; padding: 0.5em 1em; margin: 1em 0 2em 0; background: #ebf4ff;">

## Review Summary

**Overall:** A useful collection of R metaprogramming and data.table techniques, but the code blocks are missing required `library()` calls and the source attribution is incomplete.

**Critical issues:**
1. Two code blocks are missing `library()` calls — the first uses `rlang::syms()`, `purrr::map2()`, and `rlang::expr()` without loading them; the third uses `survival::coxph()` and `survival::cox.zph()` without loading the package.
2. The Stack Overflow attribution is a bare link placeholder with no actual URL — readers cannot trace the original source.
3. A sentence in the introduction conflates tidyverse design goals with base R behavior, making it hard to follow.

**Annotations:** 6 issues flagged — see inline blocks below.

</div>

About a year ago, I decided to stop using `dplyr` for data processing and switched to using `data.table`. One important reason is its more concise syntax in most situations and faster performance. Another reason is that using tidy-like code often involves loading many packages, leading to a miscellaneous workspace. Tidy-like code typically involves repeating some behaviors in base R but provides a unified interface for performing tasks more conveniently and rigorously.

<div style="border-left: 4px solid #dd6b20; padding: 0.5em 1em; margin: 1em 0; background: #fffaf0;">

**[Clarity]** The phrase "repeating some behaviors in base R" is ambiguous. Tidyverse packages don't "repeat" base R — they re-implement and extend base R functionality with a different philosophy (non-standard evaluation, functional programming primitives). Similarly, "miscellaneous workspace" is non-standard; consider "cluttered namespace" or "packed search path."

**Correction:** Reword to clarify the trade-off: "Tidyverse code wraps common base R operations in a more consistent API, at the cost of depending on many packages and creating a cluttered namespace."

</div>

In certain cases, we might want to generate an R expression for later use. A concrete example is producing a linear expression from a named vector:

```r
fit <- c(x = 1, y = 2)

coef_sym <- syms(names(fit))
coefs <- unname(fit)

summands <- map2(coef_sym, coefs, ~ expr((!!.x * !!.y)))
eq <- purrr::reduce(summands, ~ expr(!!.x + !!.y))
```

<div style="border-left: 4px solid #e53e3e; padding: 0.5em 1em; margin: 1em 0; background: #fff5f5;">

**[Accuracy]** The code block is incomplete — it uses `syms()`, `map2()`, and `expr()` without loading the required packages.

**Principle:** R code in instructional materials should be self-contained and reproducible. (Reference: [R FAQ 7.32](https://cran.r-project.org/doc/FAQ/R-FAQ.html), which recommends that examples include necessary `library()` calls.)

**Correction:** Add `library(rlang)` and `library(purrr)` at the top of the code block. Note that `syms()`, `expr()` are from rlang, while `map2()` is from purrr. The `purrr::reduce()` call correctly uses the namespace prefix, but the other functions do not.

</div>

This solution is from the [Advanced R](https://adv-r.hadley.nz/quasiquotation.html#expr-case-studies) book. The `rlang` and `purrr` packages provide functions related to non-standard evaluation (NSE) and functional programming tools. However, achieving the same result is possible using functions in base R.

<div style="border-left: 4px solid #dd6b20; padding: 0.5em 1em; margin: 1em 0; background: #fffaf0;">

**[Clarity]** The sentence conflates two distinct responsibilities: `rlang` provides NSE tools (`syms()`, `expr()`, `!!`), while `purrr` provides functional programming tools (`map2()`, `reduce()`). The current phrasing reads as if both packages provide both categories.

**Correction:** Split into: "The `rlang` package provides non-standard evaluation (NSE) tools such as `syms()` and `expr()`, while `purrr` provides functional programming primitives such as `map2()` and `reduce()`."

</div>

Some functions related to metaprogramming are listed below:

- `parse` and `deparse`: Convert between character string and expression.
- `quote`: Quote an R expression.
- `expression`: Quote multiple R expressions.
- `bquote`: Quoting and unquoting within a function call.
- `substitute`: Substitutes the values of variables into an R expression.
- `call` and `as.call`: Construct a function call.
- `eval`: Evaluate an R expression in a specified environment.

`bquote`:

>An analogue of the LISP backquote macro. `bquote` quotes its argument, except that terms wrapped in .() are evaluated in the specified environment. If `splice = TRUE`, then terms wrapped in ..() are evaluated and spliced into a call.

`substitute`:

>`substitute` returns the parse tree for the (unevaluated) expression `expr`, substituting any variables bound in `env`.

Thus, we can do it like this:

```r
# Assuming 'fit' is a named numeric vector
fit <- c(x = 1, y = 2)

coef_sym <- names(fit)
coefs <- unname(fit)

summands <- mapply(function(x, y) bquote(.(as.name(x)) * .(y)), coef_sym, coefs, SIMPLIFY = FALSE)
eq <- Reduce(function(x, y) bquote(.(x) + .(y)), summands)
```

In `data.table`, we might want to construct different models for various variables, such as performing univariate Cox regression for multiple variables. We can achieve this as follows (this solution was originally from [Stack Overflow](https://stackoverflow.com/)):

<div style="border-left: 4px solid #e53e3e; padding: 0.5em 1em; margin: 1em 0; background: #fff5f5;">

**[Accuracy]** The Stack Overflow link points to the homepage (`https://stackoverflow.com/`), not to the specific answer that the solution was derived from. Readers cannot verify or trace the original source.

**Principle:** Attribution URLs in technical writing should point to the specific resource, not a landing page — otherwise the attribution is functionally broken. (Reference: The "cite what you use" principle from the [Tidyverse Style Guide](https://style.tidyverse.org/documentation.html), Sec. "Linking.")

**Correction:** Replace the URL with a permalink to the actual Stack Overflow answer (e.g., `https://stackoverflow.com/q/<question-id>/` or `https://stackoverflow.com/a/<answer-id>/`). If the original source is lost, note that explicitly.

</div>

```r
candidate <- c('ARG1', 'CASP9')
dt <- data.table(exp_vars = candidate)
formulas <- sprintf("Surv(OS, vital_status) ~ %s", candidate)

dt[, let(model = lapply(formulas, function(f) coxph(as.formula(f), data = train)) ), by = exp_vars]
dt[, let( # get p value
  p.cox = sapply(model, function(mod) summary(mod)$coefficients[1, "Pr(>|z|)"]),
  p.cox.zph = sapply(model, function(model) cox.zph(model)$table[1, 3])
)]
```

<div style="border-left: 4px solid #e53e3e; padding: 0.5em 1em; margin: 1em 0; background: #fff5f5;">

**[Accuracy]** The code block is missing `library(survival)` and references an undefined variable `train`.

**Principle:** `coxph()` and `cox.zph()` are from the **survival** package, which must be loaded before use. Additionally, `Surv()` in the formula on line 108 requires the survival package. The variable `train` used as the `data` argument is never defined — in a reproducible example, it should be replaced with a built-in dataset (e.g., `survival::lung`) or defined explicitly. (Reference: [R FAQ 7.32](https://cran.r-project.org/doc/FAQ/R-FAQ.html) on writing reproducible examples.)

**Correction:** Add `library(survival)` and `library(data.table)` at the top of the code block. Replace `train` with a defined dataset, e.g., `data(lung, package = "survival")` and use `data = lung`.

</div>

<div style="border-left: 4px solid #3182ce; padding: 0.5em 1em; margin: 1em 0; background: #ebf8ff;">

**[Suggestion]** Lines 112-113 use `sapply()` to extract p-values and ZPH test results from model objects. Since the expected return type is always a numeric vector of the same length as `model`, `vapply()` with an explicit `FUN.VALUE = numeric(1)` would be safer — it will error informatively if any model fails rather than silently returning a list. (Reference: [Tidyverse Style Guide](https://style.tidyverse.org/), Sec. "Avoid sapply.")

</div>