# Codebase Overview Baseline 📚

Use this shared baseline for producing and maintaining architecture overview documentation for this repository.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[CBO-<prefix>-NNN]`, where the prefix maps to the containing section (for example `SCP` for Scope, `HRD` for Hard Rules, `EVD` for Evidence, `EXC` for Exclusions, `WRT` for Writing, `DSC` for Discovery, `PRM` for Prompts, `ITR` for Iteration, `NAV` for Navigation). Use these identifiers when referencing, planning, or validating requirements.

## Scope 🎯

- [CBO-SCP-001] Produce and maintain Markdown documents under `docs/architecture/`.
- [CBO-SCP-002] Treat the repository as the only authoritative source.

## Hard rules 🚫

- [CBO-HRD-001] Do not guess: if evidence is missing, write **Unknown from code – {suggested action}**.
- [CBO-HRD-002] Do not invent components, services, flows, or dependencies.
- [CBO-HRD-003] Do not rely on documentation claims unless confirmed by code or config.
- [CBO-HRD-004] Do not quote or summarise code you have not opened in the workspace.

## Evidence rules 🔍

- [CBO-EVD-001] Every major statement must include an **Evidence** bullet.
- [CBO-EVD-002] Evidence must reference a concrete artefact: file path + symbol and/or config key.
- [CBO-EVD-003] Evidence links must use an absolute repo path (prefix with `/`) so links resolve.
- [CBO-EVD-004] Prefer "composition roots" as evidence (router registration, DI wiring, consumer registration, scheduler wiring).
- [CBO-EVD-005] If you cannot find an artefact, record **Unknown from code – {what to search/confirm next}**.

## Exclusions 🚷

- [CBO-EXC-001] Exclude generated/vendor directories from analysis unless directly referenced by build tooling.
- [CBO-EXC-002] Do not treat `dist/`, `build/`, `coverage/`, `.venv/`, `node_modules/`, `vendor/` as architectural sources.
- [CBO-EXC-003] Avoid reading large files end-to-end; locate relevant sections via workspace search first.

## Writing style ✍️

- [CBO-WRT-001] Use headings and short paragraphs.
- [CBO-WRT-002] Prefer bullet lists over long prose.
- [CBO-WRT-003] Keep statements specific (names, routes, topics, schedules, config keys).
- [CBO-WRT-004] Use Mermaid diagrams, authored as fenced `mermaid` blocks, for non-C4 diagrams where they clarify interactions.
- [CBO-WRT-005] Include a **Last Amended** footer in every file you produce, using this format:

```plaintext
---

> **Last Amended**: YYYY-MM-DD
```

## Working method 🔄

### Start of any pass (discovery sweep)

- [CBO-DSC-001] List top-level directories (e.g. `ls`) and identify likely source roots.
- [CBO-DSC-002] Identify language/tooling indicators (`Makefile`, `pyproject.toml`, `package.json`, `go.mod`, etc.).
- [CBO-DSC-003] Identify CI/deploy indicators (`.github/workflows/`, `Dockerfile`, Helm, Kubernetes, Terraform).
- [CBO-DSC-004] Record any new findings in `docs/architecture/repository-map.md` (even if partial).

### Prompt execution order

- [CBO-PRM-001] Run prompts in this order.
- [CBO-PRM-002] [architecture.01-repository-map](../../prompts/architecture.01-repository-map.prompt.md)
- [CBO-PRM-003] [architecture.02-component-catalogue](../../prompts/architecture.02-component-catalogue.prompt.md)
- [CBO-PRM-004] [architecture.03-runtime-flows](../../prompts/architecture.03-runtime-flows.prompt.md)
- [CBO-PRM-005] [architecture.04-domain-analysis](../../prompts/architecture.04-domain-analysis.prompt.md)
- [CBO-PRM-006] [architecture.05-c4-model](../../prompts/architecture.05-c4-model.prompt.md)

### Iteration rules

- [CBO-ITR-001] Update existing documents; do not restart from scratch.
- [CBO-ITR-002] Replace vague statements with evidenced specifics on each iteration.
- [CBO-ITR-003] Convert "Unknown from code" items into evidenced statements when you find proof.

## Indexing and navigation 🗂️

- [CBO-NAV-001] Treat `docs/architecture/README.md` as the canonical landing page.
- [CBO-NAV-002] Link every `component-*.md`, `runtime-flow-*.md` and `domain-*` document from the README.
- [CBO-NAV-003] Maintain an **Unknowns / to verify** section in the README for follow-up work.

---

> **Version**: 1.3.2
> **Last Amended**: 2026-01-17
