# OpenCode Provider Compatibility

This page covers only the OpenCode provider used by Paseo. It does not configure
WSL networking, SSH, systemd, Paseo Desktop, or host exposure.

This is a conditional human-operated troubleshooting procedure. Bootstrap V1
does not download, install, update, or replace OpenCode automatically. Use this
path only after native Paseo diagnostics confirm a protocol/version mismatch;
otherwise reuse the user's healthy existing runtime.

## Observed failure on 2026-09-24

The validated host had:

- Paseo CLI/daemon `0.9.1`;
- Paseo server dependency `@opencode-ai/sdk` `1.14.46`;
- interactive OpenCode `2.0.15` at `~/.opencode/bin/opencode`;
- `~/.local/bin/opencode` symlinked to that interactive binary.

Paseo could resolve and execute OpenCode 2.0.15, but provider discovery failed:
the SDK requested the OpenCode `/provider` API and received `text/html`. Both
`opencode` and `opencode-worker` consequently reported `error`, and model
discovery was unavailable. This is a `MODEL/PROVIDER GAP`, not a reason to
change the Design Agent Team architecture or move worker roles to `codex-lead`.

The provider failure was reproduced through both Paseo CLI and native MCP. A
temporary OpenCode 1.18.31 server returned `200 application/json` with the
object keys expected by Paseo before any live mutation was made.

## Compatibility layout

Keep interactive and provider runtimes separate:

```text
interactive terminal/profile
  ~/.local/bin/opencode -> ~/.opencode/bin/opencode
  OpenCode 2.x

Paseo OpenCode provider
  ~/.local/bin/opencode-paseo-1.18.31
  selected by agents.providers.opencode.command
```

The OpenCode terminal profile remains:

```json
{
  "command": "opencode",
  "args": ["--prompt={{{prompt}}}"]
}
```

Do not replace the user's interactive binary or pass prompts positionally.

## Verified installation procedure

Use the official release asset for the host architecture. For the validated
Linux x64 host, GitHub release metadata reported this asset digest:

```text
OpenCode release: v1.18.31
Asset: opencode-linux-x64.tar.gz
SHA-256: e9312be75ed803b7415fc2aeabda1f4fe938912a39673762dc0c38c0e11ebde4
```

Download to a temporary directory, verify the archive digest, extract it, and
run `opencode --version`. Test a temporary server's `/provider` endpoint before
installing it. Never invent or skip the checksum.

Install the verified binary as:

```text
~/.local/bin/opencode-paseo-1.18.31
```

Before changing Paseo config, create a timestamped mode-0600 backup under
`~/.paseo/backups/`. Then ownership-aware merge only:

```json
{
  "agents": {
    "providers": {
      "opencode": {
        "command": ["/home/<user>/.local/bin/opencode-paseo-1.18.31"],
        "enabled": true
      }
    }
  }
}
```

Preserve all credentials, auth state, other provider fields, worker policy,
profiles, and unrelated config. Validate the candidate with the native Paseo
config surface, atomically replace the live file, and run `paseo reload`.

Paseo 0.9.1 may retain an already initialized OpenCode server manager after a
provider command reload. Evidence is a log warning containing `already
initialized with different runtime settings`, or a diagnostic that resolves
the new binary while provider discovery still returns the old error. When that
specific condition occurs, run one supervised `paseo daemon restart`; do not
restart blindly.

## Validation

All of these must pass:

```bash
paseo provider diagnostic opencode
paseo provider ls --json
paseo provider models opencode --thinking --json
paseo provider models opencode-worker --thinking --json
```

Expected behavior:

- diagnostic resolves the dedicated 1.18.31 binary and reports `Ready`;
- both `opencode` and `opencode-worker` are `available`;
- model discovery succeeds for both provider IDs;
- the required Implementation model remains available;
- `opencode-worker.paseoTools.enabled` remains `false`;
- interactive `opencode --version` still reports the user's 2.x runtime;
- the terminal profile still uses `--prompt={{{prompt}}}`.

## Rollback

If validation fails:

1. Stop changing additional fields.
2. Atomically restore the exact pre-change config backup.
3. Reload Paseo; restart only if the cached provider runtime remains active.
4. Re-run provider diagnostics.
5. Keep the compatibility binary until the failure is understood; it contains
   no credentials, but do not point Paseo at it after restoring the override.

## Decommission gate

The dedicated binary is a compatibility workaround, not a permanent
architecture invariant. After upgrading Paseo/OpenCode, first test the current
interactive OpenCode binary against provider discovery. Remove the command
override only when diagnostic, model discovery, a real OpenCode worker launch,
and the worker capability-boundary test all pass. Preserve a config backup and
restore the override immediately if any check regresses.

This procedure is derived from the project runbook at
`ai-agent/tooling/paseo-desktop-wsl-setup-runbook.md`, restricted to its OpenCode
compatibility sections as requested.
