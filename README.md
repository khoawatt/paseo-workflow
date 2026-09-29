# Paseo Workflow

Reproducible Node.js/TypeScript CLI for bootstrapping the existing Design Agent
Team V0.2 architecture on WSL2 Ubuntu. Paseo remains the orchestration runtime. This repository only
reconciles the host policy, Agent Profiles, and native Paseo skills required to
run that architecture.

Codex and OpenCode are external user/host prerequisites. Install and
authenticate both CLIs on the WSL host before running the bootstrap;
`paseo-workflow` detects and verifies them but never installs, upgrades, or
replaces them.

The production baseline is Node.js 24 LTS (24.21.0 or newer). CI also tests
Node.js 26 Current. Application logic uses native TypeScript type stripping,
so no runtime transpiler or bundler is required.

## Quick start

```bash
git clone https://github.com/khoawatt/paseo-workflow.git
cd paseo-workflow
npm ci
node src/cli.ts install
```

The installer checks WSL/Ubuntu, installs the pinned supported Paseo CLI when
needed, preserves user-owned configuration, backs up a changed live config,
writes atomically, reloads the selected daemon, and runs the Node verifier. “Fresh
host” means a fresh WSL Ubuntu Paseo host whose documented external Codex and
OpenCode prerequisites have already been satisfied by the user.

Possible results:

- `READY`: bootstrap prerequisites and structural policy are ready.
- `AUTH_REQUIRED`: a required installed provider needs interactive human login.
- `BLOCKED`: a safety, policy, platform, missing external runtime, or other
  non-authentication prerequisite failed; the report includes the next action.

`READY` alone is not operational validation. Bootstrap V1 is
`OPERATIONALLY VALIDATED` only after real-host Preflight and smoke tests A-G,
the bootstrap regression suite, live idempotency, and secret-safety checks all
pass with observable evidence. This status applies only to the bootstrap and
orchestration distribution; each adopting project requires its own local
project-runtime validation.

## Commands

```bash
node src/cli.ts install --dry-run
node src/cli.ts install
node src/cli.ts verify
node src/cli.ts verify --json
node src/cli.ts project inspect /path/to/repository
npm run check
```

The package exposes the same commands as the `paseo-workflow` bin when installed
or linked. The legacy script names are thin compatibility wrappers;
`bootstrap.sh` only checks the Node baseline and transfers control to the CLI.

`project inspect` is read-only in V1. It reports an existing `paseo.json` or
literal commands found in real manifests; it never invents project scripts,
ports, services, or lifecycle hooks.

Start with [AGENTS.md](AGENTS.md). Detailed guidance is in
[Setup](docs/SETUP.md), [Configuration](docs/CONFIGURATION.md),
[Validation](docs/VALIDATION.md), and
[Troubleshooting](docs/TROUBLESHOOTING.md). OpenCode protocol/version failures
are covered by [OpenCode Provider Compatibility](docs/OPENCODE_COMPATIBILITY.md).
The accepted specification is
[Bootstrap V1](docs/specs/2026-09-24-paseo-workflow-bootstrap-v1.md).
Phase 1 task-depth, scope, evidence, and human commitment policy is in
[Governance](docs/GOVERNANCE.md), with an adaptive
[task contract](docs/templates/task-contract.md) and
[behavioral evaluation specification](docs/evals/behavioral-evaluation-spec.md).
Behavioral findings use the canonical
[failure taxonomy](docs/evals/failure-taxonomy.md) and
[recovery playbooks](docs/evals/recovery-playbooks.md).

## Non-goals

No custom workflow controller, agent runtime, provider router, message bus,
workspace/worktree manager, permission queue, scheduler, or authentication
collector is implemented here. Native Paseo capabilities remain authoritative.

## Collaboration

Propose changes from a focused branch and open a pull request against `main`.
Follow [Contributing](CONTRIBUTING.md), keep evidence labels distinct, and
preserve co-authorship with `Co-authored-by` trailers so GitHub attributes
every contributor on the merged commits.

## License

MIT. See [`LICENSE`](LICENSE).
