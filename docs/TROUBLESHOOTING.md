# Troubleshooting

Classify failures before changing the system:

- `CONFIG`: schema, merge, routing, skill, or daemon configuration error.
- `PROMPT/POLICY`: role behavior or delegation contract error.
- `PASEO GAP`: a measured native runtime capability is missing.
- `PROJECT GAP`: the inspected repository lacks a validated runtime contract.
- `MODEL/PROVIDER GAP`: required compatible model/provider is unavailable.
- `ARCHITECTURE GAP`: a frozen invariant is technically invalid in the runtime.

CONFIG and PROMPT/POLICY failures must not be solved with custom orchestration
infrastructure.

## Common results

`AUTH_REQUIRED`: complete native provider login, then rerun `bash verify.sh`.
Do not store auth material in this repository.

`BLOCKED` after config apply: the installer restores the timestamped backup.
Check the printed backup SHA, daemon health, and verifier blockers. Never delete
or overwrite unrelated host config to make the check pass.

Local daemon says stopped but loopback health works: this is observed on Paseo
0.9.1. Use the configured endpoint rather than starting a duplicate daemon.

Profile not visible through CLI: Paseo 0.9.1 has no CLI Profile-list command.
Use native Paseo MCP discovery for real-host evidence.

Worker shows `create_agent` in a catalog: test invocation. On the observed
OpenCode path, a disabled tool may remain visible while the runtime denies it.

`PROJECT_RUNTIME_PENDING`: inspect the real project and human-review the
smallest documented `paseo.json`. Do not infer commands, ports, or services from
project names.

Stop and ask the human before removing providers/profiles, changing credentials,
destructive workspace/worktree actions, production changes, canonical merges,
security tradeoffs, or architecture changes.
