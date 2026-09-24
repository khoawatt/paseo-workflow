# Setup

## Prerequisites

- WSL2 running Ubuntu.
- Bash and an `apt`-compatible environment.
- Human access to authenticate the required Codex/OpenCode providers.

Clone and inspect before applying:

```bash
git clone https://github.com/khoawatt/paseo-workflow.git
cd paseo-workflow
bash install.sh --dry-run
bash install.sh
```

The installer performs platform/dependency checks, installs or upgrades to the
pinned supported Paseo version, verifies native Paseo skills, discovers real
provider model catalogs, reconciles a candidate config, validates it with the
native CLI, backs up a changed config, atomically applies it, reloads or starts
the correct daemon topology, and runs `verify.sh`.

It will not automatically downgrade a newer Paseo version. That requires a
human decision after comparing current runtime/docs with the V0.2 assumptions.

## Authentication checkpoint

`AUTH_REQUIRED` means the structural bootstrap is valid but a required provider
is unavailable. Use the provider's native interactive authentication flow; do
not paste credentials into repository files. Then run:

```bash
bash verify.sh
```

## Backup and rollback

Before changing an existing config, the installer writes a mode-0600 backup in
the same Paseo home:

```text
~/.paseo/config.json.backup-bootstrap-<UTC>
```

It prints the backup path and SHA-256, then atomically replaces `config.json`.
If reload or final verification returns `BLOCKED`, it atomically restores that
exact backup and reloads the restored state. No-op reruns do not create backups.
Backups are host state and must never be copied into this repository.

## Idempotency

Run the installer repeatedly only after the first result is understood:

```bash
bash install.sh
bash install.sh
```

The second successful run must report a converged config, preserve its SHA, and
create no additional backup. Operational validation is a separate gate.
