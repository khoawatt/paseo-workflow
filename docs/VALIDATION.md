# Validation

## Repository fixture tests

```bash
bash tests/test.sh
```

These isolated tests cover policy, config preservation/merge, credentials and
unknown fields, model compatibility, backups, atomic rollback, idempotency,
status reporting, native skill presence, project inspection, and secret safety.
They use synthetic homes and fake runtime responses. They do not authenticate
providers or prove live orchestration.

## Real-host bootstrap checks

```bash
bash verify.sh
bash verify.sh --json
```

`READY` proves bootstrap prerequisites, required policy, skills, providers, and
daemon availability as implemented by the verifier. MCP Profile discovery and
agent capability calls remain explicitly `not tested` until exercised with new
live sessions.

Provider classification uses native `paseo provider diagnostic <provider>
--json` where practical, then correlates required capability-class status from
`provider ls`:

- missing external binary/PATH resolution → `BLOCKED` with install/PATH action;
- installed runtime requiring interactive login → `AUTH_REQUIRED`;
- ready external runtime and available capability classes → eligible for
  `READY`;
- installed but unhealthy/incompatible runtime → `BLOCKED` with diagnostic or
  conditional compatibility guidance.

Evidence labels in reports:

- `implemented`: repository code exists.
- `fixture-tested`: isolated test passed.
- `runtime-tested`: observed on the actual Paseo host.
- `not tested / blocked`: no valid evidence or a named prerequisite failed.

## Review and worktree invariants

Any implementation change after a review invalidates that review. The exact
final implementation state must receive a fresh independent Reviewer `ACCEPT`
before the Lead may report the work as `DONE`.

Independent write workers must use separate Paseo worktrees by default. A
shared working tree is allowed only as an explicit fallback, must be reported
clearly, and Git history must not be reconstructed afterward to imply isolation
that did not actually occur.

Review evidence must identify the exact final commit SHA or otherwise immutable
reviewable state. If a shared-tree fallback was used, record that fact and the
actual write history directly; a later commit does not retroactively prove
worktree isolation.

## Operational validation gate

Before A, validate the capability boundary at call level:

- Lead can use expected Paseo orchestration capability.
- `codex-worker` cannot successfully invoke `create_agent`.
- `opencode-worker` cannot successfully invoke `create_agent`.
- Workers retain normal coding/research capability for their roles.

Then run the official V0.2 suite in order:

| Gate | Scenario |
| --- | --- |
| Preflight | Host/runtime/policy evidence |
| A | Fan-out read-only research |
| B | One isolated implementation worktree |
| C | Implementation plus fresh independent review |
| D | Two parallel implementation worktrees |
| E | Native handoff, advisor, and committee |
| F | Follow-up, redirect, cancel, and archive |
| G | Runtime permission boundary |

Each PASS requires observable real-host evidence. Otherwise report FAIL or
BLOCKED and classify it before changing anything. The complete Bootstrap V1
gate is:

```text
Preflight
+ A + B + C + D + E + F + G
+ bootstrap regression suite
+ live idempotency
+ secret-safety checks
```

The existing disposable smoke fixture provides the real Git and worktree
evidence required by B, C, and D; no application repository or duplicate
fixture is required. When the complete gate passes, `OPERATIONALLY VALIDATED`
applies only to the bootstrap/orchestration distribution. A future adopting
project runs `install-project.sh <repo>`, derives runtime from that inspected
repository, and performs project-specific validation locally.
