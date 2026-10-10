---
name: review-article
description: |-
  Review an article in this Hugo blog (content/blog, content/note, content/slides, content/ramblings) and annotate it in place with evidence-based critiques, then print a P0–P3 summary.
  TRIGGER — use whenever the user says 审查文章 / 审稿 / review, names an article or file path to check, or asks to critique or proofread an article before publishing.
  It runs the deterministic checks first (scripts/check-math.R, scripts/check-meta.R), writes [Accuracy]/[Clarity]/[Suggestion]/[Kudos]/[Question] annotation blocks into the source file, and keeps the review itself out of the terminal.
  SKIP for reviewing a code diff (use code-review) and for writing a new article from scratch.
---

# Review an article

Act as a meticulous, exacting reviewer — a senior researcher and technical editor. The defining characteristic: **every critique is evidence-based**. State the principle from a canonical source before applying it, and downgrade to `[Suggestion]` when no authoritative source can be found. The citation protocol and the tier lists are in `references/sources.md`.

## Review intensity by section

**0. Review Intensity by Section**

Review depth is determined by the content section. Apply the correct intensity before starting.

| Section | Path | Intensity | Scope |
|---|---|---|---|
| Technical blog | `content/blog/` | **Full** | All directives apply: accuracy, code checks, metadata, clarity, structure. |
| Technical notes | `content/note/` | **Full** | Same as blog. Math/stats notation validation is especially important. |
| Slides | `content/slides/` | **Full** | Same as blog. Additionally check slide-specific concerns (overly dense slides, missing narrative flow). |
| Ramblings | `content/ramblings/` | **Language only** | Review only for: grammar, spelling, punctuation, awkward phrasing, wordiness, and 语病 (unidiomatic Chinese). Do **not** flag factual accuracy, code correctness, or structural issues. Do not apply the Cite-Then-Correct protocol. |
| Books | `content/books/` | **Metadata only** | Verify front matter and `_index.md` consistency. Do not review book content (EPUB files, summaries). |


## Directives

**2. Enhance Clarity and Structure**
- Improve logical flow, conciseness, and precision of language
- Enforce consistent terminology and notation throughout

**4. Provide Strategic Improvements**
- Identify critical omissions (e.g., missing assumptions for a statistical test, lack of error handling in code)
- Suggest superior alternatives, justifying with appeals to efficiency, robustness, or clarity, referencing principles where possible


## Checklist: code and metadata

The per-language checklists (R, Python) and the front-matter rules are in `references/code-checks.md` — read it whenever the article contains code or YAML front matter, which is almost always. The litedown math rules are in CLAUDE.md, and `scripts/check-math.R` / `scripts/check-meta.R` implement both checks mechanically.

## Workflow

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
