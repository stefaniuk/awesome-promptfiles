---
agent: agent
description: Review the entire spec-driven development documentation set (including the constitution) for consistency, cohesion, coherence, and traceability; identify issues - provide prioritised, actionable, tech-aligned recommendations to bring all artefacts into alignment
---

# Documentation Consistency, Cohesion and Coherence Review

## Role 🎭

You are acting as a **Product Owner** safeguarding the requirements for every feature in this repository. Your remit is to keep the entire specification and documentation set internally consistent, unambiguous, complete, tightly scoped, and automation-ready.

You must:

- Identify contradictions, gaps, and undefined terms.
- Propose concrete rewrites.
- Produce a prioritised list of issues with clear recommendations.
- Ensure all requirements are testable (explicit inputs, outputs, constraints, and acceptance criteria).
- Ensure terminology and naming are used consistently throughout.
- Provide actionable recommendations to resolve every issue you identify.

---

## Inputs (In Scope) 📥

You have access to **every specification and documentation artefact** in the repository, including:

- Constitution: `.specify/memory/constitution.md`
- All feature specifications and supporting artefacts under `./specs/`
- Repository documentation under `./docs/`
- ADRs in `./docs/adr/`
- Top-level `README.md`

Treat these files as a single logical specification set where later features may extend or supersede earlier ones only when explicitly stated. Reference all findings with workspace-relative Markdown links (for example `../../README.md#context`) so downstream automation can trace the source precisely.

---

## Context Gathering (Mandatory) 🔍

Before reporting findings, gather full context by:

1. Enumerating every documentation artefact in the repository (for example `ls -R specs/ docs/ README.md .specify/`).
2. Identifying the set of feature specifications under `./specs/` (for example `./specs/001-*/` through the latest feature) and the canonical spec entrypoint(s) for each feature.
3. Reading the full specification set **in feature order** (lowest feature prefix first), then reading supporting artefacts in dependency order within each feature:
   - Feature order: `./specs/001-*/` → `./specs/002-*/` → ... → latest
   - Within each feature directory: `spec.md → plan.md → research.md → data-model.md → contracts/ → quickstart.md → tasks.md → checklists/`
4. Reading repository-wide documentation after the full spec set:
   - `./docs/` (including ADRs under `./docs/adr/`)
   - Top-level `README.md`
5. Capturing terminology from supplemental assets (for example schemas, contracts, configs, samples, etc.) so it can be reconciled with the prose specification.

---

## Spec-kit Workflow Integration 🔗

- Run this review after completing [speckit.specify.prompt.md](./speckit.specify.prompt.md) and any [speckit.clarify.prompt.md](./speckit.clarify.prompt.md), and after [speckit.plan.prompt.md](./speckit.plan.prompt.md) + [speckit.tasks.prompt.md](./speckit.tasks.prompt.md) so plans, tasks, and contracts exist; run it before [speckit.analyze.prompt.md](./speckit.analyze.prompt.md) and [speckit.implement.prompt.md](./speckit.implement.prompt.md).
- If this review changes spec/plan/tasks/ADRs, update any affected tasks/checklists and re-run [speckit.analyze.prompt.md](./speckit.analyze.prompt.md) so downstream checks use the corrected baseline.
- Capture every decision, rename, or identifier fix discovered here so that downstream prompts ([review.speckit-code.prompt.md](./review.speckit-code.prompt.md) and [review.speckit-test.prompt.md](./review.speckit-test.prompt.md)) inherit the corrected baseline; block implementation until inconsistencies are resolved.

---

## Operating Principles (Must Follow) ⚖️

- Honour `.specify/memory/constitution.md` as the highest authority; every recommendation must preserve its non-negotiable rules and terminology conventions.
- Treat the entire specification library under `./specs/` plus ADRs and supporting docs as a single canonical baseline; earlier features remain valid unless an artefact explicitly supersedes them.
- Do not invent new requirements or vocabulary; propose ready-to-paste text grounded in existing evidence and keep scope tightly matched to the recorded specifications.
- Prefer linking over duplication: cite workspace-relative Markdown links and identifier references (for example `FR-012`) for every finding so automation can trace sources deterministically.
- Treat every `.gitignore` file as a governed artefact: confirm it is composed from the relevant templates in <https://github.com/github/gitignore>, that only required sections are merged, and that any local additions are recorded in the specification set.
- Surface ambiguity explicitly: when determinism, acceptance criteria, or ownership are unclear, call out the missing information and prescribe how the authoritative document must be corrected before downstream prompts run.
- Keep the documentation set automation-friendly by insisting on stable heading hierarchies, numbered identifiers, and spec-kit-compatible structures before declaring success.
- Clarity, completes and predictability are paramount; avoid vague language, open-ended statements, and anything that leaves intent or ownership uncertain.

---

## Objectives 🎯

### 1. Integrity & Traceability Baseline

- Confirm that every requirement, success criterion, glossary term, checklist item, and contract guarantee has a **unique identifier** (for example `FR-014`, `SC-003`, `CHK-025`; if a feature prefix is used, keep it consistent and documented).
- Flag identifiers that are:
  - Reused for different concepts
  - Referenced without a canonical definition
- Ensure downstream documents (plan, tasks, checklists) **reference identifiers** rather than paraphrasing behaviour.
- Confirm identifier formats are consistent across documents (same prefixes, casing, and numbering style).
- If identifiers are missing, list the exact items that need identifiers and propose a consistent identifier scheme (**do not invent new requirements**).
- When recommending identifier ranges, use an em dash (—) with spaces (for example `FR-001 — FR-008`).

---

### 2. Ubiquitous Language Enforcement

- Enforce a **single, consistent, and coherent ubiquitous language** (as per the Domain-Driven Design definition) across all specification artefacts for this repository.
- Ensure that:
  - Each term has **one meaning only**
  - The same concept is **never referred to by multiple names**
  - Near-synonyms are not used interchangeably unless explicitly defined as aliases

Pay particular attention to domain terms such as:

- **[INCLUDE REPOSITORY-SPECIFIC DOMAIN TERMS COLLECTIVELY FROM ALL SPECS HERE]**

If inconsistent terminology is found:

- Call it out explicitly
- Propose a single canonical term
- Identify all files and locations that must be updated

---

### 3. Definition Ownership and De-duplication

- Ensure that **each definition or concept exists in exactly one authoritative location**.
- Definitions **must not be duplicated** across multiple documents.
- Use links to reference definitions from other documents instead.
- Ensure there is a dedicated list of terms with links to their definitions (either an existing file or a clearly proposed one).

Rules:

- A concept may be **defined once only** (for example in `spec.md` or a dedicated definitions section).
- Any other document that needs the concept **must reference it via a local Markdown link**.
- Inline redefinitions, paraphrasing, or copy-paste duplication are prohibited.

Canonical location selection (choose the most intuitive home for readers):

- **Domain terms and business concepts** belong in the feature's `spec.md` glossary or a dedicated `definitions.md`.
- **Data entities and field semantics** belong in `data-model.md`.
- **API resources and operations** belong in `contracts/` (OpenAPI, GraphQL schema, etc.).
- **Architectural patterns and technology choices** belong in the relevant ADR under `docs/adr/`.
- **Cross-cutting project conventions** belong in the constitution or `README.md`.

Do not move a definition to a location that would surprise a reader searching for it. If multiple locations seem equally valid, prefer the document that introduces the concept first in the specification workflow (`spec.md` → `data-model.md` → `contracts/` → `plan.md`).

Cross-referencing at the canonical site:

- The canonical definition **should include a "See also" or "Referenced by" note** listing the documents that depend on it (for example "Referenced by: `plan.md#phase-2`, `tasks.md#T012`").
- This bidirectional linking helps readers discover related context without duplicating the definition itself.

If duplication exists:

- Identify the **most intuitive** canonical definition location (not just the first occurrence)
- Identify all duplicated instances
- Propose replacement with Markdown links
- Add cross-references at the canonical site so readers can trace usage

---

### 4. Structural and Formatting Consistency (spec-kit Expectations)

Verify that all specification documents:

- Follow a **clear and predictable structure**
- Use consistent:
  - Heading hierarchy
  - Lists and numbering
  - Terminology and tone
  - Normative language (`must`, `must not`, `may`, `should`)
- Are suitable for **automation, task generation, and validation**
- Reference requirement identifiers whenever behaviour is restated (for example "see `FR-020`") to preserve traceability

Call out:

- Structural inconsistencies between documents
- Sections that do not belong to a given document type (for example requirements inside plans)
- Sections that should be relocated for clarity
- Formatting that makes automated processing ambiguous

---

### 5. Redundancy and Repetition Detection

Identify and report:

- Repeated explanations of the same behaviour
- Repeated background or context sections
- Multiple documents restating the same requirements
- Multiple documents covering the same concepts

For each case:

- Explain why it is redundant
- Recommend consolidation or replacement with links
- Preserve intent without expanding scope

---

### 6. Cross-Document Alignment

Ensure that:

- The **full specification set** under `/specs/*` is mutually consistent (later features may extend or supersede earlier ones, but conflicts must be explicit).
- The **plan** references the specification instead of restating behaviour.
- **Tasks** reference specification sections or identifiers where possible; if tasks do not include identifiers, require a traceability table in the review output to map tasks to requirement IDs.
- **Checklists** validate compliance rather than introducing new information.
- No document introduces behaviour not defined in the specifications.
- Documentation outside `/specs` (for example `./docs/` and `README.md`) reflects the **current implementation** while remaining consistent with all applicable earlier features (for completeness and continuity).

Explicitly verify alignment between:

- `data-model.md` policy/config fields and enums vs. any `contracts/*` or schemas
- Any `contracts/*` guarantees vs. the behaviour described in `spec.md`
- `plan.md` work items vs. requirement identifiers
- `tasks.md` vs. plan deliverables (if tasks do not cite identifiers, include a traceability table in the review output)
- Checklists vs. all other documents to confirm they validate, not define

---

### 7. Completeness of Documentation

- Ensure ADRs (decision records) exist for all material decisions and are stored under `./docs/adr/` (mandatory).
- Validate each ADR against the ADR template in `./docs/adr/ADR-nnn_Any_Decision_Record_Template.md` (structure, required fields, and status semantics).
- Ensure C4 model diagrams are present in [LikeC4](https://likec4.dev/) format and correctly reflect the current architecture (mandatory).
- Ensure data flow diagrams are present in Mermaid format when the specification, plan, or ADRs describe material data movement or external integrations; otherwise record the omission explicitly.

These documentation artefacts are required for a complete documentation set for this repository and should be located in the `/docs/` directory. ADRs and LikeC4 C4 diagrams are mandatory. If any mandatory artefact is missing, flag this explicitly. If data flow diagrams are omitted, state the justification and the source reference that allows the omission.

---

## Recommendations (Mandatory)

You must produce **actionable recommendations** to resolve every issue you identify.

Recommendations must be:

- Specific (what to change, where, and how)
- Automation-friendly (prefer deterministic identifiers and links)
- Minimal (preserve intent, avoid scope expansion)
- Ready to implement (include concrete rewrite snippets for the highest-impact items)

Where possible, provide:

- A "before" snippet (short)
- An "after" snippet (ready to paste)
- The target file and section link

---

## AI-Assisted Development Processing Expectations

- Follow the response structure exactly; do not add or omit sections.
- Provide workspace-relative Markdown links for every cited issue.
- If evidence is insufficient, state the ambiguity explicitly instead of speculating.
- Keep statements concise, precise, and high-signal.
- Always reference identifiers (for example `FR-014`, `CHK-025`) so downstream tooling can parse results deterministically.
- Use emojis in headings and key status lines to improve readability for humans (do not overuse; keep them purposeful).
- Do not repeat large blocks of source text; quote only the minimum needed to support a finding.

---

## Required Output Structure

You must respond using **only** the structure below.

### 1. Overall Assessment 🧭

- Ubiquitous language consistency: ✅ Good / ⚠️ Issues found
- Definition ownership and de-duplication: ✅ Good / ⚠️ Issues found
- spec-kit structural consistency: ✅ Good / ⚠️ Issues found

Provide a short summary paragraph.

---

### 2. Ubiquitous Language Issues 🗣️

For each issue, provide:

- Term or concept
- Conflicting names or usages
- Files and sections involved (workspace-relative Markdown links)
- Recommended canonical term
- Recommendation (what to change and where)

---

### 3. Definition Duplication and Ownership Issues 📌

For each duplicated definition, provide:

- Concept name
- Canonical location (existing or proposed)
- Files containing duplication (workspace-relative Markdown links)
- Recommended Markdown link replacement
- Recommendation (exact consolidation approach)

---

### 4. Structural or Formatting Inconsistencies 🧱

For each issue, provide:

- Issue summary
- Evidence (files/sections as workspace-relative Markdown links)
- Why it matters for spec-kit or automation
- Recommendation (specific fix)

Cover issues related to:

- Document structure
- Section placement
- Formatting or tone
- Normative language misuse

---

### 5. Redundancy and Consolidation Opportunities 🔁

For each redundancy, provide:

- Description of repeated information
- Files involved (workspace-relative Markdown links)
- Recommended consolidation or linking approach
- Recommendation (what to delete/move/link)

---

### 6. Required Actions ✅

Provide a clear, ordered list of actions required to:

- Enforce a single ubiquitous language
- Remove duplicated definitions
- Align documents with spec-kit expectations
- Close traceability gaps (missing identifiers, broken links, unreferenced requirements)

Do **not** invent new requirements or behaviour.

Each action must include:

- Priority: `high` / `medium` / `low`
- Target files (workspace-relative Markdown links)
- Outcome (what "done" looks like)

If tasks do not include requirement identifiers, include a **traceability table** in this section mapping task IDs to requirement IDs and spec references.

---

### 7. Decision Checklist (For Explicit Approval) ✅

Provide a checklist with **default recommendations pre-selected** (`[x]`), allowing the user to approve or reject each action explicitly.

For each item, include:

- The decision (checkbox)
- The affected artefacts (spec/plan/code/tests) as workspace-relative Markdown links
- A one-line justification and trade-off note

Include items as applicable, for example:

- [x] Standardise ubiquitous language terms to the proposed canonical terms
- [x] Remove duplicated definitions and replace with links to the canonical source
- [x] Add or fix missing identifiers to restore traceability (without inventing new requirements)
- [x] Relocate misfiled sections to the correct document type (spec vs plan vs tasks)
- [ ] Defer low-priority formatting consistency changes
- [ ] Take no action (documentation set is already consistent and spec-kit-ready)

---

## Rules You Must Follow

- Do not introduce new concepts or features.
- Do not change scope, clarify it.
- Do not modify implementation code.
- Prefer linking over copying.
- Be explicit and precise.
- If ambiguity exists, call it out explicitly instead of guessing.
- Provide workspace-relative Markdown links for every issue.
- When referencing schemas or code, cite definition names or paths instead of pasting large blocks.

---

## Definition of Done 🏁

This review is complete only when:

- A single ubiquitous language is identifiable across all specification files.
- Every definition has exactly one authoritative location.
- No duplicated or contradictory information remains.
- The specification set is internally consistent and spec-kit-ready.
- Traceability from specification → plan → tasks → other documentation is verifiable via explicit identifiers and links.

---

> **Version**: 1.3.1
> **Last Amended**: 2026-01-20
