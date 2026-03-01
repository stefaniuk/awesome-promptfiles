---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs: 
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
---

You **MUST** adhere to the following mandatory requirements when creating a development plan.

**Workflow context:**

- **Input:** `spec.md` (feature specification)
- **Output:** `plan.md` (implementation plan)
- **Next phase:** Tasks generation (`/speckit.tasks`)

**Base requirements:** Follow all rules in [copilot-instructions.md](/.github/copilot-instructions.md), particularly:

- Documentation ADRs
- Toolchain Version
- Repository Tooling

## Show & Tell Sections (Mandatory)

Each phase and user story in `plan.md` must include a `Show & Tell` subsection. This subsection defines the demonstration steps that will be:

1. Expanded with specific commands in `tasks.md` (next phase)
2. Executed by the user during implementation to verify completion

### GitHub Copilot Execution Requirement (Mandatory)

Show & Tell steps must be written so GitHub Copilot can execute and validate them without guessing.

- Use explicit, runnable commands, URLs, and API calls
- Include an expected result for every step (output text, status code, or visible UI state)
- Avoid vague language such as "check it works" or "verify manually"
- State pass/fail criteria clearly so steps cannot be skipped or missed during `/speckit.implement`

During implementation, GitHub Copilot **MUST** execute every Show & Tell step and confirm the expected result before marking the phase or user story complete.

## Plan Completion Checklist (Mandatory)

Before marking `plan.md` as complete, verify:

- [ ] Plan addresses all requirements from `spec.md`
- [ ] All architectural decisions have corresponding ADRs
- [ ] Toolchain versions are specified, verified online during planning, and confirmed as the latest stable releases
- [ ] Repository-template capabilities are planned using the skill at [.github/skills/repository-template/SKILL.md](/.github/skills/repository-template/SKILL.md), including at minimum:
  - [ ] Core Make System
  - [ ] Pre-commit Hooks
  - [ ] Secret Scanning
  - [ ] File Format Checking
  - [ ] Markdown Linting
  - [ ] Docker Support
  - [ ] Tool Version Management
- [ ] Each phase and user story includes a `Show & Tell` subsection
- [ ] Show & Tell subsections are placed at the end of each phase or user story
- [ ] Show & Tell steps are specific enough for GitHub Copilot to execute and validate without ambiguity
- [ ] Show & Tell steps define explicit expected outcomes and pass/fail criteria

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Define interface contracts** (if project has external interfaces) → `/contracts/`:
   - Identify what interfaces the project exposes to users or other systems
   - Document the contract format appropriate for the project type
   - Examples: public APIs for libraries, command schemas for CLI tools, endpoints for web services, grammars for parsers, UI contracts for applications
   - Skip if project is purely internal (build scripts, one-off tools, etc.)

3. **Agent context update**:
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications

---

> **Version**: 1.6.0
> **Last Amended**: 2026-03-01
