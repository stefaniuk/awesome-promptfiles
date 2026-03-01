# AI Assistant Instructions ✨

## Communication style guide

- Use British English
- Keep language simple

## Non-negotiable rules

- Read and adhere to the [constitution](/.specify/memory/constitution.md) at all times

## Documentation ADRs

When making architectural or significant technical decisions, document them as Architecture Decision Records (ADRs):

**What requires an ADR:**

- Architectural style choices (e.g. event-driven vs layered, monolith vs microservices)
- Architectural pattern choices (e.g. composition over inheritance, repository pattern, event sourcing)
- Language and framework selections
- Any other significant technical decision that shapes the system

**ADR requirements:**

- Only consult the ADR template when creating or updating an ADR; do not read it otherwise
- Use the template when an ADR is required
- Follow the existing ADR format for consistency
- Always present 3 or more options with trade-offs
- Include the conversational context that led to the decision
- Document decisions regardless of whether you made them independently or were guided by the user

This requirement is mandatory, especially during the spec-driven development cycle: `spec` → `plan` → `tasks` → `implement`.

## Toolchain version

- Use the latest stable language, runtime, and framework versions at the time of change, search the internet for the latest versions

## Test-driven development

- Define tasks using a strict TDD approach
- For each specified functionality, sequence tasks as Red (write failing test first), Green (implement to pass), then Refactor (improve code without changing behavior)
- Ensure tests are always listed before implementation tasks

## Repository tooling

- When you identify missing development capabilities (linting, CI/CD, Docker support, pre-commit hooks, etc.), consult the [repository-template skill](/.claude/skills/repository-template/SKILL.md) for standardised implementations.

## Quality gates

After any source code change:

1. Run `make lint` and `make test`
2. Fix all errors and warnings — including those in files you not modified
3. Repeat until both commands complete with zero errors and zero warnings
4. Do this automatically without prompting

---

> **Version**: 1.5.4
> **Last Amended**: 2026-03-01
