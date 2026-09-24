# Setup

## Prerequisites

- WSL2 running Ubuntu.
- Bash and an `apt`-compatible environment.
- Paseo-compatible Codex CLI installed on the daemon host and authenticated by
  the user (`codex login`).
- Paseo-compatible OpenCode CLI installed on the daemon host with its required
  provider authentication completed by the user.

Provider CLIs are external prerequisites. The bootstrap does not install,
upgrade, replace, or authenticate them. See Paseo's current
[Providers](https://paseo.sh/docs/providers.md),
[Codex](https://paseo.sh/docs/codex.md), and
[Troubleshooting](https://paseo.sh/docs/troubleshooting.md) documentation.

Clone and inspect before applying:

```bash
git clone https://github.com/khoawatt/paseo-workflow.git
cd paseo-workflow
bash install.sh --dry-run
bash install.sh
```

The installer performs platform/dependency checks, installs or upgrades the
pinned supported Paseo version, preflights the externally managed provider
runtimes with native diagnostics, verifies native Paseo skills, discovers real
provider model catalogs, reconciles a candidate config, validates it with the
native CLI, backs up a changed config, atomically applies it, reloads or starts
the correct daemon topology, and runs `verify.sh`.

It will not automatically downgrade a newer Paseo version. That requires a
human decision after comparing current runtime/docs with the V0.2 assumptions.

## Authentication checkpoint

`AUTH_REQUIRED` means an installed required provider needs interactive login.
Use the provider's native authentication flow; do not paste credentials into
repository files. A missing binary is instead `BLOCKED` and reports the exact
external installation/PATH action. Then run:

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

## OpenCode provider compatibility

If `opencode` is installed but Paseo reports a protocol/server error during
model discovery, stop before config reconciliation and follow
[OpenCode Provider Compatibility](OPENCODE_COMPATIBILITY.md). This is a
conditional compatibility repair, not a default bootstrap dependency. Preserve
the user's interactive OpenCode runtime and authentication state.

## Native skill upstream dependency

Paseo currently documents `npx skills add getpaseo/paseo`, and selected skills
are refreshed by the host on startup. The public documentation does not expose
a reproducible skill-version pin contract. V1 therefore uses and verifies the
official upstream flow, does not vendor or recreate the skills, and records the
upstream dependency rather than building a custom installer.
