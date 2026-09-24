# Bootstrap V1 Final Implementation Report

Date: 2026-09-24  
Repository: `khoawatt/paseo-workflow`  
Host: WSL2 Ubuntu, sanitized  
Paseo version: `0.9.1`

## Status

- Bootstrap status: `READY` — runtime-tested.
- Core smoke status: `PASS` — Preflight and A-G runtime-tested.
- Bootstrap V1 status: `OPERATIONALLY VALIDATED`.
- Scope: bootstrap/orchestration distribution only. This result does not claim
  project-runtime validation for any application repository.

## Implementation and fixture tests

- Ownership-aware config policy and reconciler: implemented and fixture-tested.
- WSL bootstrap installer: implemented and fixture-tested.
- Native host verifier: implemented, fixture-tested, and runtime-tested.
- Read-only project inspector: implemented and fixture-tested.
- Operator/bootstrap documentation: implemented and secret-scanned.
- Fixture suite: 98 assertions passed, zero failures.
- Secret safety: PASS; repository contains no credentials, live config backup,
  runtime agent/workspace/session IDs, or private auth state.
- Complete operational gate: PASS — Preflight, A-G, regression suite, live
  idempotency, and secret-safety checks all have observable evidence.

## Host policy

Runtime-tested PASS:

- native daemon MCP enabled and injected into new agents;
- `codex-lead` available with orchestration catalog;
- `codex-worker` available with `paseoTools.enabled = false`;
- `opencode-worker` available with `paseoTools.enabled = false`;
- Lead can create native workspaces and agents;
- both worker families retain normal repository capability and cannot create
  agents through the native Paseo catalog.

Required capability-class provider IDs already existed and were reconciled;
none required creation during the final live apply. The host-owned base
`opencode` provider command was updated to a dedicated compatibility binary.

## OpenCode runtime

Runtime-tested PASS:

- interactive OpenCode remained `2.0.15`;
- Paseo provider runtime uses checksum-verified OpenCode `1.18.31`;
- `opencode` and `opencode-worker` are available;
- provider diagnostic is Ready and model discovery succeeds;
- the existing terminal profile and worker tool policy were preserved.

The repair is documented in [OpenCode Runtime Repair
Evidence](2026-09-24-opencode-runtime-repair.md). It is a host/provider
compatibility override, not a new architecture component.

## Agent Profiles and skills

Runtime MCP discovery returned the five required profiles:

- Lead -> `codex-lead`;
- Planning / Research -> `codex-worker`;
- Implementation -> `opencode-worker`;
- Review -> `codex-worker`;
- Specialist -> `codex-worker`.

Planning and Review provider boundaries were reconciled while their existing
model, thinking, mode, and notes were preserved. Native skills `/paseo`,
`/paseo-handoff`, `/paseo-advisor`, and `/paseo-committee` are installed;
handoff/advisor/committee behavior was runtime-tested in smoke E.

## Backup, merge, and idempotency

- Candidate was inspected before live mutation.
- One mode-0600 timestamped backup was created before bootstrap config write.
- Merge changed only the two required profile provider fields and preserved
  credentials, unknown fields, unrelated config, profiles, providers, and user
  model/thinking preferences.
- Two immediate live reruns preserved the exact config SHA-256 and created no
  additional backup.
- Atomic rollback behavior is fixture-tested.

## Core smoke tests

| Gate | Result | Evidence class |
| --- | --- | --- |
| Preflight | PASS | runtime-tested |
| A - parallel read-only research | PASS | runtime-tested |
| B - isolated implementation worktree | PASS | runtime-tested |
| C - fresh independent review | PASS | runtime-tested |
| D - parallel implementation worktrees | PASS | runtime-tested |
| E - handoff, advisor, committee | PASS | runtime-tested |
| F - follow-up, redirect, cancel, archive | PASS | runtime-tested |
| G - runtime permission boundary | PASS | runtime-tested |

Detailed sanitized evidence is in [V0.2 Core Smoke Tests
A-G](2026-09-24-smoke-tests-a-g.md).

Post-validation cleanup removed only task-owned temporary fixture and
compatibility-test directories/files under `/tmp`. Live config backups and the
installed compatibility provider binary were retained for rollback.

## Observed Paseo gaps and mismatches

1. Paseo 0.9.1 public JSON schema omits `daemon.agentProfiles`, although the
   runtime consumes it and native MCP discovers profiles.
2. CLI has provider discovery but no equivalent profile-list command; real
   profile proof requires MCP.
3. Restricted OpenCode may expose a disabled Paseo tool name while invocation
   is denied; call-level validation is required.
4. Provider command reload can retain an initialized OpenCode server manager;
   one supervised daemon restart was required after explicit log evidence.
5. A restricted command sandbox blocks loopback sockets and can make an
   in-sandbox daemon health check fail while MCP remains live.
6. Completion attention/notifications can be duplicated or stale across
   follow-up turns; status and activity must be correlated.
7. No dedicated redirect primitive was observed. `send_agent_prompt` applied
   the corrective prompt to the running agent and preserved identity.
8. Codex usage and Gemini quota prevented the preferred committee provider
   diversity. Restricted OpenCode model-family diversity completed the test.
9. The approved architecture adjustment separates Bootstrap V1 validation from
   project-specific adoption. No application repository is required for the
   bootstrap gate; future project runtime is derived and validated locally.

## Architecture impact

No architecture change is required. No custom workflow controller, agent
runtime, provider router, scheduler, message bus, permission queue, or state
database was added. Observed failures were classified and handled as config,
runtime compatibility, validation-environment, or model/provider issues.

## Future adopter/project-runtime considerations

No project-runtime work remains for Bootstrap V1 itself. For each future
adopting repository:

- run `install-project.sh <repo>` against the real repository;
- derive any project runtime only from inspected scripts, services, ports, and
  environment;
- human-review proposed runtime configuration before writing it;
- perform project-specific task, service, permission, and cleanup validation
  locally in that repository.

## Next recommended action

Publish/review the Bootstrap V1 branch and tag the validated distribution when
ready. Future application repositories should adopt it through
`install-project.sh <repo>` and keep their project-specific validation local;
that work does not change Bootstrap V1's operational status.
