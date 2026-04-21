---
applyTo: "**/*.tf"
---

# Terraform Engineering Instructions (AWS) ☁️

These instructions define the default engineering approach for building and evolving **AWS infrastructure** using **Terraform** (Infrastructure as Code).

They must remain applicable to:

- Terraform configuration (`.tf`), variables, and modules
- Backend/state, environments, and release workflows
- Security, networking, identity, logging, and compliance controls
- Operational readiness (monitoring, alerting, runbooks)
- Documentation and diagrams for infrastructure and operations

They are **non-negotiable** unless an exception is explicitly documented (with rationale and expiry) in an ADR/decision record.

**Identifier scheme.** Every normative rule carries a unique tag in the form `[TF-<prefix>-NNN]`, where the prefix maps to the containing section (for example `OP` for Operating Principles, `LCL` for Local-first developer experience, `QG` for Quality Gates, continuing through `AI` for AI-assisted expectations). Use these identifiers when referencing, planning, or validating requirements.

---

## 0. Quick reference (apply first) 🧠

This section exists so humans and AI assistants can reliably apply the most important rules even when context is tight.

- [TF-QR-001] **Specification first**: if a requirement is not specified (or agreed), do not invent it ([TF-OP-005]).
- [TF-QR-002] **Small, safe changes**: prefer incremental evolution over big rewrites ([TF-OP-003]).
- [TF-QR-003] **Deterministic and reproducible**: the same inputs must produce the same plan ([TF-OP-002], [TF-OP-008]–[TF-OP-009]).
- [TF-QR-004] **Run the quality gates** after any Terraform change and iterate to clean ([TF-QG-001]–[TF-QG-008]).
- [TF-QR-005] **Plan-first discipline**: all changes must be reviewed via `terraform plan` output ([TF-BEH-001]–[TF-BEH-003]).
- [TF-QR-006] **London-only residency**: all infrastructure must be in `eu-west-2`; no other region without an ADR ([TF-REG-001]–[TF-REG-002]).
- [TF-QR-007] **Secure-by-default**: least privilege, encryption, auditable changes ([TF-OP-004], [TF-SEC-001]–[TF-SEC-026]).
- [TF-QR-008] **No snowflakes**: no manual changes in the AWS Console that are not represented in Terraform ([TF-OP-006]).
- [TF-QR-009] **Remote state, isolated per environment**: encrypted, versioned, access-controlled ([TF-STATE-001]–[TF-STATE-008]).
- [TF-QR-010] **Observability baseline**: CloudWatch logs, metrics, alarms, dashboards, and runbook references ([TF-OBS-001]–[TF-OBS-067]).
- [TF-QR-011] **IaC or nothing**: every AWS change must flow through Terraform under version control ([TF-OP-007]).
- [TF-QR-012] **Avoid common anti-patterns**: hardcoded ARNs, floating versions, mega-modules, secrets in `.tfvars` (§20).

---

## 1. Operating principles 🧭

These principles extend [constitution.md §3](../../.specify/memory/constitution.md#3-core-principles-non-negotiable).

- [TF-OP-001] **Infrastructure is a product**: it must be reliable, testable, reviewable, and operable.
- [TF-OP-002] **Deterministic and reproducible**: the same inputs must produce the same plan and the same result.
- [TF-OP-003] **Small, safe changes**: prefer incremental evolution over big rewrites.
- [TF-OP-004] **Secure-by-default**: least privilege, encryption, auditable changes, and safe failure semantics.
- [TF-OP-005] **Specification-first where it exists**: if a requirement is not specified (or agreed), do not invent it.
- [TF-OP-006] **No snowflakes**: no manual changes in the AWS Console that are not represented in Terraform (except break-glass with a follow-up fix).
- [TF-OP-007] Keep all Terraform configuration under version control with code review; no unmanaged state or local-only configuration files.

Determinism notes (how to avoid accidental drift):

- [TF-OP-008] Prefer **pinned and versioned inputs** over lookups that can change:
  - avoid "latest" AMI lookups unless explicitly required and justified
  - prefer versioned artefacts (AMI IDs, container tags/digests, module versions)
- [TF-OP-009] Treat non-deterministic resources/providers (for example `random_*`) as part of the contract:
  - scope them carefully
  - document where they are used and why

---

## 2. Local-first developer experience (bleeding-edge fast feedback) ⚡

Terraform changes must be **fully developable, reviewable, and testable locally**, even when the target environment is controlled via CI/CD.

Follow the shared [local-first developer experience baseline](./includes/local-first-dev-baseline.include.md) for common expectations, plus the Terraform-specific requirements below.

### 2.1 Single-command workflow (must exist)

Provide repository-standard commands so an engineer can do the following quickly:

- [TF-LCL-001] Bootstrap tooling: `make deps` (or equivalent) — installs/validates Terraform and companion tooling.
- [TF-LCL-002] Format: `make format` (must run `terraform fmt -recursive`).
- [TF-LCL-003] Validate: `make validate` (must run `terraform validate` with the correct module/stack context).
- [TF-LCL-004] Plan: `make plan` (must run `terraform plan` against the correct environment inputs).
- [TF-LCL-005] Lint/scan: `make lint` (must include linting and security scanning per §15).
- [TF-LCL-006] Full local suite: `make test` / `make test-all` (where the repo adopts `terraform test` or module contract tests per §18).

### 2.2 Reproducible toolchain (avoid "works on my machine")

- [TF-LCL-007] Pin Terraform with a clear constraint (see §8.1) and provide a predictable install method.
- [TF-LCL-008] Pin provider versions (see §8.1) and avoid floating versions.
- [TF-LCL-009] Commit and maintain `.terraform.lock.hcl` so provider selection is deterministic across machines and CI.
- [TF-LCL-010] Ensure local commands use the same backend/configuration model as CI (without requiring privileged credentials by default).
- [TF-LCL-011] Keep the local toolchain minimal, fast, and consistent across engineers and CI:
  - Terraform CLI
  - a linter (for example `tflint`)
  - a security/policy scanner (for example Trivy/Checkov/tfsec/OPA/Sentinel as adopted)

### 2.3 Pre-commit hooks (strongly recommended)

Provide a `pre-commit` configuration that runs the same checks as CI in a fast, local-friendly way:

- [TF-LCL-012] formatting (`terraform fmt`)
- [TF-LCL-013] linting (`tflint` or repo-approved equivalent)
- [TF-LCL-014] security scanning (fast lane; heavy scans belong in CI)
- [TF-LCL-015] secret scanning (for example `gitleaks`)

### 2.4 OCI images for parity and zero-setup (strongly recommended)

Provide an OCI-based option so behaviour is consistent across laptops and CI. If the repo uses Dev Containers or OCI images:

- [TF-LCL-016] Provide an optional, maintained containerised dev environment so Terraform and companion tools run consistently across laptops and CI.
- [TF-LCL-017] Never bake credentials or secrets into images.
- [TF-LCL-018] The same commands (`make fmt`, `make validate`, `make plan`, `make lint`) must work inside and outside the container.

---

## 3. Mandatory local quality gates (constitution §7.8) ✅

Per [constitution.md §7.8](../../.specify/memory/constitution.md#78-mandatory-local-quality-gates), after making **any** Terraform change, run the repository's **canonical** quality gates:

1. Prefer:
   - [TF-QG-001] `terraform fmt -recursive`
   - [TF-QG-002] `terraform validate`
   - [TF-QG-003] `terraform plan` (against the correct environment inputs)
   - [TF-QG-004] Lint and security scanning (see §15)

2. If the repository provides `make` targets, prefer:
   - [TF-QG-005] `make lint`
   - [TF-QG-006] `make test`

   - [TF-QG-007] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for iteration and warning handling rules.
   - [TF-QG-008] Follow the shared [quality gates baseline](./includes/quality-gates-baseline.include.md) for command selection and equivalents.

---

## 4. Contracts and public surface area 📜

Terraform is an interface contract just like an API/CLI: callers depend on it.

### 4.1 Module and stack contracts (stable interfaces)

- [TF-CTR-001] Treat module interfaces as contracts:
  - [TF-CTR-001a] input variables (names, types, defaults, validation)
  - [TF-CTR-001b] outputs (names, types, sensitivity, stability)
  - [TF-CTR-001c] documented behaviours and invariants (for example encryption always on, private by default)
- [TF-CTR-002] Breaking changes must be intentional, documented, and reviewable.
- [TF-CTR-003] Prefer additive evolution (new optional variables/outputs) over breaking changes.
- [TF-CTR-004] Mark sensitive outputs as `sensitive = true` and avoid exposing secrets via outputs.
- [TF-CTR-005] Use `output` blocks to publish the minimum integration data consumers need, keeping structured names and descriptions aligned with the specification.
- [TF-CTR-006] Avoid surfacing sensitive values via outputs; when an output must exist for operational reasons, mark it `sensitive` and document the consumer and rotation policy.

### 4.2 Environment contracts and safety boundaries

- [TF-CTR-007] Environment boundaries must be explicit and repeatable (see §9 and §7):
  - one state per environment
  - explicit credentials and account targeting
  - explicit region controls
- [TF-CTR-008] The "apply path" must be clear and auditable (see §5.2):
  - who/what applies
  - where plans live
  - what approvals are required

### 4.3 Documentation as part of the contract

- [TF-CTR-009] Every stack/module must have enough documentation for a new engineer to:
  - understand what it provisions and why
  - know how to run plan safely
  - know how to recover/roll back (where applicable)

---

## 5. Behaviour rules 🚦

### 5.1 Plan-first discipline (non-negotiable)

- [TF-BEH-001] All changes must be reviewed via **`terraform plan`** output.
- [TF-BEH-002] Plans must be generated against the correct environment variables and backend.
- [TF-BEH-003] Avoid "unknown drift" by keeping inputs explicit and versioned.

### 5.2 Apply strategy (controlled delivery)

- [TF-BEH-004] Prefer applies via CI/CD with controlled credentials and audit trails.
- [TF-BEH-005] Do not run `terraform apply` locally for production unless explicitly authorised.
- [TF-BEH-006] Use approvals for production applies (two-person rule where appropriate).

### 5.3 Rollback and irreversibility

- [TF-BEH-007] Prefer changes that are reversible.
- [TF-BEH-008] Where changes are not reversible (or are destructive), document:
  - [TF-BEH-008a] the irreversible step
  - [TF-BEH-008b] the mitigation
  - [TF-BEH-008c] the recovery plan
- [TF-BEH-009] Use `lifecycle` controls (like `prevent_destroy`) for critical resources when appropriate and documented.

### 5.4 Drift and configuration hygiene

- [TF-BEH-010] Drift must be detected and treated as a defect.
- [TF-BEH-011] Regularly run plan against environments (or use a drift detector) and address drift promptly.
- [TF-BEH-012] Avoid "hand edits" in the console; if they happen, they must be reconciled back into Terraform.

---

## 6. Configuration and precedence ⚙️

### 6.1 Precedence order (must be explicit)

Define and document how configuration is provided, and apply it consistently.

- [TF-CFG-001] Prefer an explicit precedence order (document in the repo). A typical order is:
  1. CLI `-var` / `-var-file`
  2. environment-specific `.tfvars` / environment folder inputs
  3. default variable values in code
- [TF-CFG-002] Keep environment inputs versioned, reviewable, and discoverable (for example under `environments/` or `stacks/`).

### 6.2 Variable validation

- [TF-CFG-003] Use variable validation (`validation {}` blocks) for critical invariants (region, naming, required tags, CIDR boundaries).
- [TF-CFG-004] Avoid hidden dependency on shell environment defaults (especially region/account selection).
- [TF-CFG-005] Treat "configuration by convention" as a risk unless documented and tested.
- [TF-CFG-006] Prefer explicit typing for variables (including `object(...)` shapes for structured inputs) and avoid untyped "anything" variables unless justified.

### 6.3 Variable and data discipline

- [TF-CFG-007] Avoid hard-coded values; expose configuration via variables with sensible defaults (and descriptions) so environments stay consistent.
- [TF-CFG-008] Document every variable and output with `description` and `type` so intent is discoverable and tooling-friendly.
- [TF-CFG-009] Use data sources to look up pre-existing infrastructure instead of duplicating configuration; avoid data sources for resources defined in the same stack (pass outputs instead).
- [TF-CFG-010] Remove unused or redundant data sources—they slow plans/applies and mask real dependencies.
- [TF-CFG-011] Use `locals {}` for repeated derived values to keep naming consistent and avoid divergent literals.

---

## 7. Region and residency (London-only) 🇬🇧

Data residency is a compliance requirement. All AWS infrastructure in this repository **must** be provisioned in:

- [TF-REG-001] **`eu-west-2` (London)**
- [TF-REG-002] No other AWS region may be used unless an explicit exception is recorded in an ADR (rationale + expiry), including the data residency and operational impact assessment.

### 7.1 Terraform enforcement (mandatory)

- [TF-REG-003] Pin the AWS provider region explicitly and consistently:
  - do **not** rely on environment defaults
  - do **not** allow per-module "region drift" via optional region inputs
- [TF-REG-004] All modules must either:
  - inherit the root provider configuration, **or**
  - accept a `region` input that is **hard-validated** to `eu-west-2` (fail fast if not)

### 7.2 Guardrails (must adopt)

- [TF-REG-005] Treat "multi-region by accident" as a defect: any PR that introduces another region is invalid.
- [TF-REG-006] If policy-as-code is used (recommended), add a rule that fails CI when:
  - `provider "aws" { region = ... }` is not `eu-west-2`
  - aliased providers introduce non-`eu-west-2` regions
  - resources/data sources explicitly target other regions

### 7.3 Global AWS services (special case)

Some AWS services are **global** (for example IAM) or have global control planes (for example CloudFront / Route 53).

Rules:

- [TF-REG-007] Prefer regional alternatives where they exist.
- [TF-REG-008] When a global service is required:
  - document the rationale and scope in `docs/` (and an ADR if it materially affects risk/compliance)
  - still keep **regional resources and data** in `eu-west-2`
  - be explicit about where logs, keys, and data are stored

---

## 8. Versioning and dependency discipline 📦

Dependencies must be explicit and versioned. No floating versions.

### 8.1 Terraform and provider versions

- [TF-VER-001] Pin **Terraform** with a clear constraint (for example `required_version = "~> 1.6"`).
- [TF-VER-002] Pin **providers** with explicit constraints.
- [TF-VER-003] Run `terraform init -upgrade` deliberately and review provider changes.
- [TF-VER-004] Do not rely on floating versions.
- [TF-VER-005] Regularly refresh pinned Terraform and provider versions to the latest stable release, capturing security patches and recording any blockers when you cannot upgrade immediately.

### 8.2 Modules

- [TF-VER-006] Treat modules as **versioned products**.
- [TF-VER-007] Prefer small, single-responsibility modules with clear inputs/outputs.
- [TF-VER-008] Avoid "mega-modules" that provision unrelated concerns.
- [TF-VER-009] Do not fork upstream modules unless necessary; if you do, record the reason and a review date in an ADR.
- [TF-VER-010] Avoid wrapping single resources in modules unless they add shared policy, tagging, or abstractions; prefer direct resources for trivial cases.
- [TF-VER-011] Keep module hierarchies shallow and avoid unnecessary nesting that obscures the apply graph.
- [TF-VER-012] Prevent circular module dependencies; treat them as architecture defects that require refactoring.

---

## 9. State, backends, and environment isolation 🧱

### 9.1 Remote state (mandatory)

- [TF-STATE-001] Use a remote backend (commonly **S3** for state + **DynamoDB** for state locking).
- [TF-STATE-002] State buckets must be:
  - [TF-STATE-002a] encrypted (SSE-KMS preferred)
  - [TF-STATE-002b] versioned
  - [TF-STATE-002c] access-controlled with least privilege
  - [TF-STATE-002d] protected from accidental deletion (for example bucket policies, retention, and account controls)

### 9.2 One state per environment

- [TF-STATE-003] Each environment must have isolated state (dev/test/stage/prod, or equivalent).
- [TF-STATE-004] Prefer separate state files (and separate AWS accounts) over Terraform workspaces for real environment isolation.
- [TF-STATE-005] Do not share state across unrelated stacks.

### 9.3 State safety rules

- [TF-STATE-006] Never edit state manually unless it is a break-glass incident.
- [TF-STATE-007] If break-glass is needed:
  - [TF-STATE-007a] document what happened
  - [TF-STATE-007b] restore Terraform as the source of truth immediately after
  - [TF-STATE-007c] record the incident and preventative controls

State safety notes:

- [TF-STATE-008] Treat state access as production access:
  - restrict who/what can read state
  - prefer write access only for CI/CD roles
  - ensure state bucket access is monitored and auditable

---

## 10. Structure and organisation (readability and maintainability) 🗂️

Adopt a predictable layout. For example:

- `modules/` — reusable modules
- `environments/` (or `stacks/`) — per-environment compositions
- `policies/` — policy-as-code (if used)
- `docs/` — diagrams, runbooks, decisions, and operational notes

Rules:

- [TF-STR-001] Keep **environment composition** separate from **module implementation**.
- [TF-STR-002] Avoid deep nesting that makes navigation hard.
- [TF-STR-003] Keep each stack small enough to review confidently (split by domain/boundary when needed).
- [TF-STR-004] Split large estates into separate stacks/projects per major component so plans remain fast, isolated, and reviewable.
- [TF-STR-005] Group related resources in files with predictable names (for example `providers.tf`, `network.tf`, `ecs.tf`) so discovery is consistent across stacks.
- [TF-STR-006] Co-locate tests, variables, and helper modules near the stacks they protect when it improves comprehension, while keeping shared utilities centralised.

Practical organisation guidance (recommended):

- [TF-STR-007] Use `locals {}` for naming and derived values, but keep them small and readable.
- [TF-STR-008] Prefer explicit modules over copy-pasting resources across stacks.
- [TF-STR-009] Keep provider configuration and backend configuration in predictable, easy-to-find places.
- [TF-STR-010] Follow Terraform's style guide: two-space indentation, blank lines between logical sections, and alphabetical ordering of resources, variables, providers, and outputs within files where reasonable.
- [TF-STR-011] Group related resources within a file and keep required attributes ahead of optional ones so reviewers can scan intent quickly.
- [TF-STR-012] Place `depends_on` (when needed) at the top of a resource block, followed by `for_each`/`count`, so evaluation order is explicit; keep `lifecycle {}` blocks at the end.

---

## 11. Naming, tagging, and ownership 🏷️

### 11.1 Naming

- [TF-TAG-001] Use consistent, predictable naming conventions across resources.
- [TF-TAG-002] Encode environment and domain boundaries in names (without leaking sensitive data).
- [TF-TAG-003] Prefer stable identifiers over human "clever" names.

### 11.2 Tagging (mandatory)

Apply a standard tag set to all supported resources:

- [TF-TAG-004] `service` / `application`
- [TF-TAG-005] `component`
- [TF-TAG-006] `environment`
- [TF-TAG-007] `owner` (team name, not an individual)
- [TF-TAG-008] `cost_centre` (or equivalent)
- [TF-TAG-009] `data_classification` (if applicable)
- [TF-TAG-010] `managed_by = terraform`
- [TF-TAG-011] Do not embed secrets or personal data in tags.

---

## 12. Security defaults 🔐

Security is part of the infrastructure contract. **Secure-by-default is non-negotiable.**

### 12.1 Identity and access management

#### Least privilege by default (non-negotiable)

- [TF-SEC-001] Grant the minimum permissions required for the workload and for Terraform.
- [TF-SEC-002] Prefer **role-based access** over long-lived credentials.
- [TF-SEC-003] Separate roles for:
  - [TF-SEC-003a] provisioning (Terraform)
  - [TF-SEC-003b] runtime execution (applications/services)
  - [TF-SEC-003c] human operational access (break-glass)

#### Trust boundaries

- [TF-SEC-004] Prefer dedicated AWS accounts for production and strong separation using AWS Organizations.
- [TF-SEC-005] Use SCPs and permission boundaries where appropriate.
- [TF-SEC-006] Treat cross-account access as a first-class design concern; document it and test it.

#### Secrets

- [TF-SEC-007] Secrets must not be stored in Terraform state as plaintext values.
- [TF-SEC-008] Prefer AWS-managed secret stores:
  - [TF-SEC-008a] Secrets Manager
  - [TF-SEC-008b] SSM Parameter Store (SecureString with KMS)
- [TF-SEC-009] If a secret must be referenced, reference it by ARN/name and manage its lifecycle appropriately.
- [TF-SEC-010] Load secrets into Terraform via environment variables or injected files that reference Secrets Manager/SSM values so sensitive data never lands in state.
- [TF-SEC-011] Never commit credentials, state files, or generated secrets to version control; maintain `.gitignore` rules to enforce this and verify in code review.
- [TF-SEC-012] Mark sensitive input variables (`variable "..." { sensitive = true }`) and outputs so Terraform redacts them from plans/applies.
- [TF-SEC-013] Rotate secrets and IAM credentials regularly (and automate rotation where tooling allows); document the schedule per stack.

### 12.2 Networking and connectivity

- [TF-SEC-014] Use clear VPC boundaries and documented CIDR plans.
- [TF-SEC-015] Prefer private subnets for compute and data stores.
- [TF-SEC-016] Internet access should be explicit (NAT gateways, egress controls).
- [TF-SEC-017] Use security groups with minimal ingress/egress rules.
- [TF-SEC-018] Avoid wide-open rules (`0.0.0.0/0`) unless explicitly required and documented.
- [TF-SEC-019] For service-to-service connectivity, prefer private connectivity patterns:
  - [TF-SEC-019a] VPC endpoints (Interface/Gateway endpoints)
  - [TF-SEC-019b] PrivateLink where appropriate
  - [TF-SEC-019c] internal load balancers for internal services
- [TF-SEC-020] Document and test connectivity assumptions (DNS, routing, endpoints, firewall rules).
- [TF-SEC-021] Apply network ACLs intentionally to enforce subnet-level guardrails, documenting why any broad rules exist.

### 12.3 Encryption and data protection

- [TF-SEC-022] Encrypt data **at rest** and **in transit** by default.
- [TF-SEC-023] Prefer customer-managed keys (KMS) when policy requires it.
- [TF-SEC-024] Rotate keys according to policy and document rotation expectations.
- [TF-SEC-025] Ensure TLS is enforced on:
  - [TF-SEC-025a] load balancers
  - [TF-SEC-025b] API endpoints
  - [TF-SEC-025c] database connections where supported
- [TF-SEC-026] Ensure logs and state are encrypted and access-controlled.
- [TF-SEC-027] Explicitly enable encryption for EBS volumes, S3 buckets, RDS/Aurora instances, and any other managed data stores; document exceptions with compensating controls.

---

## 13. Reliability, resilience, and recovery 🛟

Resilience is an explicit requirement, not an afterthought.

- [TF-REL-001] Treat resilience as an explicit requirement, not an afterthought.
- [TF-REL-002] Make failure modes explicit:
  - [TF-REL-002a] what happens if a dependency is unavailable?
  - [TF-REL-002b] what fails open vs fails closed?
- [TF-REL-003] Prefer multi-AZ for production where appropriate.
- [TF-REL-004] Document and test recovery expectations:
  - [TF-REL-004a] backups (RPO/RTO)
  - [TF-REL-004b] restore procedures
  - [TF-REL-004c] runbooks and escalation paths
- [TF-REL-005] Use health checks and autoscaling where appropriate and specified.

---

## 14. Observability and auditability 🔭

**Section summary (key subsections):**

- 14.1 Golden signals and SLO discipline
- 14.2 Standard telemetry baseline (CloudWatch logs, metrics, alarms, dashboards)
- 14.3 Logging — structured, centralised, retention-controlled
- 14.4 Metrics — actionable signals, cardinality rules
- 14.5 Distributed tracing — end-to-end visibility
- 14.6 Service-specific expectations (API Gateway, Lambda, ECS, RDS, DynamoDB, SQS, S3, VPC)
- 14.7 Security and audit observability (CloudTrail, Config, GuardDuty)
- 14.8–14.9 Alerting, runbooks, operational documentation

Observability is **non-negotiable**. Every production stack must make it possible to answer quickly:

- [TF-OBS-001] What changed (deployment, config, infra drift)?
- [TF-OBS-002] What broke (symptoms, blast radius, timeline)?
- [TF-OBS-003] Where is the bottleneck (service, dependency, region/AZ)?
- [TF-OBS-004] Is it transient or persistent?
- [TF-OBS-005] What should we do next (runbook, rollback, mitigation)?

### 14.1 Golden signals and SLO discipline 🧭

- [TF-OBS-006] Use **golden signals** (at minimum): **latency**, **traffic**, **errors**, **saturation**.
- [TF-OBS-007] Define **SLIs** and **SLOs** per critical capability (API, queue consumer, batch job, etc.):
  - [TF-OBS-007a] availability / success rate
  - [TF-OBS-007b] latency targets (p50/p95/p99 where relevant)
  - [TF-OBS-007c] freshness/lag for async processing (queue age, event delay)
- [TF-OBS-008] Alerts must be designed around SLOs (avoid alerting on every metric fluctuation).

### 14.2 Standard telemetry baseline (mandatory) 🧱

For every stack, provision (or integrate with) the following as baseline:

- [TF-OBS-009] **CloudWatch Logs** for all compute (Lambda/ECS/EKS/EC2) and managed services where supported
- [TF-OBS-010] **CloudWatch Metrics** and **Alarms** for golden signals and key service limits
- [TF-OBS-011] **Dashboards** (CloudWatch or equivalent) for:
  - [TF-OBS-011a] service health (SLIs)
  - [TF-OBS-011b] dependency health
  - [TF-OBS-011c] saturation / capacity / quotas
  - [TF-OBS-011d] deployment markers (version/time)
- [TF-OBS-012] **Notifications** wired to on-call channels (SNS → Slack/Teams/email as appropriate)
- [TF-OBS-013] **Runbook reference** for each paging alarm (link or identifier)

### 14.3 Logging (CloudWatch-first, structured, centralised) 🪵

Logging must be intentional, queryable, and safe.

**Mandatory controls:**

- [TF-OBS-014] Set log retention explicitly for every log group (no "never expire" by accident).
- [TF-OBS-015] Encrypt log groups with KMS where policy requires it.
- [TF-OBS-016] Use least-privilege access for read/write of logs.
- [TF-OBS-017] Protect log integrity for audit-relevant streams (centralised copies, retention, access controls).

**Centralisation:**

- [TF-OBS-018] Production logs must be centralised beyond the source service where appropriate (for example via subscription filters to a central destination such as Firehose/S3/OpenSearch).
- [TF-OBS-019] Central log storage must support:
  - [TF-OBS-019a] search and correlation across services/accounts
  - [TF-OBS-019b] retention per policy
  - [TF-OBS-019c] access separation between producers and readers

**Operational rules:**

- [TF-OBS-020] Prefer structured logs (JSON) for application logs; avoid free-text-only logs.
  - [TF-OBS-020a] Application logs emitted by Lambda functions, ECS containers, and similar compute must follow the [Structured Logging Baseline](./includes/observability-baseline.include.md) field requirements — this is an infrastructure concern because log retention, parsing, and alerting depend on consistent schemas.
- [TF-OBS-021] Ensure logs include correlation identifiers consistently (request id / trace id / account id / region).
- [TF-OBS-022] Use CloudWatch Logs Insights-friendly fields and stable event names.

### 14.4 Metrics (actionable, low-noise) 📈

Provision metrics that drive action, not vanity charts.

**Mandatory:**

- [TF-OBS-023] Alarms for:
  - [TF-OBS-023a] error rate spikes
  - [TF-OBS-023b] latency degradation
  - [TF-OBS-023c] throttling/limit breaches
  - [TF-OBS-023d] queue backlog and age (async)
  - [TF-OBS-023e] exhausted capacity / saturation signals
- [TF-OBS-024] Use anomaly detection or dynamic thresholds where appropriate for noisy metrics, but do not hide real incidents.
- [TF-OBS-025] Use composite alarms when multiple signals together define "bad" (to reduce noise).

**Cardinality rules:**

- [TF-OBS-026] Never put high-cardinality identifiers into metric dimensions (request ids, user ids, object ids).
- [TF-OBS-027] Dimensions must remain bounded and stable.

### 14.5 Distributed tracing (end-to-end) 🧵

If the system has more than one hop (API → service → database/queue/another service), distributed tracing must be supported.

- [TF-OBS-028] Prefer standard trace context propagation (W3C trace context).
- [TF-OBS-029] Where applicable, enable tracing using:
  - [TF-OBS-029a] AWS X-Ray, or
  - [TF-OBS-029b] OpenTelemetry (collector/SDK) feeding your chosen backend
- [TF-OBS-030] Ensure trace propagation across:
  - [TF-OBS-030a] API Gateway/ALB → compute
  - [TF-OBS-030b] compute → AWS SDK calls (DynamoDB/SQS/SNS/EventBridge/S3, etc.)
  - [TF-OBS-030c] compute → HTTP dependencies

### 14.6 Service-specific observability expectations ✅

When a service is used, enable the relevant metrics/logs/alarms. At minimum:

**API Gateway / ALB / CloudFront**

- [TF-OBS-031] 4xx/5xx rate alarms, latency alarms
- [TF-OBS-032] WAF (if present): blocked/allowed counts and top rules
- [TF-OBS-033] Access logging enabled where appropriate (with retention and centralisation)

**Lambda**

- [TF-OBS-034] Errors, throttles, duration, timeouts, iterator age (if event source)
- [TF-OBS-035] Concurrency usage (and provisioned concurrency where used)
- [TF-OBS-036] Dead-letter / failure destination alarms (if configured)
- [TF-OBS-037] Explicit alarm on approaching timeout (duration p99 near configured timeout)

**ECS/EKS/EC2**

- [TF-OBS-038] CPU/memory saturation, restarts, task/Pod health, node pressure
- [TF-OBS-039] Load balancer target health alarms
- [TF-OBS-040] Container log routing and retention rules

**RDS/Aurora**

- [TF-OBS-041] CPU, connections, storage, replica lag, failover events
- [TF-OBS-042] Slow query insights/alarms (where supported/appropriate)
- [TF-OBS-043] Backup/restore alarms and maintenance events awareness

**DynamoDB**

- [TF-OBS-044] Throttled requests, consumed capacity trends, latency (where available)
- [TF-OBS-045] Error alarms for conditional check failures only when they are unexpected
- [TF-OBS-046] Alarms on hot partitions symptoms (via throttling/capacity patterns)

**SQS/SNS/EventBridge**

- [TF-OBS-047] Queue depth, age of oldest message, DLQ depth
- [TF-OBS-048] Delivery failures, retries, and DLQ alarms
- [TF-OBS-049] EventBridge failed invocations / throttles

**S3**

- [TF-OBS-050] Access logging where required
- [TF-OBS-051] 4xx/5xx error alarms where workloads depend on it
- [TF-OBS-052] Replication/notification failure signals where used

**VPC / Network**

- [TF-OBS-053] VPC Flow Logs enabled where policy requires it (with retention and cost controls)
- [TF-OBS-054] NAT gateway errors/metrics where relevant
- [TF-OBS-055] DNS/Route53 health checks for critical endpoints

### 14.7 Security and audit observability 🛡️

Audit and security signals must be enabled and monitored.

**Mandatory:**

- [TF-OBS-056] CloudTrail enabled (organisation-wide where possible), with protected storage and retention.
- [TF-OBS-057] AWS Config enabled where policy requires it (or equivalent controls) for drift/compliance detection.
- [TF-OBS-058] Security services (where adopted in your estate) must be integrated:
  - [TF-OBS-058a] GuardDuty findings routed to a central destination
  - [TF-OBS-058b] Security Hub aggregation (if used)
  - [TF-OBS-058c] IAM Access Analyzer findings triaged

**Alerting rules:**

- [TF-OBS-059] Page only on actionable, high-confidence security signals.
- [TF-OBS-060] Everything else should be ticketed/routed for triage, not paged.

### 14.8 Alerting, escalation, and runbooks 📣

- [TF-OBS-061] Every paging alarm must have:
  - [TF-OBS-061a] a clear description of impact and likely causes
  - [TF-OBS-061b] an owner/team
  - [TF-OBS-061c] a runbook link or identifier
  - [TF-OBS-061d] a clear "how to silence safely" note (and who can do it)
- [TF-OBS-062] Prefer multi-window / multi-burn-rate alerting for SLO-based alerts where your tooling supports it.
- [TF-OBS-063] Avoid alert fatigue:
  - [TF-OBS-063a] prefer fewer, higher-quality paging alarms
  - [TF-OBS-063b] route low-severity issues to ticketing

### 14.9 Operational documentation and dashboards 🗺️

For production stacks, provide (in `docs/`):

- [TF-OBS-064] a short "how this stack works" overview
- [TF-OBS-065] key dashboards and what "good" looks like
- [TF-OBS-066] common failure scenarios and mitigations
- [TF-OBS-067] rollback and recovery steps (including non-reversible actions)

---

## 15. Validation, linting, and security scanning (non-negotiable) 🔍

Validation is mandatory. All changes must pass static checks before plan.

### 15.1 Linting and style (mandatory)

- [TF-VLD-001] `terraform fmt` is mandatory.
- [TF-VLD-002] Use linting (for example `tflint`) and treat findings as defects.

### 15.2 Security and policy scanning (mandatory)

Run IaC security checks (tooling may vary by repo, but must exist). Examples include:

- [TF-VLD-003] Trivy (IaC scanning)
- [TF-VLD-004] Checkov
- [TF-VLD-005] tfsec (if still used in your estate)

Rules:

- [TF-VLD-006] Treat high/critical findings as **blocking**.
- [TF-VLD-007] Findings may only be waived in an ADR (rationale + expiry).
- [TF-VLD-008] Prefer policy-as-code for non-trivial estates (OPA/Conftest, Sentinel, or equivalent), especially for:
  - [TF-VLD-008a] public exposure
  - [TF-VLD-008b] encryption
  - [TF-VLD-008c] IAM wildcards
  - [TF-VLD-008d] logging/audit requirements

---

## 16. Cost and performance discipline 💵

Cost is a non-functional requirement. Treat it explicitly.

- [TF-COST-001] Treat cost as a non-functional requirement.
- [TF-COST-002] Prefer right-sizing over over-provisioning.
- [TF-COST-003] Use budgets/alerts where appropriate.
- [TF-COST-004] Tagging (see §11) must support cost allocation.
- [TF-COST-005] When introducing a costly service, include:
  - [TF-COST-005a] expected spend drivers
  - [TF-COST-005b] scaling assumptions
  - [TF-COST-005c] cost guardrails (limits, alarms, quotas)

---

## 17. Documentation and diagrams (C4 + infrastructure diagram) 🗺️

Documentation is part of "done". Any infrastructure change must leave the documentation set accurate.

### 17.1 C4 model alignment (mandatory)

- [TF-DOC-001] Maintain a set of C4 diagrams in `docs/` using the [LikeC4](https://likec4.dev/) format (Context, Container, Component, and where valuable Deployment).
- [TF-DOC-002] When Terraform changes affect architecture boundaries, trust boundaries, runtime topology, or integrations, update the relevant C4 diagrams in the same PR.

### 17.2 Infrastructure diagram (mandatory)

In addition to C4, maintain an **infrastructure diagram** that reflects the concrete AWS resources and their connections.

Rules:

- [TF-DOC-003] The infrastructure diagram must:
  - [TF-DOC-003a] cover the key AWS services, networks, and data flows
  - [TF-DOC-003b] show trust boundaries (accounts/VPCs/subnets), ingress/egress, and critical dependencies
  - [TF-DOC-003c] be understandable by an on-call engineer during an incident
- [TF-DOC-004] The diagram must be updated in the same PR whenever Terraform changes affect:
  - [TF-DOC-004a] networking/routing/security groups/NACLs
  - [TF-DOC-004b] ingress/egress (ALB/API Gateway/CloudFront/WAF)
  - [TF-DOC-004c] compute topology (Lambda/ECS/EKS/EC2)
  - [TF-DOC-004d] data stores (RDS/Aurora/DynamoDB/S3)
  - [TF-DOC-004e] queues/events (SQS/SNS/EventBridge/Kinesis)
  - [TF-DOC-004f] cross-account or cross-service integrations

### 17.3 Diagram format and storage

- [TF-DOC-005] C4 diagrams must be stored in-repo as LikeC4 source files (`.c4` or `.likec4`) and remain reviewable in PRs.
- [TF-DOC-006] Unless a more specific repository prompt explicitly requires a different format, any non-C4 diagram must be authored in Mermaid, either as fenced `mermaid` blocks in Markdown or as standalone Mermaid source files stored in-repo.
- [TF-DOC-007] Link diagrams from a stable index page (for example `docs/architecture/README.md`) so they are discoverable.

### 17.4 Traceability to Terraform

- [TF-DOC-008] The infrastructure diagram must be traceable to the Terraform stacks/modules:
  - [TF-DOC-008a] reference stack/module names in the diagram or adjacent documentation
  - [TF-DOC-008b] keep naming consistent with Terraform resource naming conventions
- [TF-DOC-009] Where useful, include a short "mapping" section that points from diagram elements to Terraform paths (high-level, not every resource).

### 17.5 Project-level documentation

- [TF-DOC-010] Each stack or project directory must include a `README.md` describing its purpose, prerequisites, commands (`make plan`, etc.), and any environment-specific nuances.
- [TF-DOC-011] Use inline comments sparingly to explain complex configurations, design decisions, or mitigations; remove stale comments during refactors.
- [TF-DOC-012] Prefer `terraform-docs` (or equivalent automation) to generate up-to-date variable/output tables; run it as part of the change whenever inputs/outputs shift.

---

## 18. Testing infrastructure changes 🧪

Per [constitution.md §3.6](../../.specify/memory/constitution.md#36-design-for-testability-tdd), follow a layered approach:

- [TF-TST-001] **Static checks**: fmt, validate, lint, security scan
- [TF-TST-002] **Plan review**: human review of create/update/destroy
- [TF-TST-003] **Automated tests** (where valuable):
  - [TF-TST-003a] Terraform native tests (`terraform test`) where adopted
  - [TF-TST-003b] Contract tests for modules (inputs/outputs and invariants)
  - [TF-TST-003c] Targeted integration checks for critical paths (time-boxed)
- [TF-TST-004] Do not build huge end-to-end infra tests by default; focus on high-risk boundaries.
- [TF-TST-005] Where `terraform test` (or `.tftest.hcl` files) are adopted, cover both positive and negative paths, keep tests idempotent, and ensure they can run repeatedly without side effects.

---

## 19. AI-assisted change expectations 🤖

Per [constitution.md §3.5](../../.specify/memory/constitution.md#35-ai-assisted-development-discipline--change-governance), when you create or modify Terraform:

- [TF-AI-001] Follow the shared [AI change baseline](./includes/ai-assisted-change-baseline.include.md) for scope, quality, and governance.
- [TF-AI-002] Preserve determinism and environment isolation.
- [TF-AI-003] Always produce and review a plan (and keep it for the PR where possible).

---

## 20. Anti-patterns (recognise and avoid) 🚫

These patterns cause recurring issues in Terraform codebases. Avoid them unless an ADR documents a justified exception.

- [TF-ANT-001] **Hardcoded ARNs/account IDs** — use variables or data sources; breaks portability across environments.
- [TF-ANT-002] **`count` with complex conditionals** — prefer `for_each` for clarity and stable resource keys; `count` index shifts cause recreations.
- [TF-ANT-003] **Inline policies instead of managed policies** — harder to audit, reuse, and track in IAM; prefer `aws_iam_policy` resources.
- [TF-ANT-004] **`depends_on` for data dependencies** — usually indicates missing explicit references; fix the graph instead.
- [TF-ANT-005] **`ignore_changes` as a permanent workaround** — masks drift; document with ADR + expiry and plan removal.
- [TF-ANT-006] **Floating provider versions** — determinism risk; pin explicitly in `required_providers` and commit `.terraform.lock.hcl`.
- [TF-ANT-007] **State in local backend for shared environments** — blocks collaboration and breaks CI; use remote backend with locking.
- [TF-ANT-008] **Secrets in `.tfvars` or variable defaults** — leaks to state, logs, and version control; use Secrets Manager/SSM references.
- [TF-ANT-009] **Wide IAM wildcards (`*` resource + `*` action)** — least privilege violation; scope to specific resources and actions.
- [TF-ANT-010] **Mega-modules (>300 lines, multiple concerns)** — hard to test, review, and reuse; split by responsibility.
- [TF-ANT-011] **Copying resources instead of extracting modules** — drift risk and maintenance burden; extract and version shared patterns.
- [TF-ANT-012] **Missing `description` on variables/outputs** — poor discoverability; always document intent and constraints.
- [TF-ANT-013] **`terraform apply -auto-approve` in production** — bypasses review; use CI approvals and plan artefacts.
- [TF-ANT-014] **Unencrypted state bucket** — compliance and security risk; enable SSE-KMS and versioning.
- [TF-ANT-015] **Log groups without explicit retention** — cost bloat and compliance risk; set `retention_in_days` on every `aws_cloudwatch_log_group`.

---

> **Version**: 1.5.1
> **Last Amended**: 2026-01-17
