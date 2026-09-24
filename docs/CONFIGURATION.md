# Configuration Policy

The implementation follows [field-level ownership](architecture/config-ownership.md)
and never replaces the full user config with a golden file.

## Repository-owned

- `daemon.mcp.enabled` and `daemon.mcp.injectIntoAgents`.
- Capability policy for `codex-lead`, `codex-worker`, and `opencode-worker`.
- Stable role identity, provider boundary, and behavioral notes for the five
  `design-agent-*-v02` Profiles.
- Presence of the native `paseo`, `paseo-handoff`, `paseo-committee`, and
  `paseo-advisor` skills.

## User-owned

Credentials/authentication, preferred models, thinking levels, compatible
feature choices, unrelated providers/profiles, and unrelated config are
preserved. Unknown fields are preserved unless they conflict with an explicitly
repository-owned path.

When an existing required role uses an unrestricted provider, only its provider
capability class changes when its model/thinking preference is compatible. If
no restricted provider supports the preference, reconciliation stops with
`MODEL/PROVIDER GAP`.

## Runtime-owned

Agent, session, workspace, and worktree IDs; daemon state; live backups;
permissions; and authentication state are not version-controlled.

## Capability versus permissions

`paseoTools.enabled=false` means Paseo orchestration tools are not enabled for
that provider class. It does not prove that the process cannot reach Paseo by
shell/CLI or through other host capabilities. Keep three controls separate:

1. Paseo tool policy.
2. Provider-native sandbox and filesystem/network/command permissions.
3. Human approval for high-impact actions.

Model intelligence is independent of these controls. Selecting a stronger
model must never silently switch a worker role to `codex-lead`.

## OpenCode executable override

An `agents.providers.opencode.command` override is user/host-owned compatibility
configuration. The bootstrap preserves it. When Paseo and the user's current
interactive OpenCode binary are protocol-incompatible, use a separately named,
checksum-verified provider binary as documented in
[OpenCode Provider Compatibility](OPENCODE_COMPATIBILITY.md). Do not replace
the interactive binary or copy provider credentials.
