# Paseo Workflow Agent Guide

This repository is the reproducible bootstrap distribution for Design Agent
Team V0.2. It does not define a new orchestration architecture.

## Authority

Use this order whenever sources disagree:

1. Actual current Paseo runtime behavior.
2. Current official Paseo documentation.
3. [V0.2 execution brief](https://github.com/khoawatt/storage/blob/main/ai-agent/architecture/paseo-codex-execution-brief-v0.2.md).
4. V0.2 architecture/specification files referenced by that brief, including
   [Agent Profiles](https://github.com/khoawatt/storage/blob/main/ai-agent/architecture/paseo-agent-profiles-v0.2.md)
   and [smoke tests](https://github.com/khoawatt/storage/blob/main/ai-agent/architecture/paseo-orchestration-smoke-tests-v0.2.md).
5. [Accepted Bootstrap V1 specification](docs/specs/2026-09-24-paseo-workflow-bootstrap-v1.md).
6. This operational guide.

When runtime/docs differ, record the evidence and use the smallest compatible
Paseo-native adjustment. Do not build a custom controller to hide a CONFIG or
PROMPT/POLICY problem.

## Ownership boundary

- Paseo owns agent lifecycle, delegation, handoff, advisor, committee,
  workspaces/worktrees, messages, permissions, schedules, heartbeats, provider
  discovery, Profiles, and runtime state.
- This repository owns the three required provider capability classes, owned
  profile routing/notes, MCP injection settings, native skill presence, safe
  merge rules, bootstrap verification, and sanitized evidence.
- The human owns credentials, authentication, model/thinking preferences,
  unrelated providers/profiles/config, and all high-impact approvals.

Never commit live config, backups, credentials, auth state, agent/workspace/
session IDs, cookies, private keys, or unsanitized runtime records.

## Supported bootstrap target

V1 supports WSL2 Ubuntu with Bash, `apt`, Node.js/npm, and Paseo. macOS and
native Linux are intentionally out of scope.

From a fresh clone:

```bash
bash install.sh --dry-run
bash install.sh
bash verify.sh
```

Authentication is human-controlled. If the result is `AUTH_REQUIRED`, follow
the provider's native login flow, then rerun `bash verify.sh`. Never collect or
write credentials into this repository.

## Capability classes and Profiles

Provider ID plus `paseoTools` defines a Paseo tool-capability boundary:

- `codex-lead`: Lead-capable; receives Paseo orchestration tools.
- `codex-worker`: Codex worker; `paseoTools.enabled=false`.
- `opencode-worker`: OpenCode worker; `paseoTools.enabled=false`.

This is not a hard host security sandbox. Provider-native filesystem, network,
and command permissions remain separate, and high-impact actions remain
human-gated.

Required Profiles:

- Lead → `codex-lead`.
- Planning / Research → `opencode-worker`, with restricted fallback.
- Implementation → `codex-worker`, with restricted fallback.
- Review → a fresh restricted session, preferring provider/model diversity
  from Implementation when practical.
- Specialist → a domain-appropriate restricted provider/model.

Profile means role launch preset; provider ID means runtime capability class.
Model strength never grants orchestration authority. Selection precedence is:
explicit human request, existing user preference, profile default, then Lead
selection. Preserve model/thinking preferences when compatible; otherwise
report `MODEL/PROVIDER GAP` instead of silently widening authority.

## Safe configuration workflow

`install.sh` inspects before mutation, builds and natively validates a candidate,
and performs an ownership-aware merge. A changed config is copied to
`~/.paseo/config.json.backup-bootstrap-<UTC>` with mode 0600. The candidate is
written with a same-directory atomic rename, the live daemon is reloaded, and
verification runs immediately. A reload or `BLOCKED` final verification restores
the exact backup atomically. A no-op rerun creates no backup.

Do not remove unrelated providers/profiles, overwrite credentials, downgrade a
newer Paseo, merge a canonical branch, delete workspaces/worktrees, or accept a
broader-than-expected host diff without human approval.

## Verification and evidence

```bash
bash tests/test.sh          # repository fixture tests only
bash verify.sh --json      # selected live host, structural/runtime checks
```

Keep these evidence labels distinct: `implemented`, `fixture-tested`,
`runtime-tested`, and `not tested / blocked`. Fixture tests never prove live
provider auth, MCP profile discovery, capability calls, worktree isolation, or
permission behavior.

Before smoke Test A, prove with newly launched real agents that Lead can invoke
the expected orchestration capabilities and both workers cannot successfully
invoke `create_agent`, while retaining normal role capability. Catalog presence
alone is insufficient on Paseo 0.9.1.

Then run in order: Preflight; A fan-out research; B isolated implementation;
C implementation plus fresh review; D parallel implementation worktrees; E
native handoff/advisor/committee; F follow-up/redirect/cancel/archive; G runtime
permission boundary. The Bootstrap V1 operational-validation gate also requires
the repository regression suite, live idempotency, and secret-safety checks.
Only observable PASS evidence for the complete gate permits the label
`OPERATIONALLY VALIDATED`, and that label applies only to this bootstrap and
orchestration distribution.

## Project runtime

Run `bash install-project.sh <repo>`. V1 never writes `paseo.json`. It returns
`PROJECT_RUNTIME_READY`, `PROJECT_RUNTIME_PENDING`, or `BLOCKED` based on the
actual repository. Human-review any proposed setup, teardown, service, command,
and port before adding project runtime configuration. Project-specific
validation stays local to the adopting repository and is not a prerequisite for
Bootstrap V1 operational validation.

## Known Paseo 0.9.1 differences

- Local supervisor status can report stopped while the configured loopback
  daemon and injected MCP are live; topology detection checks both.
- The public config schema omits `daemon.agentProfiles`, although the runtime
  consumes it and MCP discovers Profiles.
- CLI provider discovery exists, but Profile discovery requires MCP.
- A disabled OpenCode Paseo tool can remain catalog-visible while invocation is
  denied; validate the call.
- Paseo/OpenCode protocol incompatibility may require a separately named,
  checksum-verified provider binary while preserving interactive OpenCode 2.x;
  follow [OpenCode Provider Compatibility](docs/OPENCODE_COMPATIBILITY.md).
- Codex exposes no read-only mode on the inspected host; worker provider policy,
  role contract, and provider-native approvals/sandbox remain separate controls.

For failures, use only: `CONFIG`, `PROMPT/POLICY`, `PASEO GAP`, `PROJECT GAP`,
`MODEL/PROVIDER GAP`, or `ARCHITECTURE GAP`. Follow
[Troubleshooting](docs/TROUBLESHOOTING.md) and stop if an architecture change,
destructive/high-impact action, or serious runtime blocker is required.
