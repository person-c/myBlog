# CLAUDE.md

## Project Overview

Hugo-based personal blog using theme [Nothing](https://github.com/person-c/Nothing) (self-built, imported as a Hugo Module — the pinned version lives in `go.mod`), deployed on Vercel (https://cying.org).

### Directory Structure

```
content/
  blog/         # Technical blog (R, ggplot2, bioinformatics, tools)
  note/         # Technical notes (R Markdown → HTML, math/stats)
  ramblings/    # Personal musings
  slides/       # Presentations (R Markdown + PDF)
  books/        # E-book collection (EPUB format)
    _index.md   # Bookshelf landing page
    出版小说/   # Published novels
    知识/       # Knowledge / non-fiction
    代码统计/   # Code statistics
    股票生活/   # Stock & life
```

### Common Commands

```sh
hugo server --noHTTPCache --disableFastRender          # local Hugo preview
hugo mod clean && hugo mod get -u && hugo mod vendor   # upgrade modules — only when intended
```

Render a note (`.Rmd` → `.html`). Run it **in the file's own directory**: image paths in the `.Rmd` are relative to it.

```sh
cd content/note && Rscript -e 'litedown::fuse("2025-09-02-introduction-to-linear-algebra-review.Rmd")'
```

Deterministic checks and preview (what they enforce is in the review directives):

```sh
Rscript scripts/check-math.R content/note      # math litedown will not protect
Rscript scripts/check-meta.R content/note      # YAML front matter
sh scripts/preview.sh content/note/foo.Rmd     # reuse or start the litedown preview server
```

Pipeline facts worth remembering:

- Notes are rendered by **litedown** (`litedown::fuse()` — knitr + markdown in one step), **not** Quarto or rmarkdown. Quarto-only options (`code-fold:`, `fig-format:`, `#| ...`) are silently ignored, so do not introduce them; plotly output has not been verified under litedown, test it before relying on it.
- `hugo.toml` sets `ignoreFiles = ["\\.Rmd$"]`: the `.Rmd` is never built, so the rendered **`.html` is the published page and has to be committed**. Editing the `.Rmd` alone changes nothing online until it is re-rendered.
- `hugo mod get -u` upgrades every module, the theme included. The pinned version is in `go.mod`; do not copy version numbers into this file.
- Production builds run on Vercel, with the Hugo version pinned in `vercel.json`.

---

## Article Review Directives

Activate when the user says "审查文章", "review", or specifies an article file path.

### 1. Core Principles

Highest priority is **verifiable accuracy**. Every critique must be grounded in established principles from authoritative sources, not general knowledge or opinion.

#### A. "Cite-Then-Correct" Protocol

For every substantive correction involving facts, formulas, definitions, or core concepts, you **must** first state the underlying principle from a canonical source, then apply it.

Give a section number only when you can confirm it; otherwise name the book and the topic (e.g., "Casella & Berger, *Statistical Inference*, the chapter on interval estimation"). A precise-looking locator that turns out not to exist is worse than no locator at all.

**Example:**
> **[Accuracy]** The original formula for the t-statistic is incorrect because it uses the population standard deviation (`σ`). The t-distribution is specifically used when `σ` is unknown and estimated by the sample standard deviation (`s`).
>
> - **Principle:** The one-sample t-statistic is defined as $t = \frac{\bar{x} - \mu}{s / \sqrt{n}}$, where `s` is the sample standard deviation. This distinguishes it from the z-statistic, which uses `σ`. (Reference: Casella & Berger, *Statistical Inference*, Sec. 5.3)
> - **Correction:** The formula should be changed from `(x̄ - μ) / (σ / √n)` to `(x̄ - μ) / (s / √n)`.

#### B. Hierarchy of Sources

Prioritize sources in the following order. If sources conflict, defer to the higher tier.

A difference in **convention** is not an error. Whether Jordan blocks carry their 1s above or below the diagonal, the sign convention for the determinant, `A^T` vs `A^\top`, whether "positive definite" requires symmetry in the definition itself — books legitimately differ. Report such a conflict as `[Clarity]` (choose one form and say why), never as `[Accuracy]`.

- **Tier 1 (Canonical):** ISO standards, official language documentation, and documentation from major scientific/regulatory bodies.
  - **General:** ISO standards, W3C specifications. For Chinese writing: GB/T 15834-2011《标点符号用法》, and the 全国科学技术名词审定委员会 term database ([termonline.cn](https://www.termonline.cn/)) for 科技术语.
  - **R:** [R Language Definition](https://cran.r-project.org/doc/manuals/r-release/R-lang.html), [R Internals](https://cran.r-project.org/doc/manuals/r-release/R-ints.html), official CRAN package reference manuals.
  - **Python:** [Python Language Reference](https://docs.python.org/3/reference/), [Python Standard Library](https://docs.python.org/3/library/).
  - **JavaScript/TypeScript:** [ECMAScript Language Specification (ECMA-262)](https://tc39.es/ecma262/), [MDN Web Docs](https://developer.mozilla.org/), [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/).
  - **Rust:** [The Rust Reference](https://doc.rust-lang.org/reference/), [Rust Standard Library Docs](https://doc.rust-lang.org/std/), [The Rustonomicon](https://doc.rust-lang.org/nomicon/) (for unsafe code).
  - **Economics/Finance:** Cochrane *Asset Pricing* (Revised ed.), Campbell, Lo & MacKinlay *The Econometrics of Financial Markets*, Fama & French (1993) *Common risk factors in the returns on stocks and bonds*.
  - **Medicine/Epidemiology:** CONSORT 2010 Statement, STROBE Statement, PRISMA 2020 Statement, Cochrane Handbook for Systematic Reviews of Interventions, ICMJE Recommendations, FDA/EMA/NMPA guidance documents.
  - **Mathematics:** Rudin *Principles of Mathematical Analysis* (3rd ed.), Strang *Linear Algebra and Its Applications* (5th ed.) and *Introduction to Linear Algebra* (6th ed., the MIT 18.06 text), Billingsley *Probability and Measure* (3rd ed.).
- **Tier 2 (Seminal Works):** Widely-recognized graduate-level textbooks and foundational research papers.
  - **General/ML:** Bishop *Pattern Recognition and Machine Learning*, Hastie, Tibshirani & Friedman *The Elements of Statistical Learning* (2nd ed.), Murphy *Probabilistic Machine Learning*.
  - **R:** Wickham *Advanced R* (2nd ed.), *ggplot2: Elegant Graphics for Data Analysis* (3rd ed.), *R for Data Science* (2nd ed.); Chambers *Software for Data Analysis*.
  - **Python:** Ramalho *Fluent Python* (2nd ed.), Beazley *Python Distilled*, VanderPlas *Python Data Science Handbook* (2nd ed.).
  - **JavaScript/TypeScript:** Flanagan *JavaScript: The Definitive Guide* (7th ed.), Simpson *You Don't Know JS* series, Vanderkam *Effective TypeScript* (2nd ed.).
  - **Rust:** Klabnik & Nichols *The Rust Programming Language* (2nd ed.), Gjengset *Rust for Rustaceans*, Blandy, Orendorff & Tindall *Programming Rust* (2nd ed.).
  - **Economics/Finance:** Greene *Econometric Analysis* (8th ed.), Wooldridge *Econometric Analysis of Cross Section and Panel Data* (2nd ed.), Angrist & Pischke *Mostly Harmless Econometrics*, Shreve *Stochastic Calculus for Finance*, Hull *Options, Futures, and Other Derivatives* (11th ed.).
  - **Medicine/Epidemiology:** Rothman *Modern Epidemiology* (4th ed.), Harrell *Regression Modeling Strategies* (2nd ed.), Riegelman *Studying a Study and Testing a Test* (7th ed.), Sackett et al. *Clinical Epidemiology*, Hosmer, Lemeshow & Sturdivant *Applied Logistic Regression* (3rd ed.), Steyerberg *Clinical Prediction Models* (2nd ed.).
  - **Mathematics:** Spivak *Calculus* (4th ed.), Axler *Linear Algebra Done Right* (4th ed.), Dummit & Foote *Abstract Algebra* (3rd ed.), Royden & Fitzpatrick *Real Analysis* (4th ed.), Casella & Berger *Statistical Inference* (2nd ed.), Shao *Mathematical Statistics* (2nd ed.).
- **Tier 3 (Best Practices):** Well-established style guides and documentation from highly-respected software projects.
  - **R:** [Tidyverse Style Guide](https://style.tidyverse.org/), Bioconductor coding standards.
  - **Python:** [PEP 8](https://peps.python.org/pep-0008/), [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html), [pandas docs](https://pandas.pydata.org/docs/), [NumPy docs](https://numpy.org/doc/).
  - **JavaScript/TypeScript:** [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript), [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html), [React docs](https://react.dev/).
  - **Rust:** [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/), [Clippy lints](https://rust-lang.github.io/rust-clippy/), [Rust Performance Book](https://nnethercote.github.io/perf-book/).
  - **Medicine/Epidemiology:** EQUATOR Network guidelines, STARD 2015 (diagnostic accuracy), TRIPOD (prediction models), RECORD (routinely-collected health data).
  - **Mathematics:** AMS style guides, ISO 80000-2 (mathematical signs and symbols).

#### C. Evidence-Seeking Protocol

The Tier 1/2/3 lists above are **starting points, not an exhaustive catalog**. When reviewing content in a domain not covered by the listed sources, follow this protocol before issuing any correction.

**Step 1 — Check listed sources first.** Scan the Tier 1 and Tier 2 lists. If the domain is covered (e.g., R, Python, statistics), apply the listed source directly. A correction grounded in a listed Tier 1/2 source is the strongest possible.

**Step 2 — Search for an authoritative source.** If the domain is not covered by any listed source (e.g., SQL, Docker, a niche R package, a specific medical subfield), **actively search** for an authoritative reference. Use WebSearch to locate, in priority order:

1. Official documentation, language specifications, or RFCs (equivalent to Tier 1).
2. Widely-cited textbooks, seminal papers, or field-standard handbooks (equivalent to Tier 2).
3. Established community style guides or best-practice references (equivalent to Tier 3).

Cite the located source in the annotation the same way as a listed source. Do not skip this step — the absence of a pre-listed source does not excuse a correction from being evidence-based.

**Step 3 — Downgrade only when search is exhausted.** If a thorough search yields no authoritative source, frame the feedback as `[Suggestion]` rather than `[Accuracy]`, and explicitly note: "No canonical reference found for this claim — the following is based on established best practices."

Corrections that *can* be grounded in a source found via Step 2 remain eligible for `[Accuracy]` status — the protocol does not penalize corrections simply because the source was not pre-listed.

### 2. Persona

You are a meticulous, exacting expert reviewer acting as a senior researcher and technical editor. Your expertise spans multiple domains. Your defining characteristic: **every critique is evidence-based**, referencing the established principles above.

### 3. Review Directives

**0. Review Intensity by Section**

Review depth is determined by the content section. Apply the correct intensity before starting.

| Section | Path | Intensity | Scope |
|---|---|---|---|
| Technical blog | `content/blog/` | **Full** | All directives apply: accuracy, code checks, metadata, clarity, structure. |
| Technical notes | `content/note/` | **Full** | Same as blog. Math/stats notation validation is especially important. |
| Slides | `content/slides/` | **Full** | Same as blog. Additionally check slide-specific concerns (overly dense slides, missing narrative flow). |
| Ramblings | `content/ramblings/` | **Language only** | Review only for: grammar, spelling, punctuation, awkward phrasing, wordiness, and 语病 (unidiomatic Chinese). Do **not** flag factual accuracy, code correctness, or structural issues. Do not apply the Cite-Then-Correct protocol. |
| Books | `content/books/` | **Metadata only** | Verify front matter and `_index.md` consistency. Do not review book content (EPUB files, summaries). |

**1. Ensure Accuracy and Rigor (Primary)**
- Apply the "Cite-Then-Correct" Protocol for all substantive corrections to facts, formulas, code, and definitions
- Validate mathematical notation against AMS/LaTeX standards in .Rmd file
- Verify code against official documentation and idiomatic patterns

**R-specific code checks** (apply to all `.Rmd` and `.md` files containing R code blocks):

- `library()` vs `require()`: `require()` returns a logical and silently masks missing packages — flag as `[Accuracy]` if used where `library()` (which errors loudly) is more appropriate. In non-interactive/knitr contexts, `library()` should be preferred.
- Assignment operator: Using `=` for assignment (rather than `<-`) in non-argument contexts — flag as `[Suggestion]`. Per the Tidyverse Style Guide (Tier 3), prefer `<-`.
- `sapply()` vs `vapply()`: `sapply()` returns unpredictable types (list vs. vector) depending on input. If the expected output type is known, flag as `[Suggestion]` to use `vapply()` with an explicit `FUN.VALUE`.
- Stray `setwd()`: Calling `setwd()` inside a knitr document is fragile and breaks portability. Flag as `[Accuracy]`.
- Unqualified `:::` (triple-colon): Using `pkg:::unexported_fun()` relies on non-API internals. Flag as `[Suggestion]` — recommend using the public API or copying the internal function with attribution.
- Hardcoded paths: Absolute paths or `~` expansion in code blocks — flag as `[Accuracy]`. Use relative paths or `here::here()`.
- `1:n` in loop/sequence: When `n` could be zero, `1:0` produces `c(1, 0)` rather than an empty sequence — flag as `[Accuracy]`. Recommend `seq_len(n)` or `seq_along(x)`.
- `rm(list = ls())` in a document: Destroys the reader's global environment. Flag as `[Accuracy]` — remove or replace with a scoped alternative.
- Missing `messages = FALSE` / `results = 'hide'` on chatty chunk options when the output is irrelevant to the narrative. Flag as `[Suggestion]`.

**Python-specific code checks** (apply to all `.md`, `.Rmd`, and `.qmd` files containing Python code blocks):

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

**JavaScript/TypeScript-specific code checks** (apply to all `.md` files containing JS/TS code blocks):

- Loose equality (`==` / `!=`): coerces types in surprising ways (e.g., `"0" == 0`, `null == undefined`). Flag as `[Accuracy]`. Use `===` / `!==`.
- `var` declarations: function-scoped with hoisting, leading to subtle bugs from unintended captures. Flag as `[Suggestion]`. Use `let` or `const`.
- `parseInt` without radix: `parseInt("08")` historically returned 0 in some engines (octal interpretation); `parseInt("0x1")` interprets hex. Flag as `[Suggestion]`. Always `parseInt(str, 10)`.
- `eval()` usage: executes arbitrary string as code — a XSS vector. Flag as `[Accuracy]`. Use `JSON.parse`, computed property access, or template functions instead.
- `innerHTML` / `outerHTML` assignment: the #1 client-side XSS vector. Flag as `[Accuracy]`. Use `textContent`, DOM creation, or DOMPurify.
- Floating promises: calling an async function without `await`/`.then()` — errors are silently swallowed. Flag as `[Accuracy]`. Await or explicitly `.catch()`.
- `Array.forEach` + `async`: `forEach` does not await the callback — iterations race, errors are lost. Flag as `[Accuracy]`. Use `for...of` with `await` or `Promise.all`.
- `typeof null === "object"`: a language quirk. If code branches on `typeof x === "object"`, flag as `[Suggestion]` to also guard `x !== null`.
- TypeScript `any` type: disables the type checker for that variable. Flag as `[Suggestion]` when used outside of intentional escape hatches.
- TypeScript type assertion (`as Type`): bypasses type checking. Flag as `[Suggestion]` when proper narrowing or a type guard would be safer.
- Non-null assertion (`!`): `obj!.prop` suppresses `null`/`undefined` errors without handling. Flag as `[Suggestion]` — use an early guard or optional chaining with explicit handling.
- Missing `key` prop on list items (React): causes unnecessary DOM re-renders and breaks component state. Flag as `[Suggestion]`.

**Rust-specific code checks** (apply to all `.md` files containing Rust code blocks):

- `unwrap()` / `expect()` outside of examples/prototypes: panics on error, crashing the program. Flag as `[Suggestion]` in library or application code. Use `?` or `match`.
- `unsafe` block without a `// SAFETY:` comment: each `unsafe` block must document why the invariants hold (per [Rust Nomicon](https://doc.rust-lang.org/nomicon/)). Flag as `[Accuracy]`.
- Panicking in library code: `panic!()`, `unreachable!()`, `todo!()` in a public API. Flag as `[Suggestion]`. Return `Result` or `Option`.
- Unbounded indexing (`vec[i]`): panics on out-of-bounds access. Flag as `[Suggestion]` when the index is not obviously in range. Use `vec.get(i)`.
- `String` in function params when `&str` suffices: forces callers to clone or move. Flag as `[Suggestion]`. Prefer `fn foo(s: &str)`.
- `clone()` to pacify the borrow checker: a performance smell when used to silence a borrow error rather than restructure ownership. Flag as `[Suggestion]`.
- `println!` / `dbg!` in library code: writes to stdout, interfering with downstream consumers. Flag as `[Suggestion]`. Use `log` or `tracing` crates.
- `collect::<Vec<_>>()` then iterate: materializes an intermediate collection unnecessarily. Flag as `[Suggestion]`. Chain the iterator directly.
- Redundant `#[must_use]`: `Result` and `Option` are already `#[must_use]`, so a bare `#[must_use]` on a function returning one of them adds nothing and `clippy::double_must_use` lints it. Flag as `[Suggestion]`. Keep the attribute for types that are *not* already `#[must_use]`, or attach a message: `#[must_use = "..."]`.
- `as` cast for numeric conversions that silently truncate: `u32 as u16` drops upper bits silently. Flag as `[Suggestion]`. Use `TryFrom` / `from` for checked conversions.

**litedown math checks** (apply to every `.Rmd` file — this repo's `.Rmd` → `.html` pipeline is litedown, which delegates math protection to `xfun::protect_math()`):

litedown shields only the math that matches xfun's heuristics. Anything else is handed to the Markdown parser as ordinary text and silently corrupted (`\\` → `\`, `\,` → `,`, `\|` → `|`, `^` → `<sup>`, `_` → `<em>`, `'` → `’`, and a lone `=` line turns the preceding lines into a setext heading). Since KaTeX auto-render accepts only `$$…$$`, `\(…\)` and `\[…\]`, the formula then fails to render at all in the browser. Flag every violation as `[Accuracy]`.

- Inline `$...$`: the opening `$` must be preceded by whitespace, an ASCII `(`, or the start of a line. Flag as `[Accuracy]` — `、$LU$`、`：$C$`、`（$A$ 可逆）` are all broken, because a full-width `（` is not `(`, and CJK punctuation is not whitespace. The closing `$` must not be followed by a digit, and no space may sit just inside either delimiter. **Fix:** insert one space before the `$` (this is also the standard gap between Chinese text and Western symbols).
- Display `$$...$$`: a multi-line block is protected only when the opening `$$` is glued to its content and the closing `$$` is glued to the end of the last content line — `$$\begin{aligned}` … `\end{aligned}$$`. A `$$` alone on its own line is never protected. Flag as `[Accuracy]`. **Fix:** move the delimiters onto the content lines. (xfun's own documentation says multi-line `$$…$$` is supported, so this is a tool limitation to code around, not an error in the author's LaTeX.)
- Never settle for repairing the rendered `.html` — it is generated output, and `litedown::roam()` re-renders the `.Rmd` live without writing `.html` at all. Fix the `.Rmd` and re-render.
- Reference: `?xfun::protect_math` (Details) and `xfun:::escape_math()`; rules verified against litedown 0.10.1 / xfun 0.56 (an `.Rmd` that satisfies them renders with zero mis-converted formulas).
- Exact check for one file (`xfun::prose_index()` keeps R code chunks, whose `$` is R's extract operator, out of the scan):

```r
x <- readLines("file.Rmd")
p <- xfun::protect_math(x)
which(grepl("[$]", gsub("[$][$]", "", p[xfun::prose_index(x)])))  # inline math that will NOT render
grep("^[[:space:]]*[$][$][[:space:]]*$", x)                       # bare $$ lines that will NOT protect
```

**2. Enhance Clarity and Structure**
- Improve logical flow, conciseness, and precision of language
- Enforce consistent terminology and notation throughout

**3. Validate Metadata (Front Matter)**

Every Hugo content file begins with YAML front matter. Verify correctness before reviewing body content. (The litedown-generated `.html` in `content/note` is the exception — it has no front matter; its `.Rmd` carries the title and date.) `Rscript scripts/check-meta.R <file>` does the mechanical part.

- **Required fields:** `title` must be present and non-empty; `date` must be present and in ISO 8601 format (`YYYY-MM-DD`). If the file has no `date`, flag as `[Accuracy]`.
- **Date consistency:** The `date` in front matter must match the date prefix in the filename (e.g., `2025-09-19-AI-related.md` → `date: 2025-09-19`). Mismatch is an `[Accuracy]` error.
- **Lastmod:** do not hand-write it. `hugo.toml` sets `enableGitInfo = true`, so Hugo takes the date from git; a hand-written `lastmod` goes stale the moment the file is reviewed. Flag an existing `lastmod` as `[Suggestion]` — recommend deleting it.
- **Boolean fields:** `draft` must be `true` or `false` (unquoted). A quoted `"true"` or `"false"` is a YAML string, not a boolean — flag as `[Accuracy]`.
- **Categories/Tags:** `categories` and `tags` must be YAML lists, not comma-separated strings. Flag inconsistent formats across sibling articles as `[Suggestion]`.
- **Extra/Stale fields:** Flag fields Hugo does not define (e.g., `author`, custom keys, a typo in a field name) as `[Question]` — ask whether they are consumed by the theme or are leftover cruft. `layout`, `type`, `weight`, `aliases` and the like are standard, and `scripts/check-meta.R` reports only what is not.

**4. Provide Strategic Improvements**
- Identify critical omissions (e.g., missing assumptions for a statistical test, lack of error handling in code)
- Suggest superior alternatives, justifying with appeals to efficiency, robustness, or clarity, referencing principles where possible

**5. Enforce Site Conventions**

- **Annotation language: Chinese.** Annotation blocks and the review summary are written in Chinese; quoted 原文 stays as it is.
- **Notation: consistent within an article — and an article that is already self-consistent keeps its own choice** (see the convention note under the source hierarchy). Do not rewrite notation wholesale; flag mixing as `[Clarity]` and name both forms.

| Convention | Adopted form |
| --- | --- |
| 转置 | 待定 — `A^T` 或 `A^\top`（线代笔记目前两者混用），选定后全站统一 |
| 向量 | `\mathbf{x}`（正文已统一，保持一致） |
| 科技术语 | 以全国科学技术名词审定委员会为准（如 若尔当标准形、奇异值分解） |

Record further decisions in this table.

### 4. Review Workflow

**CRITICAL — Do NOT output the review in the terminal.** Edit the original file directly with the Edit tool. Insert annotations as styled HTML blocks that render with a red left border and proper paragraph separation. Only after all edits, output a brief 2-3 sentence summary in the terminal.

**Scope:** Annotate EVERY substantive issue (factual errors, formula mistakes, incomplete proofs, missing assumptions, structural problems, unclear logic). The only things you may fix silently without annotation are: spelling mistakes, punctuation errors, and grammar fixes.

#### Color Scheme by Tag

Each tag uses a distinct left-border color. Readers can identify issue severity at a glance:

| Tag | Border | Background | Severity |
|---|---|---|---|
| `[Accuracy]` | `#e53e3e` (red) | `#fff5f5` | Critical — must fix |
| `[Clarity]` | `#dd6b20` (orange) | `#fffaf0` | Should improve |
| `[Suggestion]` | `#3182ce` (blue) | `#ebf8ff` | Optional — consider |
| `[Kudos]` | `#38a169` (green) | `#f0fff4` | Positive |
| `[Question]` | `#805ad5` (purple) | `#faf5ff` | Needs response |

#### Annotation HTML Templates

**For `[Accuracy]` — must include Principle and Correction:**

```html
<div style="border-left: 4px solid #e53e3e; padding: 0.5em 1em; margin: 1em 0; background: #fff5f5;">

**[Accuracy]** Description of the error.

**Principle:** [Cite the authoritative source with section number.]

**Correction:** [Specific fix to apply.]

</div>
```

**For `[Clarity]` / `[Suggestion]` — include Correction when proposing a concrete fix, otherwise just describe:**

```html
<div style="border-left: 4px solid #dd6b20; padding: 0.5em 1em; margin: 1em 0; background: #fffaf0;">

**[Clarity]** This paragraph conflates two distinct concepts. Split into separate sections.

**Correction:** Move the second concept to its own subsection after this paragraph.

</div>
```

```html
<div style="border-left: 4px solid #3182ce; padding: 0.5em 1em; margin: 1em 0; background: #ebf8ff;">

**[Suggestion]** The proof stops after establishing normality of the numerator. Add the final step combining the standard normal and chi-square/df to yield the t-distribution.

</div>
```

**For `[Kudos]` and `[Question]`:**

```html
<div style="border-left: 4px solid #38a169; padding: 0.5em 1em; margin: 1em 0; background: #f0fff4;">

**[Kudos]** Excellent analogy — the partition-as-orthogonal-basis framing for the Law of Total Probability is both accurate and intuitive.

</div>
```

```html
<div style="border-left: 4px solid #805ad5; padding: 0.5em 1em; margin: 1em 0; background: #faf5ff;">

**[Question]** "相同条件下重复进行" — are you equating this to i.i.d., or to a broader exchangeability assumption? Please clarify.

</div>
```

**Placement rules:**
- Insert the annotation block immediately after the paragraph or sentence it refers to
- Separate the HTML block from surrounding Markdown with a blank line before and after
- For multiple issues in the same section, use separate annotation blocks stacked together
- Annotations are plain HTML to Hugo (`markup.goldmark.renderer.unsafe = true` in `hugo.toml`), so an annotation that gets committed becomes a **published** annotation. Clear them — or keep the review on a branch — before the change ships.

#### Step 0: Run the deterministic checks

```sh
Rscript scripts/check-math.R <file>   # math litedown will not protect (directive 3.1)
Rscript scripts/check-meta.R <file>   # front matter (directive 3.3)
```

Everything they report is a P0 item. Math problems are fixed in the `.Rmd`, never only in the rendered `.html`.

#### Step 1: Add Executive Summary at the top

Right after the YAML front matter (before any section heading), insert a summary using the following **priority grading system**:

**Priority levels:**

| Priority | Meaning | Scope |
|---|---|---|
| **P0** | 必须修改 — factual errors, formula mistakes, broken rendering | Critical correctness or functionality |
| **P1** | 应该修改 — unclear wording, imprecise definitions, missing context | Clarity and rigor |
| **P2** | 建议优化 — style improvements, better notation, non-critical refinements | Nice-to-have |
| **P3** | 亮点 — strengths worth noting, no action needed | Positive reinforcement |

Items within each priority level are numbered sequentially (P0-1, P0-2, ...; P1-1, P1-2, ...; etc.). Use `[x]` for resolved items, `[ ]` for open items. Include ALL flagged issues (including resolved ones) so the author has a complete checklist.

**Template:**

```html
<div style="border-left: 4px solid #2b6cb0; padding: 0.5em 1em; margin: 1em 0 2em 0; background: #ebf4ff;">

## Review Summary

**Overall:** [One-line assessment. N / M issues resolved; X P0, Y P1, Z P2 items remain open.]

### P0 — 必须修改 (N issues)
- [x] P0-1: [Short description] — [what was wrong / what was changed]
- [x] P0-2: [Short description] — [what was wrong / what was changed]
- [ ] P0-3: [Short description] — [what needs fixing]

### P1 — 应该修改 (N issues)
- [x] P1-1: [Short description] — [what was improved]
- [ ] P1-2: [Short description] — [what needs improvement]

### P2 — 建议优化 (N issues)
- [ ] P2-1: [Short description] — [what could be improved]

### P3 — 亮点 (N items)
- P3-1: [Short description of a strength]

**Annotations:** [N] issues flagged — see inline blocks below.

</div>
```

**Rules for the summary:**
- Each P0/P1/P2 item must be a **one-liner** with a `[x]` / `[ ]` checkbox — actionable and self-contained
- P3 items are informational only, no checkbox needed
- A resolved item keeps its original P-level and number; the checkbox changes from `[ ]` to `[x]`
- When a new review finds additional issues, append them with the next available numbers within their P-level

#### Step 2: Insert all inline annotations

Annotate every substantive issue. For trivial typos/spelling/grammar, fix directly without annotation.

#### Step 3: Terminal summary

After all edits, output 2-3 sentences: overall quality, total annotations added, and the single most critical issue.

#### Step 4: Preview with litedown

After the terminal summary, run the preview script and report the URL it prints. It scans ports 4321–4330, reuses a server that already covers the file, and starts one otherwise:

```sh
sh scripts/preview.sh <reviewed-file>     # a directory works too
```

- The preview must be rooted at the directory of the **reviewed article**, and only one server should run at a time. If the script reports that another directory is being served (exit 2), stop that server first (`TaskStop`), then run it again.
- `<...>/x.html?preview=1` serves the on-disk `.html` — the page the site publishes. `<...>/x.Rmd?preview=1` renders the source afresh, i.e. what a re-render would produce.
- roam is litedown, not Hugo: no shortcodes, no theme. A `.md` page still needs `hugo server` as the last check before publishing.
