---
applyTo: "**/*.{likec4,c4}"
---

# LikeC4 DSL Instructions (architecture-as-code diagrams) 📐

These instructions define the engineering approach for authoring **LikeC4 architecture-as-code** files.

They must remain applicable to:

- C4 model definitions (system context, container, component diagrams)
- Specification blocks (element kinds, relationship kinds, styles)
- View definitions and layout
- Multi-file workspace models

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Cross-references.** For architecture documentation standards, see [architecture-baseline.include.md](./includes/architecture-baseline.include.md). For the C4 model generation prompt, see [architecture.05-c4-model.prompt.md](../prompts/architecture.05-c4-model.prompt.md). This file focuses exclusively on LikeC4 DSL patterns and validation.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[LC4-<prefix>-NNN]`, where the prefix maps to the containing section (for example `QR` for Quick Reference, `OP` for Operating Principles, `SYN` for Syntax, `VAL` for Validation, `STY` for Style). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [LC4-QR-001] **Element syntax**: use `identifier = kind 'Title'` — identifier first, then `=`, then kind.
- [LC4-QR-002] **Never mix forms**: `kind identifier = 'Title'` is INVALID and silently drops the element.
- [LC4-QR-003] **Validate after generation**: use LikeC4 MCP tools to confirm all elements parsed correctly.
- [LC4-QR-004] **Specification first**: declare every element kind in `specification {}` before using it in `model {}`.

---

## 1. Operating principles 🧭

These principles extend [constitution.md §3](../../.specify/memory/constitution.md#3-core-principles-non-negotiable).

- [LC4-OP-001] Treat the **specification as the source of truth** for the architecture model. If a system, container, or component is not evidenced in the codebase, it does not belong in the diagram.
- [LC4-OP-002] Prefer **small, incremental updates** over full model rewrites.
- [LC4-OP-003] Design for **determinism**: the same model source must produce the same diagrams.
- [LC4-OP-004] **Validate every change** using LikeC4 MCP tools — the tooling fails silently on syntax errors.

---

## 2. Element declaration syntax 🧩

LikeC4 supports two forms for declaring elements. Mixing them causes silent parse failures.

### Valid forms

```likec4
// Form A — identifier-first with = (PREFERRED)
customer = actor 'Customer' {
  description 'End user of the system'
}

// Form B — kind-first WITHOUT = (alternative)
actor customer 'Customer' {
  description 'End user of the system'
}
```

### Invalid form (common mistake)

```likec4
// WRONG — kind-first WITH = sign
// This silently fails: the element is dropped without error
actor customer = 'Customer' {
  description 'End user of the system'
}
```

- [LC4-SYN-001] Prefer Form A (`identifier = kind 'Title'`) for consistency.
- [LC4-SYN-002] Never combine kind-first ordering with the `=` sign.
- [LC4-SYN-003] Apply the same rule to nested elements (containers, components) — the syntax is identical at every nesting level.

---

## 3. Specification block 📋

- [LC4-SYN-010] Declare all element kinds in `specification {}` before referencing them in `model {}`.
- [LC4-SYN-011] Declare custom styles (e.g. `shape person` for actors) inside the kind's `style {}` block within the specification.

```likec4
specification {
  element actor {
    style {
      shape person
    }
  }
  element system
  element container
  element component
}
```

---

## 4. Views 🖼️

- [LC4-SYN-020] Use `view name { include * }` for top-level views showing all elements.
- [LC4-SYN-021] Use `view name of element { include * }` to scope a view to a specific element's children.
- [LC4-SYN-022] List included elements as comma-separated values: `include a, b, c`.

```likec4
views {
  view index {
    title 'System Context'
    include *
  }

  view containers of mySystem {
    title 'Container Diagram'
    include *, externalUser, externalDep
  }
}
```

---

## 5. Relationships 🔗

- [LC4-SYN-030] Use `source -> target 'label'` for relationships.
- [LC4-SYN-031] Inside an element body, use `-> target 'label'` (implicit source is the enclosing element).
- [LC4-SYN-032] Use fully qualified names for cross-boundary references: `system.container.component`.

---

## 6. Validation ✅

LikeC4 fails silently on syntax errors — invalid elements are dropped without diagnostics.

- [LC4-VAL-001] After generating or editing a `.likec4` file, use `mcp_likec4_read-project-summary` to verify the element count matches expectations.
- [LC4-VAL-002] Use `mcp_likec4_read-view` to confirm each view contains the expected nodes and edges.
- [LC4-VAL-003] If the element count is lower than expected, check for the invalid `kind identifier = 'Title'` pattern first — it is the most common cause.

---

## 7. File conventions 📁

- [LC4-STY-001] Use the `.likec4` extension for LikeC4 source files (`.c4` also works but `.likec4` is unambiguous).
- [LC4-STY-002] Place architecture diagrams under `docs/architecture/`.
- [LC4-STY-003] Use a single `workspace.likec4` file for small projects; split into multiple files for larger models.
- [LC4-STY-004] Add a comment header with inputs and evidence pointers at the top of each file.

---

> **Version**: 1.0.0
> **Last Amended**: 2026-04-27
