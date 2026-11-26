# Issue Writing Standard

Certlab uses issues as executable specifications for human and AI contributors. An issue is ready for implementation only when an agent can identify the intended outcome, the applicable constraints, and the evidence required for completion without guessing about product or architecture decisions.

This standard applies whenever an issue is created, split, or materially refined. Use the issue-tracker language defined by the maintainer's local instructions.

## Required structure

### Context

Explain why the change is needed, what the current state is, and where the requirement originated. Include enough domain and repository context for someone who did not participate in the earlier discussion. Link to the relevant source instead of copying an entire specification.

### Objective

State one primary, independently deliverable outcome in a single sentence. If the issue has multiple outcomes that could be delivered or reviewed separately, split it.

### In scope

List the behaviors, components, packages, directories, or documentation that the implementation must cover. Prefer concrete positive boundaries over broad statements such as "implement the architecture."

### Out of scope

List closely related work that must not be implemented in this issue. Name deferred apps, packages, integrations, migrations, or product behavior when their omission might otherwise look accidental.

### Acceptance criteria

Use checkboxes containing observable, binary outcomes. Each criterion must be independently verifiable and describe the required result rather than a vague activity.

Good criteria:

- identify the exact behavior, artifact, or repository boundary being validated;
- state the relevant subset when referencing a broad roadmap item, design section, or ADR;
- include expected failure or boundary behavior when it is material;
- name required quality gates when they are part of completion;
- avoid combining unrelated outcomes in one checkbox.

Avoid criteria such as "works correctly," "matches the design," or "corresponds to the ADR" without specifying what correct behavior or which applicable subset means.

### Technical constraints

Record decisions the implementation must preserve, including applicable ADRs, architecture boundaries, security requirements, compatibility guarantees, and approved technologies. Describe constraints and outcomes; do not prescribe step-by-step implementation unless the approach is already an accepted decision.

### Expected validation

Name the tests, commands, manual checks, or other evidence that should demonstrate completion. Do not duplicate acceptance criteria: criteria define what must be true, while validation describes how the implementer should prove it.

### References and dependencies

Link directly to relevant roadmap sections, design documentation, ADRs, related issues, and external specifications. Identify blockers and ordering dependencies explicitly.

## Definition of Ready

Before creating or assigning an implementation issue, confirm that:

- [ ] The issue has one primary outcome that can reasonably be delivered and reviewed in one pull request.
- [ ] The context explains the need and the current state without relying on private conversation history.
- [ ] In-scope and out-of-scope boundaries are explicit.
- [ ] Every acceptance criterion has an observable pass or fail result.
- [ ] Broad references identify the exact section or subset that applies.
- [ ] Dependencies, blockers, and deferred work are identified.
- [ ] The issue does not conflict with the roadmap, design document, or accepted ADRs.
- [ ] No unresolved product or architecture decision is being delegated to the implementer implicitly.
- [ ] The issue specifies required outcomes without unnecessarily dictating implementation details.

If a material decision is unresolved, the issue is not ready for implementation. Resolve the decision, create a focused discovery issue, or record the accepted choice in the appropriate source document before assigning implementation work.

## Phase wrap-up issues

Every roadmap phase or numbered workstream that produces multiple implementation issues must end with one wrap-up issue. The wrap-up is ordered after and depends on all implementation issues in that scope. It consolidates the delivered state before the next phase or workstream begins.

A wrap-up issue must:

- compare completed work with the roadmap, design document, accepted ADRs, and the issues in the completed scope;
- reconcile the applicable roadmap checkboxes against repository and external-system evidence;
- update the developer README, architecture documentation, ADR index, contributor guidance, and agent instructions when they no longer describe the repository accurately;
- verify that documented runtime, toolchain, dependency, schema, and configuration versions match the versions actually in use;
- run the complete quality-gate suite applicable to that phase and record the evidence;
- identify incomplete, deferred, contradictory, or newly discovered work explicitly;
- create or request focused follow-up issues for material gaps instead of silently expanding the wrap-up scope;
- summarize completed work, deferrals, known limitations, and follow-ups in the wrap-up pull request.

Small documentation and consistency corrections belong in the wrap-up. New product capabilities, substantial refactors, dependency migrations, and unfinished implementation work do not. The wrap-up must not mark a roadmap item complete without evidence.

## Quality examples

Ambiguous:

> The repository structure corresponds to ADR-0002.

Specific:

> The initial repository structure implements the Phase 1.1 subset of ADR-0002: `apps/{api,web}` and `packages/{contracts,core,tokens,config}`. Deferred applications, packages, content, and infrastructure are not scaffolded by this issue.

Ambiguous:

> Add localization and make sure it works.

Specific:

> The web frontend can render English and Brazilian Portuguese message catalogs, falls back to English for a missing translation key, and persists a manually selected locale across a page reload.
