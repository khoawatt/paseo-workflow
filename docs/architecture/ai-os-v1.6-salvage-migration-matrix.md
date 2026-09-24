# AI OS v1.6 Salvage & Migration Matrix

> **Source audited:** `khoawatt/ai-os-v1.6` @ `main`
>
> **Audit date:** 2026-09-24
>
> **Current architecture baseline:** Design Agent Team V0.2 + native Paseo orchestration
>
> **Working location:** `khoawatt/paseo-workflow`
>
> **Promotion rule:** `storage` stays curated. Nothing from this audit is promoted to `storage` until the design is accepted, stable, and worth preserving as long-lived knowledge.
>
> **Purpose:** identify reusable knowledge/assets from AI OS v1.6 without reintroducing the custom orchestration/runtime layer that V0.2 intentionally removed.

## Executive decision

`ai-os-v1.6` should **not** return as an active runtime dependency.

Its remaining value is concentrated in the layer **above Paseo**:

- task-depth / governance selection;
- context loading discipline;
- verification and quality gates;
- human commitment boundaries;
- behavioral/adversarial evals;
- task/report contract vocabulary;
- feedback and debugging loops;
- a small number of reusable deterministic QA assets.

The migration rule is:

```text
Paseo-native orchestration/runtime
        stays canonical

AI OS governance knowledge
        may be salvaged selectively

Old custom runner/state/worktree machinery
        must not be revived
```

## Action vocabulary

| Action | Meaning |
|---|---|
| **EXTRACT** | Valuable enough to become a distinct reusable policy, skill, eval or deterministic utility. |
| **MERGE** | Valuable concepts exist and should be integrated into the current working architecture in `paseo-workflow`; any later promotion to `storage` requires a separate curated decision. |
| **ARCHIVE** | Keep as historical/provenance material only. No active dependency. |
| **DROP** | Do not migrate. The file primarily implements obsolete/duplicated runtime mechanics. |

Priority:

- **P0** — salvage first; materially improves the current system.
- **P1** — useful second wave.
- **P2** — historical/supporting value only.
- **-** — no migration.

## Audit summary

Total files audited: **157**

- EXTRACT: **16**
- MERGE: **55**
- ARCHIVE: **39**
- DROP: **47**

Priority distribution:

- P0: **18**
- P1: **51**
- P2: **41**
- no migration priority: **47**

## P0 salvage set

These are the items worth carrying forward before touching lower-priority material:

1. **Adaptive operating modes M0-M4** + mode/strategy separation.
2. **Progressive context loading** proportional to task/risk depth.
3. **Quality gates** and evidence-before-DONE discipline.
4. **Centralized human commitment / hard-approval vocabulary** from `agent-permissions.json`.
5. **Behavioral/adversarial agent evals** (HC14 pattern).
6. **Task brief / worker ticket contract fields**: scope, write boundary, forbidden actions, AC, verification, escalation.
7. **Feedback loop** that turns recurring failures/corrections into durable policy/skill/eval improvements.
8. **Frontend browser gate + tests** as a deterministic project QA asset.

## Explicit non-goals

Do **not** migrate or recreate:

- `run-cmdc-worker.sh` / `run-codex-worker.sh`;
- a custom agent launcher;
- custom worktree creation/cleanup orchestration;
- `orchestration-state.schema.json`;
- branch-history runtime/state machine;
- custom worker-status or retry engine;
- a second report database;
- custom permission queue;
- custom provider router;
- old `.commandcode` topology;
- a duplicate set of permanent roles beside Paseo Agent Profiles.

The current authority remains:

```text
Paseo
→ runtime lifecycle, delegation, messages, workspaces/worktrees,
  permissions, schedules, heartbeats, provider/profile discovery

Lead
→ engineering reasoning, task depth, decomposition, role selection,
  evidence interpretation, review/rework decisions

Git / GitHub
→ code provenance, PR/CI, durable engineering collaboration

Human
→ high-impact commitment decisions
```


## .codex / .commandcode / root

| Source file | Action | Priority | Target | Rationale |
|---|---|---:|---|---|
| `.codex/agents/aios_cmdc_builder.toml` | **DROP** | - | None | Legacy provider-specific builder contract; current roles are expressed through Paseo Profiles and worker prompts. |
| `.codex/agents/aios_explorer.toml` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md / paseo-delegation-playbook-v0.2.md | Extract any unique role constraints, evidence expectations, or integration checks; do not preserve these as a second agent-definition system. |
| `.codex/agents/aios_integrator.toml` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md / paseo-delegation-playbook-v0.2.md | Extract any unique role constraints, evidence expectations, or integration checks; do not preserve these as a second agent-definition system. |
| `.codex/agents/aios_planner.toml` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md / paseo-delegation-playbook-v0.2.md | Extract any unique role constraints, evidence expectations, or integration checks; do not preserve these as a second agent-definition system. |
| `.codex/agents/aios_reviewer.toml` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md / paseo-delegation-playbook-v0.2.md | Extract any unique role constraints, evidence expectations, or integration checks; do not preserve these as a second agent-definition system. |
| `.codex/agents/aios_tester.toml` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md / paseo-delegation-playbook-v0.2.md | Extract any unique role constraints, evidence expectations, or integration checks; do not preserve these as a second agent-definition system. |
| `.codex/config.toml` | **DROP** | - | None | Old-repo/runtime plumbing; not reusable in the Paseo-native architecture. |
| `.commandcode/agents/aios-cmdc-builder.md` | **DROP** | - | None | Command Code-specific agent/runtime layer is no longer part of the current Paseo-native topology. |
| `.commandcode/agents/aios-cmdc-explorer.md` | **DROP** | - | None | Command Code-specific agent/runtime layer is no longer part of the current Paseo-native topology. |
| `.commandcode/agents/aios-cmdc-verifier.md` | **DROP** | - | None | Command Code-specific agent/runtime layer is no longer part of the current Paseo-native topology. |
| `.env.example` | **DROP** | - | None | Old-repo/runtime plumbing; not reusable in the Paseo-native architecture. |
| `.gitignore` | **DROP** | - | None | Old-repo/runtime plumbing; not reusable in the Paseo-native architecture. |
| `AGENTS.md` | **ARCHIVE** | P2 | No active target | Entry-point/release documentation for the old harness; useful for provenance, but superseded by Design Agent Team V0.2 + paseo-workflow. |
| `AI_OS_v1.4_SOURCE_OF_TRUTH.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical reasoning | Preserve as historical evidence of the pre-Paseo AI OS design; do not use as active runtime authority. |
| `AI_OS_v1.6_SOURCE_OF_TRUTH.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical reasoning | Preserve as historical evidence of the pre-Paseo AI OS design; do not use as active runtime authority. |
| `index.html` | **DROP** | - | None | Old-repo/runtime plumbing; not reusable in the Paseo-native architecture. |

## Research and historical task records

| Source file | Action | Priority | Target | Rationale |
|---|---|---:|---|---|
| `docs/research/harness-core-benchmark-gap-analysis.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `docs/research/harness-ecc-analysis.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `docs/research/harness-four-way-comparison.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `docs/research/harness-gsd-core-analysis.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `docs/research/harness-repository-harness-analysis.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `docs/research/harness-superpowers-analysis.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `docs/research/harness-superpowers-vs-repository-harness-comparison.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `docs/tasks/aios-v1.6-workflow-refactor-plan.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Implementation history/release notes are provenance, not reusable active architecture. |
| `docs/tasks/harness-core-integration-roadmap.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Implementation history/release notes are provenance, not reusable active architecture. |
| `harness-core/docs/research/2026-06-17-pdf-source-summary.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `harness-core/docs/research/README.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `harness-core/docs/research/local-verification/command-code-worker-local-verification.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Benchmark/research history may explain earlier choices, but should not become active runtime policy. |
| `harness-core/docs/tasks/README.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Implementation history/release notes are provenance, not reusable active architecture. |
| `harness-core/docs/tasks/ai-os-workflow-hardening-20260703.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Implementation history/release notes are provenance, not reusable active architecture. |
| `harness-core/docs/tasks/harness-core-docs-first-release-note.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Implementation history/release notes are provenance, not reusable active architecture. |
| `harness-core/docs/tasks/harness-core-docs-first-review.md` | **ARCHIVE** | P2 | how-to-design-agent-team historical references | Implementation history/release notes are provenance, not reusable active architecture. |

## Harness docs: agents, commands, skills, runbooks, schemas, templates, tools

| Source file | Action | Priority | Target | Rationale |
|---|---|---:|---|---|
| `harness-core/docs/AI_AGENT_CODING_OS.md` | **MERGE** | P1 | ai-agent/architecture/ai-operating-systems.md | Use as a gap-check source; merge only principles missing from the broader AI operating systems reference. |
| `harness-core/docs/README.md` | **ARCHIVE** | P2 | No active target | Entry-point/release documentation for the old harness; useful for provenance, but superseded by Design Agent Team V0.2 + paseo-workflow. |
| `harness-core/docs/decisions/README.md` | **ARCHIVE** | P2 | Review only if future need appears | No strong current migration case; preserve source repository as historical reference. |
| `harness-core/docs/evals/HC14-EVAL-001-read-source-of-truth.md` | **EXTRACT** | P0 | paseo-orchestration-smoke-tests-v0.2.md + future behavioral-eval spec | High-value adversarial behavior tests: source-of-truth adherence, write-scope discipline, and verify-before-done should become repeatable agent-policy evals. |
| `harness-core/docs/evals/HC14-EVAL-002-respect-write-allowlist.md` | **EXTRACT** | P0 | paseo-orchestration-smoke-tests-v0.2.md + future behavioral-eval spec | High-value adversarial behavior tests: source-of-truth adherence, write-scope discipline, and verify-before-done should become repeatable agent-policy evals. |
| `harness-core/docs/evals/HC14-EVAL-003-verify-before-completion.md` | **EXTRACT** | P0 | paseo-orchestration-smoke-tests-v0.2.md + future behavioral-eval spec | High-value adversarial behavior tests: source-of-truth adherence, write-scope discipline, and verify-before-done should become repeatable agent-policy evals. |
| `harness-core/docs/evals/HC14-EVAL-results-20260630.md` | **EXTRACT** | P0 | paseo-orchestration-smoke-tests-v0.2.md + future behavioral-eval spec | High-value adversarial behavior tests: source-of-truth adherence, write-scope discipline, and verify-before-done should become repeatable agent-policy evals. |
| `harness-core/docs/evals/README.md` | **MERGE** | P1 | new behavioral-eval section/spec | Keep the eval methodology/navigation, but consolidate rather than copy the old harness layout. |
| `harness-core/docs/harness/README.md` | **ARCHIVE** | P2 | No active target | Old harness directory map; concepts are handled by current architecture/harness docs. |
| `harness-core/docs/harness/agents/builder.md` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md | Compare for missing role obligations only; current five Paseo Profiles remain canonical and Integration stays a temporary role. |
| `harness-core/docs/harness/agents/explorer.md` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md | Compare for missing role obligations only; current five Paseo Profiles remain canonical and Integration stays a temporary role. |
| `harness-core/docs/harness/agents/integrator.md` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md | Compare for missing role obligations only; current five Paseo Profiles remain canonical and Integration stays a temporary role. |
| `harness-core/docs/harness/agents/memory-curator.md` | **MERGE** | P1 | ai-agent/context-engineering/memory.md | Memory-curation behavior belongs to context engineering, not a permanent runtime role by default. |
| `harness-core/docs/harness/agents/orchestrator.md` | **MERGE** | P1 | paseo-delegation-playbook-v0.2.md | Keep fan-out gate, scope assignment, validation, escalation and reconciliation principles; Paseo remains runtime and Lead remains technical orchestrator. |
| `harness-core/docs/harness/agents/planner.md` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md | Compare for missing role obligations only; current five Paseo Profiles remain canonical and Integration stays a temporary role. |
| `harness-core/docs/harness/agents/reviewer.md` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md | Compare for missing role obligations only; current five Paseo Profiles remain canonical and Integration stays a temporary role. |
| `harness-core/docs/harness/agents/tester.md` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md | Compare for missing role obligations only; current five Paseo Profiles remain canonical and Integration stays a temporary role. |
| `harness-core/docs/harness/commands/check.md` | **MERGE** | P1 | agentic-engineering.md / delegation playbook | Keep minimal plan/verification discipline where it adds clarity; avoid another command layer. |
| `harness-core/docs/harness/commands/cleanup-worktrees.md` | **DROP** | - | None | Old custom orchestration command surface duplicates native Paseo lifecycle/worktree/delegation primitives. |
| `harness-core/docs/harness/commands/collect-results.md` | **DROP** | - | None | Old custom orchestration command surface duplicates native Paseo lifecycle/worktree/delegation primitives. |
| `harness-core/docs/harness/commands/execute.md` | **DROP** | - | None | Old custom orchestration command surface duplicates native Paseo lifecycle/worktree/delegation primitives. |
| `harness-core/docs/harness/commands/fanout-plan.md` | **DROP** | - | None | Old custom orchestration command surface duplicates native Paseo lifecycle/worktree/delegation primitives. |
| `harness-core/docs/harness/commands/integrate-workers.md` | **DROP** | - | None | Old custom orchestration command surface duplicates native Paseo lifecycle/worktree/delegation primitives. |
| `harness-core/docs/harness/commands/plan.md` | **MERGE** | P1 | agentic-engineering.md / delegation playbook | Keep minimal plan/verification discipline where it adds clarity; avoid another command layer. |
| `harness-core/docs/harness/commands/review.md` | **MERGE** | P1 | paseo-report-contract-v0.2.md / Review profile | Keep review evidence/decision semantics only; use native Paseo fresh Reviewer sessions. |
| `harness-core/docs/harness/commands/select-mode.md` | **MERGE** | P0 | new operating-modes policy + paseo-delegation-playbook-v0.2.md | Adaptive task-depth selection is valuable; implement as Lead policy, not a custom command runtime. |
| `harness-core/docs/harness/commands/ship.md` | **DROP** | - | None | Old custom orchestration command surface duplicates native Paseo lifecycle/worktree/delegation primitives. |
| `harness-core/docs/harness/commands/spawn-worker.md` | **DROP** | - | None | Old custom orchestration command surface duplicates native Paseo lifecycle/worktree/delegation primitives. |
| `harness-core/docs/harness/commands/worker-status.md` | **DROP** | - | None | Old custom orchestration command surface duplicates native Paseo lifecycle/worktree/delegation primitives. |
| `harness-core/docs/harness/skills/brainstorm/SKILL.md` | **MERGE** | P1 | ai-agent/methodologies/superpowers.md + ai-agent/harness/agent-skills.md | Useful methodology, but substantially overlaps Superpowers; consolidate instead of creating duplicate skills. |
| `harness-core/docs/harness/skills/component-packaging/SKILL.md` | **EXTRACT** | P1 | ai-agent/harness reusable skill candidate | Distinct reusable design-system extraction procedure; strong fit for Design Agent Team. |
| `harness-core/docs/harness/skills/finish-branch/SKILL.md` | **MERGE** | P1 | ai-agent/methodologies/superpowers.md + ai-agent/harness/agent-skills.md | Useful methodology, but substantially overlaps Superpowers; consolidate instead of creating duplicate skills. |
| `harness-core/docs/harness/skills/review/SKILL.md` | **MERGE** | P1 | ai-agent/methodologies/superpowers.md + ai-agent/harness/agent-skills.md | Useful methodology, but substantially overlaps Superpowers; consolidate instead of creating duplicate skills. |
| `harness-core/docs/harness/skills/task-breakdown/SKILL.md` | **MERGE** | P1 | ai-agent/methodologies/superpowers.md + ai-agent/harness/agent-skills.md | Useful methodology, but substantially overlaps Superpowers; consolidate instead of creating duplicate skills. |
| `harness-core/docs/harness/skills/tdd/SKILL.md` | **MERGE** | P1 | ai-agent/methodologies/superpowers.md + ai-agent/harness/agent-skills.md | Useful methodology, but substantially overlaps Superpowers; consolidate instead of creating duplicate skills. |
| `harness-core/docs/runbooks/README.md` | **ARCHIVE** | P2 | No active target | Old runbook index. |
| `harness-core/docs/runbooks/agent-harness.md` | **MERGE** | P1 | ai-agent/harness/agent-skills.md + how-to-design-agent-team | Useful harness mental model; avoid recreating the old harness directory/runtime. |
| `harness-core/docs/runbooks/ai-debugging.md` | **EXTRACT** | P1 | ai-agent/methodologies or workflow debugging guide | Layered failure classification is reusable across agent systems and complements Paseo failure classes. |
| `harness-core/docs/runbooks/always-on-agents.md` | **MERGE** | P2 | paseo-orchestration-design-v0.2.md schedules/heartbeats/resident-role guidance | Keep only criteria for resident/recurring roles; Paseo Schedule/Heartbeat already owns execution. |
| `harness-core/docs/runbooks/component-style-packaging.md` | **EXTRACT** | P1 | ai-agent/harness reusable component-packaging skill/reference | Reusable design-system packaging guidance; independent of old orchestration. |
| `harness-core/docs/runbooks/content-automation.md` | **ARCHIVE** | P2 | Optional future workflow knowledge | Generic content workflow is not central to current Design Agent Team/Paseo engineering architecture. |
| `harness-core/docs/runbooks/cost-context-latency.md` | **MERGE** | P0 | ai-agent/context-engineering/memory.md + agent-team governance | Progressive context loading and context hygiene directly improve multi-agent cost/latency/reliability. |
| `harness-core/docs/runbooks/feedback-loop.md` | **EXTRACT** | P0 | new governance feedback/eval section | System-level learning loop turns recurring failures/corrections into runbook, skill, eval or policy improvements. |
| `harness-core/docs/runbooks/frontend-browser-verification.md` | **EXTRACT** | P1 | paseo-project-runtime-contract-v0.2.md / future fea-lms-rfbe QA | Reusable browser evidence policy belongs to project verification, not Paseo orchestration. |
| `harness-core/docs/runbooks/git-worktree-orchestration.md` | **MERGE** | P1 | paseo-delegation-playbook-v0.2.md | Keep dirty-state protection, write ownership and crash-recovery principles; drop custom worktree creation/cleanup commands. |
| `harness-core/docs/runbooks/integration-and-conflicts.md` | **MERGE** | P1 | paseo-delegation-playbook-v0.2.md + GitHub role reasoning | Conflict ownership, overlap checks, final combined verification and rollback rules remain useful. |
| `harness-core/docs/runbooks/large-feature-profile.md` | **MERGE** | P1 | agentic-engineering.md / superpowers.md + operating-modes policy | Spec-plan-execute-verify-handoff is useful, but should remain methodology rather than a new Paseo profile. |
| `harness-core/docs/runbooks/minimum-adoption-pack.md` | **ARCHIVE** | P2 | paseo-workflow bootstrap is canonical | Old harness adoption pack is superseded by the reproducible Paseo bootstrap. |
| `harness-core/docs/runbooks/multi-agent-orchestration.md` | **MERGE** | P1 | paseo-delegation-playbook-v0.2.md | Fan-out gate and supervisor responsibilities are useful; native Paseo handles runtime mechanics. |
| `harness-core/docs/runbooks/observability.md` | **MERGE** | P1 | paseo-report-contract-v0.2.md + smoke-test evidence rules | Keep replay/evidence bundle principles while sourcing identity/state from Paseo, Git and GitHub instead of mirrored runtime state. |
| `harness-core/docs/runbooks/operating-modes.md` | **EXTRACT** | P0 | new agent-team operating-modes policy | M0-M4 plus mode-versus-strategy and progressive context loading are the strongest reusable governance concepts. |
| `harness-core/docs/runbooks/persistent-workflows.md` | **MERGE** | P1 | paseo-orchestration-design-v0.2.md SDK/lifecycle sections | Keep checkpoint/resume principles only; do not restore a parallel orchestration-state database. |
| `harness-core/docs/runbooks/provider-portability.md` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md / host policy | Keep capability-over-brand and adapter-boundary thinking; Paseo provider discovery remains authoritative. |
| `harness-core/docs/runbooks/quality-gates.md` | **MERGE** | P0 | paseo-delegation-playbook-v0.2.md + project runtime verification policy | Keep evidence-before-DONE, orchestration exit gates, and frontend verification distinctions. |
| `harness-core/docs/runbooks/retrieval-memory.md` | **MERGE** | P1 | ai-agent/context-engineering/memory.md | Good retrieval priority and stale-memory handling; consolidate into existing memory reference. |
| `harness-core/docs/runbooks/safety-integrations.md` | **MERGE** | P0 | paseo-host-policy-v0.2.md / human commitment boundary | Centralize trust boundaries, high-impact actions, dependency legitimacy and least-privilege guidance without rebuilding permissions. |
| `harness-core/docs/runbooks/standard-agent-flow.md` | **ARCHIVE** | P2 | Current V0.2 execution brief/delegation playbook | Onboarding flow is tightly coupled to old Codex+cmdc harness and has been superseded. |
| `harness-core/docs/runbooks/tool-registry.md` | **MERGE** | P1 | paseo-host-policy-v0.2.md + tooling docs | Access-level/trust-boundary vocabulary is useful; provider/runtime capabilities should still come from Paseo and native provider settings. |
| `harness-core/docs/runbooks/worker-execution.md` | **DROP** | - | None | Worker wrapper/runtime mechanics duplicate native Paseo agent lifecycle and provider execution. |
| `harness-core/docs/schemas/branch-history-export.schema.json` | **DROP** | - | None | Branch-history/export schemas belong to the obsolete custom evidence lifecycle. |
| `harness-core/docs/schemas/branch-history.schema.json` | **DROP** | - | None | Branch-history/export schemas belong to the obsolete custom evidence lifecycle. |
| `harness-core/docs/schemas/orchestration-state.schema.json` | **DROP** | - | None | Would mirror Paseo runtime state and reintroduce a second workflow state machine. |
| `harness-core/docs/schemas/worker-result.schema.json` | **MERGE** | P1 | paseo-report-contract-v0.2.md | Retain compact vocabulary and validation lessons; do not require universal worker-result JSON unless a machine consumer needs outputSchema. |
| `harness-core/docs/templates/adr.md` | **ARCHIVE** | P2 | Existing architecture docs | Generic ADR stub is too thin to justify migration. |
| `harness-core/docs/templates/agent-prompt.md` | **MERGE** | P1 | ai-agent/harness/agent-skills.md / agent-team design framework | Keep role/objective/scope/tools/output/escalation contract elements. |
| `harness-core/docs/templates/agent-role.md` | **MERGE** | P1 | paseo-agent-profiles-v0.2.md | Role-contract vocabulary only; Profiles remain canonical. |
| `harness-core/docs/templates/code-review.md` | **MERGE** | P1 | paseo-report-contract-v0.2.md / Review profile | Keep evidence/severity/action structure if not already covered. |
| `harness-core/docs/templates/command.md` | **ARCHIVE** | P2 | No active target | Generic old template; migrate only if a current workflow demonstrates a need. |
| `harness-core/docs/templates/component-pattern.md` | **EXTRACT** | P1 | component-packaging skill/reference | Useful companion template for reusable design patterns. |
| `harness-core/docs/templates/debug-report.md` | **MERGE** | P1 | future AI debugging guide | Useful evidence shape for repeatable failure analysis. |
| `harness-core/docs/templates/eval-case.md` | **EXTRACT** | P0 | future behavioral-eval spec/templates | Small reusable template for regression/adversarial agent behavior tests. |
| `harness-core/docs/templates/feedback-log.md` | **MERGE** | P1 | future feedback/eval loop | Small learning record pattern; can be represented in existing docs/issues instead of copied verbatim. |
| `harness-core/docs/templates/frontend-browser-scenario.json` | **EXTRACT** | P1 | future project QA utility | Companion scenario format for frontend browser verification. |
| `harness-core/docs/templates/goal-follow-up.md` | **MERGE** | P2 | delegation playbook | Follow-up/checkpoint concepts can use send_agent_prompt and native session continuity. |
| `harness-core/docs/templates/handoff.md` | **MERGE** | P1 | paseo-report-contract-v0.2.md | Useful compact completion/handoff checklist; consolidate into current report contract. |
| `harness-core/docs/templates/memory-entry.md` | **ARCHIVE** | P2 | ai-agent/context-engineering/memory.md | Memory abstraction exists already; do not proliferate storage formats. |
| `harness-core/docs/templates/mode-assessment.md` | **MERGE** | P0 | new operating-modes policy | Compact mode/strategy/rationale record is directly reusable. |
| `harness-core/docs/templates/observability-note.md` | **MERGE** | P1 | report/evidence guidance | Keep minimal replay/evidence fields, not a separate mandatory file. |
| `harness-core/docs/templates/orchestration-manifest.md` | **DROP** | - | None | Duplicates Paseo agent/workspace lifecycle and would create parallel orchestration state. |
| `harness-core/docs/templates/research-note.md` | **ARCHIVE** | P2 | Existing storage research conventions | Generic template adds little beyond current Markdown practice. |
| `harness-core/docs/templates/safety-review.md` | **MERGE** | P1 | paseo-host-policy-v0.2.md / task risk assessment | Useful checklist, but avoid another independent template set unless actively used. |
| `harness-core/docs/templates/skill.md` | **ARCHIVE** | P2 | ai-agent/harness/agent-skills.md | Existing Agent Skills document is much more complete. |
| `harness-core/docs/templates/task-brief.md` | **MERGE** | P0 | paseo-delegation-playbook-v0.2.md | Extract goal/scope/out-of-scope/acceptance/constraints/verification/dependency-risk fields into the worker task contract. |
| `harness-core/docs/templates/tool-contract.md` | **MERGE** | P1 | tooling/host-policy guidance | Tool input/output/side-effect/approval contract is useful. |
| `harness-core/docs/templates/trace-companion.md` | **DROP** | - | None | Exists to mirror custom worker-result JSON; unnecessary with current provenance rules. |
| `harness-core/docs/templates/worker-handoff.md` | **MERGE** | P1 | paseo-report-contract-v0.2.md | Keep active-responsibility handoff fields; prefer native /paseo-handoff. |
| `harness-core/docs/templates/worker-result.v1.2.template.json` | **MERGE** | P1 | paseo-report-contract-v0.2.md | Keep status/changes/verification/risks/blockers/next-action vocabulary; source provenance from Paseo/Git/GitHub. |
| `harness-core/docs/templates/worker-ticket-lite.md` | **MERGE** | P0 | paseo-delegation-playbook-v0.2.md | Use as the low-overhead task-contract inspiration for small delegated slices. |
| `harness-core/docs/templates/worker-ticket.md` | **MERGE** | P0 | paseo-delegation-playbook-v0.2.md | Extract read/write scope, forbidden actions, acceptance, verification and escalation fields; Paseo remains worker launcher. |
| `harness-core/docs/tools/agy-worker.md` | **ARCHIVE** | P2 | Paseo/provider docs are canonical | Old local provider-runner records are tied to custom wrappers and stale capability verification. |
| `harness-core/docs/tools/codex-worker.md` | **ARCHIVE** | P2 | Paseo/provider docs are canonical | Old local provider-runner records are tied to custom wrappers and stale capability verification. |
| `harness-core/docs/tools/command-code-worker.md` | **ARCHIVE** | P2 | Paseo/provider docs are canonical | Old local provider-runner records are tied to custom wrappers and stale capability verification. |

## Policies, config and runtime scripts

| Source file | Action | Priority | Target | Rationale |
|---|---|---:|---|---|
| `harness-core/config/cmdc-runtime.json` | **DROP** | - | None | Old-repo/runtime plumbing; not reusable in the Paseo-native architecture. |
| `harness-core/policies/agent-permissions.json` | **EXTRACT** | P0 | paseo-host-policy-v0.2.md + centralized human commitment policy | High-value hard-approval vocabulary. Reuse as policy semantics; Paseo/provider-native permissions remain the enforcement mechanism. |
| `harness-core/scripts/agents/append-branch-event.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/archive-run.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/capture-git-state.py` | **ARCHIVE** | P2 | Git provenance principles already in report contract | Possible reference implementation, but current architecture should query Git directly rather than mirror state. |
| `harness-core/scripts/agents/cleanup-branch-history.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/cleanup-worktree.sh` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/collect-worker-review.py` | **ARCHIVE** | P2 | Review/report semantics only | Parser is coupled to old result contracts; preserve only as reference if implementing a future machine consumer. |
| `harness-core/scripts/agents/create-worktree.sh` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/examples/mock-worker.sh` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/export-branch-history.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/init-branch-history.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/integrate-worker.sh` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/lib/common.sh` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/preflight-cmdc.sh` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/run-cmdc-worker.sh` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/run-codex-worker.sh` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/status.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/tests/provider-dry-run-test.py` | **DROP** | - | None | Tests target obsolete custom runner/state/worktree machinery. |
| `harness-core/scripts/agents/tests/smoke-test.sh` | **DROP** | - | None | Tests target obsolete custom runner/state/worktree machinery. |
| `harness-core/scripts/agents/tests/test-archive-run.py` | **DROP** | - | None | Tests target obsolete custom runner/state/worktree machinery. |
| `harness-core/scripts/agents/tests/test-branch-history-lifecycle.py` | **DROP** | - | None | Tests target obsolete custom runner/state/worktree machinery. |
| `harness-core/scripts/agents/tests/test-capture-git-state.py` | **DROP** | - | None | Tests target obsolete custom runner/state/worktree machinery. |
| `harness-core/scripts/agents/tests/test-collect-worker-review.py` | **DROP** | - | None | Tests target obsolete custom runner/state/worktree machinery. |
| `harness-core/scripts/agents/validate-branch-history-export.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/validate-branch-history.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/validate-orchestration-state.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/agents/validate-worker-result.py` | **DROP** | - | None | Custom worker/worktree/branch-history/validation runtime duplicates Paseo-native orchestration or obsolete cmdc execution. |
| `harness-core/scripts/quality/frontend-browser-gate.mjs` | **EXTRACT** | P0 | future fea-lms-rfbe/project QA utility | Concrete deterministic asset with independent value: Playwright scenarios, runtime errors, overflow, dialog visibility and screenshots. |
| `harness-core/scripts/quality/tests/test-frontend-browser-gate.py` | **EXTRACT** | P0 | future fea-lms-rfbe/project QA utility | Keep together with the browser gate as regression coverage. |

## Harness entrypoints

| Source file | Action | Priority | Target | Rationale |
|---|---|---:|---|---|
| `harness-core/AGENTS.md` | **ARCHIVE** | P2 | No active target | Entry-point/release documentation for the old harness; useful for provenance, but superseded by Design Agent Team V0.2 + paseo-workflow. |
| `harness-core/README.md` | **ARCHIVE** | P2 | No active target | Entry-point/release documentation for the old harness; useful for provenance, but superseded by Design Agent Team V0.2 + paseo-workflow. |
| `harness-core/VERSION.md` | **ARCHIVE** | P2 | No active target | Entry-point/release documentation for the old harness; useful for provenance, but superseded by Design Agent Team V0.2 + paseo-workflow. |


## Recommended migration order

### Phase 1 — Governance, no runtime code

Create/merge the P0 governance concepts:

- operating modes M0-M4;
- progressive context loading;
- hard-approval / human commitment classes;
- task contract additions;
- quality gates;
- behavioral eval methodology;
- feedback loop.

**Constraint:** this phase must not introduce a new controller, runtime state, queue, worker launcher or worktree manager.

### Phase 2 — Reusable skills and methodology

Consolidate:

- component packaging;
- debugging/failure analysis;
- review/task-breakdown/TDD only where they add something not already covered by Superpowers;
- provider portability and context hygiene.

During active design work, adapt these ideas inside `paseo-workflow` first. Only after they are accepted and stable should selected long-lived knowledge be promoted into the appropriate `storage/ai-agent` documents.

### Phase 3 — Deterministic project QA

Salvage the frontend browser gate and its tests into the adopting project only when a real frontend project exists and the project runtime contract can define the command safely.

For the planned LMS rebuild, the likely future shape is:

```text
Paseo project script: verify
  → lint
  → typecheck
  → tests
  → build
  → browser gate when user-visible interaction changed
```

Do not make this browser utility a Paseo orchestration responsibility.

### Phase 4 — Archive, then freeze AI OS

After migrated concepts have been reviewed and the working Paseo design is stable:

1. mark `ai-os-v1.6` historical/frozen;
2. keep the repository available as provenance;
3. stop maintaining its runtime;
4. keep active design artifacts in `paseo-workflow`;
5. promote only accepted, durable knowledge into `storage` through a separate curated PR;
6. do not delete the source repository until all desired P0/P1 knowledge has a reviewed destination.

## Architectural acceptance test for every salvage change

For each proposed migration, ask:

```text
Does this improve how Lead decides, scopes, verifies, evaluates or governs work?
→ candidate to keep

Does this recreate something Paseo already owns?
→ reject

Does this only preserve old implementation history?
→ archive

Is there a deterministic utility with independent project value?
→ extract into the project/tooling layer, not orchestration
```

This prevents “salvage” from becoming a backdoor restoration of the old AI OS runtime.
