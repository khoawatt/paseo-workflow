# Paseo Workflow Bootstrap Preflight

Date: 2026-09-24  
Evidence class: real-host read-only inspection  
Status: `DESIGN COMPLETE / OPERATIONAL VALIDATION PENDING`

## Host and repository

- Platform: WSL2, Ubuntu 26.04 LTS, x86_64.
- Paseo CLI: `0.9.1`, installed as `@getpaseo/cli` through npm.
- Repository: `khoawatt/paseo-workflow`, clean `main` at the start of planning.
- Bootstrap implementation did not exist at preflight.

## Host policy

- `daemon.mcp.enabled` and `daemon.mcp.injectIntoAgents` are enabled.
- `codex-lead`, `codex-worker`, and `opencode-worker` exist and are available.
- Both worker provider IDs configure `paseoTools.enabled = false`.
- The five V0.2 profiles exist.
- `Planning / Research` and `Review` currently use unrestricted `codex` and
  require provider-only reconciliation to `codex-worker`; their selected model
  and thinking level are compatible and must be preserved.
- Required native orchestration skills are present in the host skill roots.

## Observed runtime/documentation differences

1. Local supervisor status reports stopped while the configured loopback health
   endpoint and injected Paseo MCP are live. Bootstrap topology detection must
   avoid starting a duplicate daemon.
2. The deployed public V1 JSON schema exposes provider `paseoTools` but not
   `daemon.agentProfiles`; the 0.9.1 runtime uses that profile path and returns
   the five profiles through `list_profiles`.
3. The CLI supports provider discovery but has no `list_profiles` command.
   Runtime profile discovery therefore requires Paseo MCP evidence.
4. A disabled OpenCode Paseo tool may remain catalog-visible while invocation
   is denied. The boundary test must exercise the call, not inspect names only.
5. Codex exposes no read-only mode on this host. Planning/Review restrictions
   using the Codex fallback therefore combine the restricted Paseo provider,
   the role contract, and normal provider approval/sandbox behavior.

## Gates

- Config mutation: not performed during preflight.
- Capability boundary: must be revalidated with new sessions after bootstrap.
- Smoke tests A-G: not run for this bootstrap version.
- `fea-lms-rfbe` runtime: pending until the real project is present and
  inspectable.
