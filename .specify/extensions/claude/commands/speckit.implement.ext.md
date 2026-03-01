You **MUST** adhere to the following mandatory requirements when implementing features.

**Workflow context:**

- **Input:** `tasks.md` (actionable task list)
- **Output:** Working code with passing tests
- **Verification:** Execute Show & Tell steps after each phase

**Base requirements:** Follow all rules in [CLAUDE.md](/.claude/CLAUDE.md), particularly:

- Repository Tooling
- Test-Driven Development
- Quality Gates

## Implementation Process (Mandatory)

1. Work through tasks in `tasks.md` sequentially
2. Follow TDD: write failing test first, then implement, then refactor
3. After completing each phase or user story, execute its `Show & Tell` steps to verify correctness
4. Run `make lint` and `make test` after every source code change

## Implementation Completion Checklist (Mandatory)

Before marking implementation as complete, verify:

- [ ] All tasks in `tasks.md` are completed
- [ ] Each repository-template capability that was planned to be implemented using the skill at [.claude/skills/repository-template/SKILL.md](/.claude/skills/repository-template/SKILL.md) is completed
- [ ] TDD was followed: tests written before implementation
- [ ] All `Show & Tell` steps executed successfully for each phase
- [ ] Repository-template capabilities are present and up to date (see [.claude/skills/repository-template/SKILL.md](/.claude/skills/repository-template/SKILL.md))
- [ ] `make lint` and `make test` complete with zero errors and zero warnings

---

> **Version**: 1.6.0
> **Last Amended**: 2026-03-01
