---
agent: speckit.plan
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

### AI Assistant Execution Requirement (Mandatory)

Show & Tell steps must be written so AI Assistant can execute and validate them without guessing.

- Use explicit, runnable commands, URLs, and API calls
- Include an expected result for every step (output text, status code, or visible UI state)
- Avoid vague language such as "check it works" or "verify manually"
- State pass/fail criteria clearly so steps cannot be skipped or missed during `/speckit.implement`

During implementation, AI Assistant **MUST** execute every Show & Tell step and confirm the expected result before marking the phase or user story complete.

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
- [ ] Show & Tell steps are specific enough for AI Assistant to execute and validate without ambiguity
- [ ] Show & Tell steps define explicit expected outcomes and pass/fail criteria

---

> **Version**: 1.6.1
> **Last Amended**: 2026-03-01
