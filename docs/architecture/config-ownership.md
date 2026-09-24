# Paseo Configuration Ownership

This policy implements Design Agent Team V0.2 without replacing a user's
complete Paseo configuration.

## Repository-owned fields

The bootstrap reconciles only:

- `$schema` and `version` when absent or incompatible with Paseo V1 config;
- `daemon.mcp.enabled` and `daemon.mcp.injectIntoAgents`;
- `extends`, `label`, and `paseoTools` for `codex-lead`, `codex-worker`, and
  `opencode-worker`;
- stable identity, name, provider capability class, and behavioral notes for
  the five `design-agent-*-v02` profiles.

An existing required profile may move from an unrestricted provider to a
compatible restricted provider. The repository does not own provider entries
or profiles outside these exact IDs.

## User-owned fields

The bootstrap preserves credentials, authentication state, provider commands,
environment variables, model catalogs, unrelated provider fields, unrelated
profiles, preferred models, thinking levels, feature values, and unrelated
Paseo settings.

For a required profile, an existing model and thinking preference are retained
when an allowed provider exposes that model. If no allowed restricted provider
supports the preference, reconciliation stops with `MODEL/PROVIDER GAP`. It
does not switch the role to a Lead-capable provider or silently replace the
model.

## Runtime-owned state

Agent, session, workspace, and worktree IDs; daemon process state; live config
backups; permission requests; and provider authentication state are never
stored in this repository.

## Mutation and rollback

Host changes follow this order:

1. Inspect the selected Paseo home and daemon topology.
2. Build a protected candidate without modifying the live file.
3. Validate the candidate with the installed Paseo CLI/runtime.
4. If there is no semantic change, stop without writing or backing up.
5. Create a timestamped mode-0600 backup and record its SHA-256.
6. Replace the live file with a same-directory atomic rename.
7. Reload the selected live daemon and verify the owned policy.
8. If apply or verification fails, atomically restore the exact backup, reload
   the restored state, and report `BLOCKED`.

Removing unrelated providers/profiles, modifying credentials, or accepting a
broader diff is a human-gated action.

## Evidence classes

- **Implemented:** behavior exists in repository code.
- **Fixture-tested:** behavior passed against isolated synthetic homes and
  fake provider/runtime responses.
- **Runtime-tested:** behavior was observed through the real Paseo host.
- **Not tested / blocked:** evidence is absent or a named prerequisite failed.

Fixture success never proves provider authentication, tool injection, agent
parentage, worktree isolation, permission behavior, or smoke tests A-G.
