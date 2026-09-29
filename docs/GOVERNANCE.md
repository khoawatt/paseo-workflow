# Phase 1 governance policy

This policy adapts the reusable governance concepts identified in the
[AI OS v1.6 salvage matrix](architecture/ai-os-v1.6-salvage-migration-matrix.md)
without restoring the old AI OS runtime. It governs how the Lead selects task
depth, scopes work, requests human commitments, evaluates evidence, and records
reusable feedback.

## Authority and ownership

This document is subordinate to the authority order in [AGENTS.md](../AGENTS.md)
and the accepted [Bootstrap V1 specification](specs/2026-09-24-paseo-workflow-bootstrap-v1.md).
When sources disagree, follow the higher authority and record the mismatch.

- Paseo owns agent lifecycle, delegation, messages, Profiles, permissions,
  workspaces/worktrees, schedules, heartbeats, and runtime state.
- The Lead owns task-depth selection, decomposition, role selection, evidence
  interpretation, and review or rework decisions.
- Git and GitHub own durable code provenance and engineering collaboration.
- The human owns destructive and other high-impact commitment decisions.

The modes below are Lead policy metadata. They are not Paseo modes, persisted
runtime state, permission grants, or an alternative orchestration controller.
They never widen the authority provided by the human, Paseo, the provider, the
repository, or the execution sandbox.

### Policy and runtime flow

Use this decision-to-execution flow:

```text
Human commitments and constraints
        ↓
Lead reasoning and policy
        ↓
Paseo runtime
        ↓
Paseo Profiles and scoped workers
```

The Lead selects task depth, scope, context, and evidence requirements. Paseo
executes lifecycle, delegation, messaging, workspace, worktree, and permission
operations. Profiles remain the role launch presets. This policy does not add a
layer between the Lead and Paseo or create new agent roles.

## Operating modes

Select the smallest mode that covers the task's complexity and risk. Record the
mode, its source, the execution strategy, and a short rationale for meaningful
work. A task may move between modes when evidence changes. Record the reason.

| Mode | Task complexity | Context depth | Verification depth | Review requirement | Escalate when |
|---|---|---|---|---|---|
| M0: Trivial | One obvious, local, reversible, low-risk change | Low | Check the changed artifact and its direct contract | Inspect the final diff and apply the repository review rule to implementation changes | Scope expands, behavior is uncertain, or risk is no longer low |
| M1: Standard | One clear owner; ordinary change in one component or a small related set | Medium | Run focused checks plus affected tests or document validation | Review scope and regression risk; obtain fresh independent review for the exact final implementation state | The change crosses an architecture boundary, needs delegation, or exposes high-impact risk |
| M2: Delegated | Work benefits from narrow research, review, or implementation slices, but the Lead can reconcile them directly | Medium, plus exact slice context | Verify every slice and the reconciled result | The Lead checks each handoff; fresh independent review covers the exact final implementation state | A slice lacks authority, scopes overlap, reconciliation is unclear, or repeated attempts fail |
| M3: Multi-slice | Work spans multiple modules or architecture boundaries, or independent investigation or writing creates clear value | High | Run slice-specific checks and the full combined gate | The Lead reviews integration evidence; fresh independent review covers the combined final state | Write scopes overlap, the architecture changes, integration fails, or coordination cost exceeds the benefit |
| M4: Controlled | Security, data, infrastructure, production, irreversible, or high-blast-radius work | High, including current risk and recovery evidence | Run all applicable safety, rollback, focused, and full gates | Stop at human checkpoints and obtain fresh independent review for the exact final implementation state | Approval is missing, live state drifts, rollback is unsafe, or impact exceeds the authorized scope |

M4 is a governance overlay, not a synonym for parallel work. It can use a
single, sequential, or parallel strategy.

### Mode source

Record one of:

- `human`: the human explicitly selected or constrained the mode;
- `repository`: repository policy requires the mode or a minimum control;
- `lead`: the Lead selected the minimum sufficient mode from observed risk and
  complexity.

A lower requested mode cannot bypass a mandatory safety, repository, or human
approval rule.

### Execution strategy

Select strategy separately from mode:

- `single`: one active execution owner;
- `sequential`: slices or reviews occur in a controlled order;
- `parallel`: independent slices run concurrently.

Higher modes do not automatically authorize more workers. Parallelism is
appropriate only when scopes are independent and its benefit exceeds the
coordination cost.

## Progressive context loading

Context depth defines the inputs the Lead inspects before deciding or delegating.
It does not trigger automated retrieval, memory loading, or background services.

| Depth | Required inputs | Use when |
|---|---|---|
| Low | Task description, applicable repository instructions, directly relevant files, and the focused verification target | The change is local, reversible, and already understood |
| Medium | Low-depth inputs plus relevant architecture docs, related tests, constraints, dependencies, and affected interfaces | The work changes behavior, spans related files, or needs a delegated slice |
| High | Medium-depth inputs plus relevant historical decisions, migration records, prior incidents, cross-module dependencies, live-state evidence, approval needs, and recovery constraints | The work crosses boundaries, coordinates multiple slices, or carries high-impact risk |

Apply these selection rules:

1. Start M0 at low depth and M1 or M2 at medium depth.
2. Start M3 and M4 at high depth.
3. Raise depth when evidence reveals a wider dependency, unresolved history, or
   a stronger risk.
4. Give each delegated slice only its required authority, scope, source, and
   verification context.
5. Search before opening broad histories or logs. At high depth, read only the
   records relevant to the current decision.
6. Record missing required context as an assumption, escalation, or blocker.

Do not treat chat history, stale memory, or a previous run as current runtime
evidence. Verify drift-prone facts when the task depends on them.

## Task contracts

Use [the adaptive task contract](templates/task-contract.md) for meaningful M1
work when it improves clarity and for every delegated M2–M4 slice. Keep it
proportional: omit non-applicable optional fields instead of creating separate
lite and full formats.

A contract must not prescribe a provider, model, Profile, worktree ID, or Paseo
runtime operation unless the human or current runtime evidence already made
that choice. It does not grant permissions. If the requested work exceeds its
scope, stop that portion and request rescoping.

Independent write workers use separate Paseo worktrees by default. A shared
working tree is only an explicit fallback and must be reported accurately; Git
history must not later be reconstructed to imply isolation that did not occur.

## Human commitment boundaries

Stop and obtain explicit human approval before:

- deploying, rolling back, or changing production configuration;
- accessing production secrets or exposing credentials to another agent;
- destructive or irreversible filesystem, workspace, worktree, data, or
  database actions;
- deleting data or making security or compliance tradeoffs;
- sending external writes at scale or charging, refunding, or transferring
  money;
- force-pushing, pushing or merging a protected/canonical branch, or deleting
  branches when that action has not already been authorized;
- materially expanding scope or increasing beyond an authorized worker limit;
- accepting a broader-than-expected host or repository mutation.

This list is policy vocabulary, not an executable permission registry. Paseo
permission controls, provider-native filesystem/network/command controls, and
human approval are independent boundaries. An approval for one exact action
does not authorize adjacent actions.

## Quality and evidence gates

Before reporting completion for meaningful work:

1. Confirm the relevant authority and task context were inspected.
2. Confirm the result stayed within the declared scope and write boundary.
3. Run meaningful verification proportional to the change.
4. Review regression, safety, dependency, and integration risks.
5. Record commands or observations, outcomes, skipped gates, and residual risk.
6. Label evidence accurately as `implemented`, `fixture-tested`,
   `runtime-tested`, or `not tested / blocked`.

An ordinary task instruction cannot turn an unverified result into verified
evidence. If required verification cannot run, report the exact limitation and
do not claim the missing evidence class.

For implementation work, any change after review invalidates that review. The
exact final implementation state must receive a fresh independent Reviewer
`ACCEPT` before the Lead reports `DONE`. A worker's success report is not a
substitute for inspecting its scope, changes, and combined verification.

Use the [behavioral evaluation specification](evals/behavioral-evaluation-spec.md)
to test these policy behaviors. Historical AI OS results and static regression
fixtures are calibration or provenance only and never establish a current
`PASS`.

## Feedback loop

Capture recurring corrections, escaped defects, ambiguous contracts, missing
context, repeated manual work, stale guidance, and successful reusable patterns.
Classify each signal and propose the smallest durable improvement: a document,
template, test/eval, skill, issue, or narrowly justified automation.

Apply an improvement only when it is inside the authorized task scope. Otherwise
record it as a follow-up. Do not automatically mutate memory, `storage`, host
configuration, runtime policy, or scripts. Verify adopted improvements and
report remaining risk.

## Non-goals

Phase 1 does not add or recreate:

- a controller, runtime state machine, queue, retry engine, or report database;
- a worker launcher, provider router, permission system, or command layer;
- worktree creation/cleanup or branch-history machinery;
- permanent roles beside current Paseo Agent Profiles;
- mandatory machine-readable worker results or orchestration manifests;
- the frontend browser gate or other project-specific QA utilities;
- host configuration mutation or promotion into `storage`.

If a proposed governance change recreates something Paseo owns, reject it. If it
only preserves obsolete implementation history, keep it as provenance rather
than active policy.
