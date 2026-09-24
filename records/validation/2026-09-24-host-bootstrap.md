# Host Bootstrap and Capability Boundary Evidence

Date: 2026-09-24  
Host: WSL2 Ubuntu, sanitized  
Bootstrap status: `READY`  
Architecture status: `DESIGN COMPLETE / OPERATIONAL VALIDATION PENDING`

## Implementation and fixture evidence

- Ownership-aware merge, installer, verifier, project inspection, policy, and
  secret-safety behavior are implemented.
- Repository fixture suite: 98 assertions passed, zero failures.
- Fixture coverage includes unknown fields, unrelated providers and profiles,
  credential-shaped fields, user model/thinking preferences, atomic rollback,
  backup behavior, idempotency, invalid policy, unavailable models, and status
  reporting.
- Fixture evidence uses synthetic homes and fake runtime responses. It is not
  counted as real-host orchestration proof.

## Real-host bootstrap

- Paseo CLI/daemon: `0.9.1`.
- `install.sh --dry-run`: passed before live apply.
- Live apply created one mode-0600 timestamped backup. Backup SHA-256:
  `fbd9689e61fff64073bd9e3c7f70d83d96696fcbc48f0ad996460a6337d9d873`.
- The ownership-aware candidate changed only the provider fields for
  `Planning / Research` and `Review`, from unrestricted `codex` to restricted
  `codex-worker`.
- Their existing `gpt-5.6-sol` model, `high` thinking option, mode, notes, and
  unrelated profile/config fields were preserved.
- Native reload and verification completed with `READY`.

The required capability-class provider IDs are available:

- `codex-lead`;
- `codex-worker`, with `paseoTools.enabled = false`;
- `opencode-worker`, with `paseoTools.enabled = false`.

No required capability-class provider ID needed to be newly created during the
live apply. The base `opencode` provider required a host-owned executable
override; see [OpenCode Runtime Repair
Evidence](2026-09-24-opencode-runtime-repair.md).

## Profiles and native skills

Native MCP discovery returned exactly the five required profiles:

- Lead: `codex-lead`;
- Planning / Research: `codex-worker`;
- Implementation: `opencode-worker`;
- Review: `codex-worker`;
- Specialist: `codex-worker`.

Model, thinking, mode, and feature preferences remained user-owned where
compatible. The four native skills `/paseo`, `/paseo-handoff`,
`/paseo-committee`, and `/paseo-advisor` are installed and discoverable. Their
behavior remains part of smoke test E rather than this bootstrap gate.

## Real-host idempotency

Two immediate reruns converged without another write or backup:

- config SHA-256 before and after both reruns:
  `7e5a34207625961630b1d47bc45832892b8779db5c2e8e88422f945ff491c855`;
- bootstrap backup count before and after: one;
- final status on both reruns: `READY`.

## Capability boundary

The prerequisite boundary was exercised through fresh real agents after reload:

- Lead read the repository, listed profiles, created a native workspace, and
  created a restricted child agent. The child completed a read-only task.
- Codex worker read the repository with normal coding tools. Its injected native
  catalog contained no `create_agent` capability.
- OpenCode worker read the repository with normal worker tools. Calling the
  catalog-visible disabled `create_agent` operation was denied by the runtime
  with `Paseo tools are disabled for this session`.
- All probes reported no repository mutation.
- Both test-owned workspaces and all four test agents were archived after
  evidence collection; no directory was removed.

Result: `PASS`. This proves the Paseo tool-capability boundary at call level; it
does not claim a hard host security sandbox.

## Remaining gates

- Official V0.2 smoke tests A-G: not yet executed for this bootstrap state.
- Regression, idempotency, and secret-safety evidence must be included in the
  final gate.
- Project-specific runtime validation is intentionally outside the bootstrap
  gate and remains local to future adopters.
- `OPERATIONALLY VALIDATED`: not claimed at this intermediate phase; see the
  final implementation report for the completed gate.
