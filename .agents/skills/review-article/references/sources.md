# Sources and citation protocol

Highest priority is **verifiable accuracy**. Every critique must be grounded in established principles from authoritative sources, not general knowledge or opinion.

This is not a mathematics-only rule. A false claim about an R function's default, a package's version requirement, a method's assumption, or a paper's result is as much a P0 as a wrong formula; the evidence forms and the per-domain table are in `references/verification.md`.

## A. "Cite-Then-Correct" Protocol

For every substantive correction involving facts, formulas, definitions, or core concepts, you **must** first state the underlying principle from a canonical source, then apply it.

Give a section number only when you can confirm it; otherwise name the book and the topic (e.g., "Casella & Berger, *Statistical Inference*, the chapter on interval estimation"). A precise-looking locator that turns out not to exist is worse than no locator at all.

**A citation must be quotable.** Quote the sentence or formula as printed, with the edition and page — or give a stable URL and the words on the page. A locator remembered without the text is a memory claim: it cannot carry `[Accuracy]` (the three evidence forms are in `references/verification.md`). When the source states a convention and the article chose another, that is `[Clarity]`, never an error — see §B.

**Example:**
> **[Accuracy]** The original formula for the t-statistic is incorrect because it uses the population standard deviation (`σ`). The t-distribution is specifically used when `σ` is unknown and estimated by the sample standard deviation (`s`).
>
> - **Principle:** The one-sample t-statistic is defined as $t = \frac{\bar{x} - \mu}{s / \sqrt{n}}$, where `s` is the sample standard deviation. This distinguishes it from the z-statistic, which uses `σ`. (Reference: Casella & Berger, *Statistical Inference*, Sec. 5.3)
> - **Correction:** The formula should be changed from `(x̄ - μ) / (σ / √n)` to `(x̄ - μ) / (s / √n)`.

## B. Hierarchy of Sources

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

## C. Evidence-Seeking Protocol

The Tier 1/2/3 lists above are **starting points, not an exhaustive catalog**. When reviewing content in a domain not covered by the listed sources, follow this protocol before issuing any correction.

**Step 1 — Check listed sources first.** Scan the Tier 1 and Tier 2 lists. If the domain is covered (e.g., R, Python, statistics), apply the listed source directly. A correction grounded in a listed Tier 1/2 source is the strongest possible.

**Step 2 — Search for an authoritative source.** If the domain is not covered by any listed source (e.g., SQL, Docker, a niche R package, a specific medical subfield), **actively search** for an authoritative reference. Use WebSearch to locate, in priority order:

1. Official documentation, language specifications, or RFCs (equivalent to Tier 1).
2. Widely-cited textbooks, seminal papers, or field-standard handbooks (equivalent to Tier 2).
3. Established community style guides or best-practice references (equivalent to Tier 3).

Cite the located source in the annotation the same way as a listed source. Do not skip this step — the absence of a pre-listed source does not excuse a correction from being evidence-based.

**Step 3 — Downgrade only when search is exhausted.** If a thorough search yields no authoritative source, frame the feedback as `[Suggestion]` rather than `[Accuracy]`, and explicitly note: "No canonical reference found for this claim — the following is based on established best practices."

Corrections that *can* be grounded in a source found via Step 2 remain eligible for `[Accuracy]` status — the protocol does not penalize corrections simply because the source was not pre-listed.

