# Paseo Workflow

Reproducible WSL2 Ubuntu bootstrap for the existing Design Agent Team V0.2
architecture. Paseo remains the orchestration runtime; this repository only
reconciles the host policy, Agent Profiles, and native Paseo skills required to
run that architecture.

## Quick start

```bash
git clone https://github.com/khoawatt/paseo-workflow.git
cd paseo-workflow
bash install.sh
```

The installer checks WSL/Ubuntu, installs the pinned supported Paseo CLI when
needed, preserves user-owned configuration, backs up a changed live config,
writes atomically, reloads the selected daemon, and runs `verify.sh`.

Possible results:

- `READY`: bootstrap prerequisites and structural policy are ready.
- `AUTH_REQUIRED`: structure is ready, but a human must authenticate a required
  provider and rerun verification.
- `BLOCKED`: a safety, policy, platform, or runtime prerequisite failed.

`READY` alone is not operational validation. Bootstrap V1 is
`OPERATIONALLY VALIDATED` only after real-host Preflight and smoke tests A-G,
the bootstrap regression suite, live idempotency, and secret-safety checks all
pass with observable evidence. This status applies only to the bootstrap and
orchestration distribution; each adopting project requires its own local
project-runtime validation.

## Commands

```bash
bash install.sh --dry-run
bash install.sh
bash verify.sh
bash tests/test.sh
bash install-project.sh /path/to/repository
```

`install-project.sh` is read-only in V1. It reports an existing `paseo.json` or
literal commands found in real manifests; it never invents project scripts,
ports, services, or lifecycle hooks.

Start with [AGENTS.md](AGENTS.md). Detailed guidance is in
[Setup](docs/SETUP.md), [Configuration](docs/CONFIGURATION.md),
[Validation](docs/VALIDATION.md), and
[Troubleshooting](docs/TROUBLESHOOTING.md). OpenCode protocol/version failures
are covered by [OpenCode Provider Compatibility](docs/OPENCODE_COMPATIBILITY.md).
The accepted specification is
[Bootstrap V1](docs/specs/2026-09-24-paseo-workflow-bootstrap-v1.md).

## Non-goals

No custom workflow controller, agent runtime, provider router, message bus,
workspace/worktree manager, permission queue, scheduler, or authentication
collector is implemented here. Native Paseo capabilities remain authoritative.

## License

MIT. See [`LICENSE`](LICENSE).
