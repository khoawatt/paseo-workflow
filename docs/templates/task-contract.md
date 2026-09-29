# Define an adaptive task contract

Use this contract for meaningful work when it improves clarity and for every
delegated M2–M4 slice under [Phase 1 Governance](../GOVERNANCE.md). Keep it
proportional and omit optional fields that do not apply. This document scopes
work; it does not grant permissions or prescribe Paseo runtime state.

## Goal and deliverable

- Goal:
- Deliverable:

## Authority and context

- Applicable repository instructions:
- Source-of-truth files:
- Relevant code, tests, or external sources:
- Assumptions requiring confirmation:

## Mode and strategy

- Mode: `M0` | `M1` | `M2` | `M3` | `M4`
- Mode source: `human` | `repository` | `lead`
- Strategy: `single` | `sequential` | `parallel`
- Rationale:

## Scope

- In scope:
- Out of scope:
- Read scope:
- Write scope:
- Forbidden paths or actions:

Treat the write scope as an allowlist. Stop and request rescoping before changing
any path or behavior outside it.

## Repository state

- Repository root:
- Branch or reviewable state:
- Base ref/commit, if relevant:
- Pre-existing changes to preserve:
- Isolation requirement or approved fallback:

Do not record live agent, session, workspace, permission-request, credential, or
other runtime-owned identifiers in a committed contract.

## Acceptance criteria

- [ ]

## Constraints and dependencies

- Technical constraints:
- Security/privacy constraints:
- Dependencies or external systems:
- Dependency legitimacy or supply-chain concerns:
- Time or compatibility constraints:

## Risk and human checkpoints

- Risk/blast radius:
- Reversibility or recovery plan:
- Explicit human approvals required:
- Stop conditions:

## Verification plan

- Focused checks:
- Broader checks:
- Manual/runtime checks, if applicable:
- Expected evidence class:
- Conditions that must be reported as skipped or blocked:

## Role and capability needs

- Required role or specialty:
- Required capabilities:
- Prohibited capabilities or authority:

Choose any Profile, provider, model, workspace, or runtime settings from current
human direction and Paseo discovery. Do not hard-code them into a reusable
contract or infer that model strength grants orchestration authority.

## Escalation

Stop and return to the Lead or human when scope is insufficient, authority is
missing, a human commitment gate is reached, sources conflict, the selected
approach repeatedly fails, or safe verification is impossible. Do not silently
expand scope.

## Completion gate

Do not report `DONE` until all of these conditions hold:

- Every acceptance criterion is satisfied with evidence.
- Required verification ran and its results are recorded.
- No scope, authority, approval, or safety blocker remains unresolved.
- The exact final implementation state has a fresh independent Reviewer
  `ACCEPT` when repository policy requires it.

If any condition fails, report `partial` or `blocked`, identify the unmet
condition, and name the next action. Technical capability does not override this
gate.

## Handoff

- Outcome/status: `complete` | `partial` | `blocked`
- Changed paths or artifacts:
- Verification performed and results:
- Evidence classification:
- Review state and exact reviewed state:
- Skipped/blocked checks:
- Residual risks:
- Recommended next action:
