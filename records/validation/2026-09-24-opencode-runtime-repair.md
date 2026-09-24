# OpenCode Runtime Repair Evidence

This record describes a human-operated host repair performed during validation.
It is not a default `paseo-workflow` bootstrap action. Provider runtime
installation, updates, executable selection, and authentication remain external
user/host responsibilities.

Date: 2026-09-24  
Host: WSL2 Ubuntu, sanitized  
Classification: `MODEL/PROVIDER GAP`  
Final provider result: `PASS`

## Before

- Paseo CLI/daemon: `0.9.1`.
- Paseo server dependency: `@opencode-ai/sdk` `1.14.46`.
- Interactive OpenCode: `2.0.15`.
- `opencode` and `opencode-worker`: `error`.
- Provider/model request error: OpenCode server response was unsupported and
  returned `text/html` to the SDK request.
- Required Implementation preference remained
  `opencode/muse-spark-1.3-contributor-free`; switching it silently to Codex was
  rejected as incompatible with the accepted ownership/model policy.

No live Paseo config mutation occurred while the provider was failing.

## Candidate proof before mutation

- Official OpenCode release: `v1.18.31`.
- Release asset: `opencode-linux-x64.tar.gz`.
- GitHub release digest and downloaded archive SHA-256 both:
  `e9312be75ed803b7415fc2aeabda1f4fe938912a39673762dc0c38c0e11ebde4`.
- Extracted binary SHA-256:
  `f9dab32248695e9ebd56b16a1921798fd85112cf5a69c7dfd0cabc1e17be4a11`.
- Isolated binary version: `1.18.31`.
- Isolated `/provider` response: HTTP 200, `application/json`, expected object
  shape. Test used a temporary home and loopback-only server.

## Applied repair

- Installed a dedicated provider binary at
  `~/.local/bin/opencode-paseo-1.18.31` with mode 0755.
- Created a mode-0600 config backup under `~/.paseo/backups/`; backup SHA-256:
  `79b8d3f3c92abdfff2c12373a53df5c45b666ae4f9b32bf7284e5923f054a1f1`.
- Atomically merged only `agents.providers.opencode.command` and `enabled`.
- Native Paseo candidate validation passed.
- `paseo reload` applied `agents.providers` and reported no schema error.
- The first post-reload check still failed because the OpenCode server manager
  was already initialized with the prior runtime settings. The daemon log
  explicitly recorded that mismatch.
- One supervised daemon-worker restart activated the override. No OpenCode
  agents were active; only closed OpenCode agents existed before restart.

The interactive binary and terminal profile were not changed:

```text
interactive OpenCode = 2.0.15
terminal profile = opencode --prompt={{{prompt}}}
```

Credentials and authentication state were neither read into the repository nor
modified.

## After

- OpenCode diagnostic resolved the dedicated compatibility binary.
- Diagnostic version: `1.18.31`.
- Diagnostic status: `Ready`.
- Discovered models: 109 at validation time; model count is evidence, not an
  invariant.
- `opencode`: `available`.
- `opencode-worker`: `available`.
- `opencode-worker.paseoTools.enabled`: still `false`.
- Interactive `opencode --version`: still `2.0.15`.

## Rollback

Restore the exact pre-provider config backup atomically, reload Paseo, and
restart the daemon worker only if the old provider runtime remains cached. The
dedicated binary contains no credentials and may remain for diagnosis, but it
must not be selected after restoring the override.

## Architecture impact

None. This is a host/provider compatibility repair using an existing Paseo
provider command override. No custom controller, provider router, agent runtime,
or orchestration primitive was added.
