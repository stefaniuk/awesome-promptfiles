---
agent: agent
description: Produce C4 model diagrams (Context, Container, Component) in LikeC4 format (https://likec4.dev/, evidence-first, consistent naming)
---

**Mandatory preparation:** read [architecture overview](../instructions/includes/architecture-baseline.include.md) and [LikeC4 DSL](../instructions/likec4.instructions.md) instructions in full and follow strictly their rules before executing any step below.

## Goal 🎯

Create (or update) LikeC4 source files under `docs/architecture/`:

- `docs/architecture/c4-01-context.c4`
- `docs/architecture/c4-02-container.c4`
- `docs/architecture/c4-03-component-*.c4` (one per container/context as needed)

Also ensure they are linked from: [architecture overview](../../docs/architecture/README.md) output

---

## Discovery (run before writing) 🔍

### A. Refresh what is already known (use existing docs as inputs)

1. Review:
   - [repository map](../../docs/architecture/repository-map.md)
   - Component catalogue: `docs/architecture/component-*.md`
   - Runtime flows: `docs/architecture/runtime-flow-*.md`
   - Domain analysis (DDD): `docs/architecture/domain-*.md`
2. Extract into working notes:
   - System name(s) and purpose
   - Deployable units (services/apps/workers/CLIs) and their entry points
   - External systems (identity, messaging, email, payments, third-party APIs)
   - Datastores (DBs, caches, object stores) and which parts use them
   - Bounded contexts / major domain areas (if documented)
   - Primary protocols and interaction styles (HTTP, events, schedules) if evidenced

### B. Confirm diagram candidates in code/config (evidence-first)

Use workspace search and open relevant files to confirm:

1. Container boundaries:
   - Dockerfiles, Helm/K8s manifests, Terraform resources, compose files
   - Service start-up and deployment workflows
2. External systems and dependencies:
   - Client initialisation, env vars, config structs, IaC resources
3. Component boundaries (for at least one container, ideally more):
   - Router registrations / controllers
   - Consumer registrations
   - DI wiring / registries / module composition roots

Record any gaps as **Unknown from code – {suggested action}** and avoid guessing.

---

## Steps 👣

### 1) Establish naming and scope (consistency rules)

1. Use the same component/container names as in:
   - `component-*.md`
   - `runtime-flow-*.md`
2. Prefer stable identifiers:
   - Containers: `{system}-{service}` style or existing service names
   - Components: short names that match code modules where possible
3. Keep the model small and readable:
   - Context: 1 system + people + external systems
   - Container: 5–20 containers (group similar ones if needed)
   - Component: per-container, focus on 10–30 key components (not every class)

---

### 2) Create Context diagram (LikeC4)

Create/update: `docs/architecture/c4-01-context.c4`

Include:

- One LikeC4 top-level **system** representing the codebase/system
- Key LikeC4 **actor** elements (user types) if evidenced by API/UI usage
- Key **external systems** the system integrates with
- High-level relationships (who uses what)

Rules:

- Only include externals that have evidence in code/config/IaC.
- Use LikeC4 element kinds and styles consistently so the model remains readable and reviewable.
- Add brief descriptions (one sentence max).
- Where meaningful and evidenced, annotate relationships with the interaction style (e.g. `HTTPS/443`, `Publishes events`, `Reads/writes`).

---

### 3) Create Container diagram (LikeC4)

Create/update: `docs/architecture/c4-02-container.c4`

Include containers for each deployable unit:

- Web/API services
- Background workers/consumers
- Scheduled jobs (if separate deployables)
- CLI tools (only if operationally significant)

Also include key datastores and infrastructure dependencies as containers where helpful:

- Databases
- Message brokers / queues
- Caches
- Object storage

Rules:

- Each container must have evidence (Docker/K8s/IaC, entry point, or build pipeline).
- Capture main technology where evidenced (runtime/framework).
- Relationships must be meaningful (API calls, publishes/consumes, reads/writes).
- Prefer a small number of relationships; do not include every internal call.

---

### 4) Create Component diagrams (LikeC4)

Create component diagrams for containers where it adds value:

- Prioritise the most business-critical containers and/or those appearing in many runtime flows.

For each chosen container, create/update:

- `docs/architecture/c4-03-component-{container-name}.c4`

Include:

- Key components (controllers/handlers, application services, domain services, repositories, message handlers)
- Key relationships between components
- Relationships from components to external dependencies (DB, broker, external API) where meaningful

Rules:

- Components must be grounded in code:
  - router/controller registrations
  - handler registries
  - DI wiring / module composition
  - repository implementations
- Avoid mapping every class; aim for the main collaborating parts.
- If you cannot identify components reliably, record **Unknown from code – {suggested action}** and skip the component diagram for that container.

---

### 5) Add evidence references and unknowns

LikeC4 source files are not ideal for line-level evidence. Do this instead:

1. At the top of each `.c4` file, include a short comment block:
   - What inputs were used (links to repo map/components/flows)
   - A short "Evidence pointers" list (file paths only)
   - "Unknown from code" items, if any

Example comment:

```text
// Inputs:
// - /docs/architecture/repository-map.md
// - /docs/architecture/component-001-*.md
// Evidence pointers:
// - /path/to/router.ts
// - /infra/k8s/service.yaml
// Unknown from code – confirm whether {X} is a separate deployable
```

---

### 6) Update the index (README)

Update: [architecture overview](../../docs/architecture/README.md) with a **C4 Diagrams (LikeC4)** section linking to:

- `c4-01-context.c4`
- `c4-02-container.c4`
- `c4-03-component-*.c4`

Also include brief "How to view" notes (repo-local, no external claims), for example:

- "Open the `.c4` source in LikeC4-compatible tooling used by this repo (if present)."
- If no tooling is found, record **Unknown from code – identify how diagrams are rendered in this repo**.

---

## Output requirements

- Keep diagrams readable and consistent.
- Use the [LikeC4](https://likec4.dev/) format for every C4 diagram.
- Use the evidence-first approach; do not invent externals, containers, or components.
- When unsure, record **Unknown from code – {suggested action}** rather than guessing.

---

## LikeC4 pitfalls and validation ⚠️

These rules are derived from real debugging sessions. Follow them to avoid silent failures.

### Element declaration syntax

LikeC4 supports two declaration forms — **never mix them**:

| Form                         | Syntax                              | Valid? |
| ---------------------------- | ----------------------------------- | ------ |
| Identifier-first (preferred) | `identifier = kind 'Title' { ... }` | ✅     |
| Kind-first (alternative)     | `kind identifier 'Title' { ... }`   | ✅     |
| **Mixed (common mistake)**   | `kind identifier = 'Title' { ... }` | ❌     |

The mixed form silently drops the element — no error, no warning. The diagram renders with missing nodes.

### Post-generation validation (mandatory)

After creating or editing any `.likec4` file:

1. Call `mcp_likec4_read-project-summary` and count the elements returned.
2. Compare against the expected count from your model.
3. If elements are missing, search for the invalid `kind identifier = 'Title'` pattern.
4. Call `mcp_likec4_read-view` for each view to confirm nodes and edges.

---

## LikeC4 skeletons (use as starting points)

### Context skeleton

```c4
specification {
  element actor
  element system
  element external
}

model {
  user = actor 'User' {
    description 'Primary user type.'
  }

  platform = system 'System' {
    description 'Short description.'
  }

  dependency = external 'External System' {
    description 'Short description.'
  }

  user -> platform 'Uses'
  platform -> dependency 'Integrates with'
}

views {
  view index {
    title 'System Context'
    include *
  }
}
```

### Container skeleton

```c4
specification {
  element actor
  element system
  element container
  element datastore
}

model {
  user = actor 'User'

  platform = system 'System' {
    api = container 'API Service' {
      description 'Serves the HTTP API.'
    }

    worker = container 'Worker' {
      description 'Processes background work.'
    }

    db = datastore 'Database' {
      description 'Stores data.'
    }

    api -> db 'Reads and writes'
    api -> worker 'Publishes jobs or events'
  }

  user -> platform.api 'Uses'
}

views {
  view index {
    title 'System Context'
    include user platform
  }

  view of platform {
    title 'Container View'
    include *
  }
}
```

### Component skeleton

```c4
specification {
  element system
  element container
  element component
  element datastore
}

model {
  platform = system 'System' {
    api = container 'API Service' {
      controller = component 'Controller' {
        description 'Handles HTTP requests.'
      }

      service = component 'Application Service' {
        description 'Orchestrates use cases.'
      }

      repo = component 'Repository' {
        description 'Persists data.'
      }

      controller -> service 'Calls'
      service -> repo 'Uses'
    }

    db = datastore 'Database' {
      description 'Stores data.'
    }
  }

  platform.api.repo -> platform.db 'Reads and writes'
}

views {
  view of platform.api {
    title 'Component View - API Service'
    include *
  }
}
```

---

> **Version**: 1.2.0
> **Last Amended**: 2026-04-27
