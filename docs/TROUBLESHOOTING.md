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

`AUTH_REQUIRED`: the provider binary is installed, but native diagnostics show
that interactive login is required. Complete provider login on the daemon host,
then rerun `bash verify.sh`. Do not store auth material in this repository.

`BLOCKED` with a missing Codex/OpenCode runtime: install that CLI externally on
the daemon host, ensure a fresh login shell and the Paseo daemon can resolve it,
authenticate it, then rerun. `paseo-workflow` never installs, updates, or
replaces provider CLIs. Inspect the exact daemon view with:

```bash
paseo provider diagnostic codex --json
paseo provider diagnostic opencode --json
```

`BLOCKED` after config apply: the installer restores the timestamped backup.
Check the printed backup SHA, daemon health, and verifier blockers. Never delete
or overwrite unrelated host config to make the check pass.

Local daemon says stopped but loopback health works: this is observed on Paseo
0.9.1. Use the configured endpoint rather than starting a duplicate daemon.

Profile not visible through CLI: Paseo 0.9.1 has no CLI Profile-list command.
Use native Paseo MCP discovery for real-host evidence.

Worker shows `create_agent` in a catalog: test invocation. On the observed
OpenCode path, a disabled tool may remain visible while the runtime denies it.

OpenCode provider reports `error` with `text/html` or an unsupported-server
message: compare the Paseo-bundled OpenCode SDK with the resolved OpenCode
binary. Do not replace the user's interactive 2.x binary. Follow
[OpenCode Provider Compatibility](OPENCODE_COMPATIBILITY.md) to test and pin a
separate provider binary, preserve the terminal profile, and restart only when
the OpenCode server manager demonstrably retained old runtime settings. The
bootstrap does not execute this repair automatically.

`PROJECT_RUNTIME_PENDING`: inspect the real project and human-review the
smallest documented `paseo.json`. Do not infer commands, ports, or services from
project names.

Stop and ask the human before removing providers/profiles, changing credentials,
destructive workspace/worktree actions, production changes, canonical merges,
security tradeoffs, or architecture changes.
