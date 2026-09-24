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

Evidence labels in reports:

- `implemented`: repository code exists.
- `fixture-tested`: isolated test passed.
- `runtime-tested`: observed on the actual Paseo host.
- `not tested / blocked`: no valid evidence or a named prerequisite failed.

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
BLOCKED and classify it before changing anything. Preflight and A-G form the
core Bootstrap V1 gate. The current official V0.2 smoke-test document also
requires at least one real `fea-lms-rfbe` task end-to-end before the complete
Design Agent Team is called `OPERATIONALLY VALIDATED`; if that repository is not
present and inspected, report core smoke PASS with project validation pending.
