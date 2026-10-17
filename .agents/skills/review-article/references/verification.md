# Verification: evidence before correction

A correction is a claim about the world, and it ships with the evidence that makes it
checkable. "I remember that the textbook says so" is not evidence — it is the shape of
evidence, and it is how a confident wrong correction gets published.

Read this file before writing any `[Accuracy]` annotation, and again before the review is
declared finished.

## The evidence gate

Every `[Accuracy]` and `[Render]` annotation carries an **Evidence:** line in exactly one of
these three forms. No evidence line, no P0.

**1. Run** — a copy-pasteable command and its actual output. The output is the artifact; a
command that was not run is not evidence.

```html
**Evidence:** `Rscript -e 'set.seed(1); A <- crossprod(matrix(rnorm(12), 4)); C <- chol(A); stopifnot(isTRUE(all.equal(A, crossprod(C)))); cat("t(C) %*% C == A\n")'`
→ `t(C) %*% C == A`
```

(Verified before writing this file; in PowerShell swap the quoting as `AGENTS.md` describes
for `litedown::fuse()`.)

When the check already lives in the article's own chunk (`stopifnot` in a figure chunk is
the house pattern), cite the chunk label instead of repeating the code:

```html
**Evidence:** the `fig-proj-plane` chunk's self-check — `stopifnot(all(abs(crossprod(A, e)) < 1e-10))` — passes at render.
```

**2. Quote** — the printed source, verbatim, with an edition and a page (or a stable URL
plus the sentence). The angle brackets are filled from your own copy of the book:

> Strang, *Introduction to Linear Algebra* (6th ed.), p. <page>: "<the sentence exactly as
> printed, with its notation>".

A locator without a quote is a memory claim: the reader cannot tell a real section number
from a plausible one. Downgrade it.

**3. Derivation** — the one to three steps that establish the claim from definitions the
article already states (or from a Tier-1 definition), written out in the annotation:

```html
**Evidence:** $A = CC^{\mathrm{T}} \Rightarrow \mathbf{x}^{\mathrm{T}}A\mathbf{x} = \mathbf{x}^{\mathrm{T}}CC^{\mathrm{T}}\mathbf{x} = \lVert C^{\mathrm{T}}\mathbf{x}\rVert^2 \ge 0$, with equality only when $C^{\mathrm{T}}\mathbf{x} = \mathbf{0}$, i.e. $\mathbf{x} = \mathbf{0}$ because $C$ is invertible.
```

If none of the three is available, the item is not a P0:

- the author must answer something → `[Question]`
- otherwise → `[Suggestion]`

## Two ways the old process failed

The examples are mathematical because the review they come from was; the rule they break is
not. Both would have been caught by the gate:

- **A right observation, a wrong fix.** The annotation said `R` carries three meanings and
  proposed changing `A = R^{\mathrm{T}}R` to use `C`, "to match Cholesky's `A = CC^{\mathrm{T}}`".
  Substitute and check: it yields `A = C^{\mathrm{T}}C`, not `CC^{\mathrm{T}}`. The observation
  was worth keeping; the correction was false. **Run** the substitution.
- **A locator that had moved.** The annotation told the author to record the decision in
  "CLAUDE.md's writing-conventions table"; that table had moved to `AGENTS.md`, and
  `CLAUDE.md` is now a shim that only imports it. A project convention is quoted from the
  file that holds it, read at review time — a citation to a moved file is evidence that the
  reviewer worked from stale context.
- **A default read off memory.** "This function defaults to X", "this package requires Y",
  "this release changed Z" — each is checkable in one line (`formals()`, `args()`,
  `packageDescription()`, the reference page, the release notes). If the reviewer did not
  run it, it is a `[Question]`, whatever the topic.

## The second-reading rule

If the text admits a second correct reading, it is not an error.

Example from this blog: `α/(k(k-1)/2 + 1)` is wrong if only the pairwise tests are in the
family, but correct if the family includes the omnibus χ² test (`c = k(k-1)/2 + 1`). That
is a `[Question]` — "which family does your α control?" — never `[Accuracy]`. Before
calling something false, say why every other reading is false.

## Grading discipline

P0 is about the **claim**, not the topic. A wrong statement about an R function's default, a
package's requirement, a method's assumption, or a paper's result is as much a P0 as a wrong
formula — this blog is mostly not mathematics, and the gate applies to every domain.

- **P0** — a statement the article presents as fact is false, or the page will not render or
  run what it shows. False here means contradicted by a run, a quoted source, or the
  article's own other passage — not "I would phrase this differently", not "this symbol is
  unusual", not "the textbook I prefer uses another convention".
- **P1** — a notation, term, or structure choice that a competent reader can still follow;
  the claim stays true.
- **P2** — taste.
- A difference in convention is `[Clarity]` at most (`references/sources.md` §B).
- A superlative or number with no source ("the fastest", "most packages") is not P0 — it is
  `[Question]` ("compared with what?") or `[Suggestion]`.

| What is being claimed | P0 means | Evidence that settles it |
|---|---|---|
| Formula, theorem, definition | false as stated | Run (counterexample, random-matrix check), Derivation, or Quote |
| Code (R, Python, shell) | it does not run, or does not do what the text says | Run it; quote the official reference for the behaviour |
| Tool, package, data or domain fact | contradicted by the docs, the paper, or the release notes | Quote with the version (and the date, for a release) |
| Statistical or epidemiological method | wrong formula, wrong assumption, wrong interpretation of a quantity | Quote the source, or Run the computation on a constructed example |
| The article against itself | two passages state incompatible things | Quote both passages and say which one must give |
| Metadata, links, versions | a field Hugo does not use, a link that does not resolve, a pin that does not exist | Run the check (`check-meta`, `git ls-remote`, resolve the URL) |
| Rendering | the page will not display what it shows | `check-math` / `check-render` output |

A notation error that leaves the statement true is P1; one that changes what the statement
says — `A = C^{\mathrm{T}}C` for `A = CC^{\mathrm{T}}` — is P0, because the claim is now
false.

## The adversarial pass

After the annotations are written and before the summary is finalised, run one rebuttal
round with a **fresh context** — a `subagent`, a second model, or a separate session. This
subprocess inherits none of the review's assumptions. It must not add new annotations.

Prompt template (paste the annotation blocks and the paragraph each one refers to):

```text
You are an adversarial technical reviewer. Below are review annotations on an article, and
the source text each one refers to. Your only job is to try to refute them.

For each annotation, answer:
1. Is the cited source real, and does it say what the annotation claims? Quote the relevant
   sentence verbatim from a primary source. If you cannot quote it, say so. If the evidence
   is a command, re-run it and compare the output.
2. Is the derivation or counterexample valid? Recompute it; show the one line that settles it.
3. Does the source text admit a second correct reading that the annotation ignores?
4. Is the grade right: is this really false (P0), or merely unconventional (P1/P2)?

Answer per item with exactly one verdict — CONFIRMED / REFUTED / UNSURE — and at most two
sentences of justification. Do not add new findings and do not rewrite the article.
```

Then:

| Verdict | Action |
|---|---|
| CONFIRMED | keep the annotation, add the rebuttal's quote or computation to its **Evidence:** line if it is stronger |
| REFUTED | delete the annotation, or replace it with the narrower true claim |
| UNSURE | keep it as `[Question]`, explaining what the author must resolve |

The pass is cheap: one subagent call for all annotations of one article. Skip it only for
`content/ramblings/` (language-only reviews) and for metadata-only reviews.

## What each check can and cannot see

| Check | Sees | Blind to |
|---|---|---|
| `scripts/check-math.R` | math litedown will not protect | whether the math is true |
| `scripts/check-meta.R` | front matter shape | everything else |
| `scripts/check-render.R` | unbalanced braces / `\left`-`\right` / `\begin`-`\end` in the TeX that actually reaches KaTeX; a `$` left in visible text; figure/caption mismatch; missing or too-deep TOC; a loaded `@fold-details` with no `<pre>` | KaTeX parse errors only the browser sees; whether a figure draws what its caption says |
| `scripts/check-fresh.R` | `.Rmd` vs `.html` drift | content |
| the evidence gate | the claim itself | claims nobody wrote down |

A green run of the scripts removes the mechanical failure classes. It is not a correctness
proof, and no run of any script makes a mathematical claim true.

## Stale annotations

Annotations quote the text they judge; once the author edits that text, the quote can stop
existing. After a fix:

1. re-run `scripts/check-render.R` (the page changed);
2. re-run the commands in every **Evidence:** line that is a Run;
3. flip `[ ]` to `[x]` only for the items whose evidence still passes;
4. if the quoted sentence is gone, rewrite or delete the annotation — do not leave a note
   pointing at text that no longer exists.
