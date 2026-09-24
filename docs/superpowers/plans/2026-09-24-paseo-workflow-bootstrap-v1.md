# Paseo Workflow Bootstrap V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an idempotent WSL2 Ubuntu bootstrap distribution that installs and reconciles the existing Paseo Design Agent Team V0.2, validates it with repository fixtures and real-host tests, and never claims operational validation without observable Preflight plus A-G evidence.

**Architecture:** Bash entrypoints orchestrate installation and validation only; a focused `jq` reconciliation program owns configuration merge semantics. Paseo remains the runtime for providers, profiles, skills, agents, workspaces, permissions, and lifecycle operations. Host mutation is delayed until fixture tests pass and uses inspect → candidate → native validation → timestamped backup → atomic replace → reload/verify, with automatic rollback on apply failure.

**Tech Stack:** Bash 4+, jq 1.6+, Git, curl, Node.js/npm, `@getpaseo/cli@0.9.1`, native Paseo CLI/MCP, GitHub Actions on Ubuntu.

**Spec:** `docs/specs/2026-09-24-paseo-workflow-bootstrap-v1.md`

## Global Constraints

- Authority order is actual Paseo runtime, current official Paseo docs, the V0.2 execution brief, referenced V0.2 specs, bootstrap policy, then `AGENTS.md`.
- V1 supports WSL2 Ubuntu only; macOS and native Linux are explicit non-goals.
- Paseo `0.9.1` is the pinned compatibility baseline until runtime evidence requires a documented change.
- No custom TypeScript Workflow Controller, orchestration engine, provider router, permission queue, scheduler, state database, or project process manager.
- Provider IDs are tool-capability classes; Agent Profiles are role presets; model strength never grants orchestration authority.
- Preserve credentials, unknown fields, unrelated providers/profiles, compatible model preferences, and thinking preferences.
- `paseoTools.enabled = false` is a Paseo catalog boundary, not an OS security sandbox.
- High-impact/destructive operations, canonical merge, production changes, credentials, and architecture changes are human-gated.
- `READY` means bootstrap-ready only. `OPERATIONALLY VALIDATED` requires real-host Preflight plus smoke tests A-G.

## Observed runtime/docs differences to carry through implementation

1. `paseo daemon status --json` reports the selected local supervisor as stopped, while `http://127.0.0.1:6767/api/health` returns 200 and the injected Paseo MCP returns live providers/profiles. The bootstrap must probe both the supervisor-selected home and the configured endpoint; it must not start a duplicate daemon when a healthy external/unmanaged daemon already owns the endpoint.
2. The deployed public config schema currently exposes provider `paseoTools` but does not expose `daemon.agentProfiles`; Paseo 0.9.1 runtime and `list_profiles` use `daemon.agentProfiles`. Candidate validation must therefore use the installed Paseo CLI/runtime, and this mismatch must be recorded rather than hidden.
3. The CLI exposes provider discovery but no `list_profiles` command. Repository `verify.sh` can validate configured profile state; real runtime profile discovery must be proven through Paseo MCP during host validation.
4. A prior OpenCode 0.9.1 boundary check showed a disabled Paseo tool may remain visible in a catalog while invocation is denied. Capability validation must require an actual denied call, not catalog absence alone.
5. Current host profiles `Planning / Research` and `Review` use unrestricted `codex`; their preserved `gpt-5.6-sol` preference is available on `codex-worker`, so the smallest compatible correction is provider-only migration to `codex-worker`.

## File map

- `policy/providers.json` — exact repository-owned provider capability fields.
- `policy/profiles.json` — five V0.2 role identities, notes, provider preference/fallback order, and safe fresh-host defaults.
- `docs/architecture/config-ownership.md` — repository/user/runtime ownership matrix and conflict behavior.
- `lib/common.sh` — logging, status, temporary-file, platform, and redaction helpers.
- `lib/reconcile-config.jq` — deterministic ownership-aware configuration transform.
- `bin/reconcile-config` — secret-safe wrapper around the jq transform and model catalogs.
- `install.sh` — machine bootstrap; never participates in normal orchestration.
- `verify.sh` — read-only repository/config/runtime/skill verification and status classification.
- `install-project.sh` — read-only-first project runtime assessment; never guesses commands.
- `tests/test.sh` — complete repository fixture suite.
- `tests/helpers/testlib.sh` — assertions and isolated-home helpers.
- `tests/fixtures/**` — literal config/model/project inputs with no real credentials.
- `docs/{SETUP,CONFIGURATION,VALIDATION,TROUBLESHOOTING}.md` — operator documentation.
- `records/validation/*.md` — sanitized real-host evidence only.
- `.github/workflows/test.yml` — syntax, fixture, secret-scan, and idempotency CI.

## Review Focus

- An existing required profile has a preferred model unavailable on every allowed restricted provider: abort profile mutation and report `MODEL/PROVIDER GAP` without weakening the capability class.
- A valid config contains unknown nested fields and credential-looking values: preserve bytes semantically and never print values in summaries or test logs.
- A daemon is healthy at the configured endpoint but has no local supervisor metadata: reload the existing daemon target and never launch a duplicate.
- Atomic replacement succeeds but reload/verification fails: restore the exact backup, revalidate, and return `BLOCKED` rather than leaving partial state.
- An existing project contains scripts with unusual package managers or no manifest: report evidence and `PROJECT_RUNTIME_PENDING`; never synthesize commands.

---

### Task 1: Freeze authority, ownership, and declarative V0.2 policy

**Files:**
- Create: `policy/providers.json`
- Create: `policy/profiles.json`
- Create: `docs/architecture/config-ownership.md`
- Create: `records/validation/2026-09-24-preflight.md`
- Create: `tests/helpers/testlib.sh`
- Create: `tests/policy_test.sh`
- Create: `tests/test.sh`

**Interfaces:**
- Consumes: accepted spec and current V0.2 source documents.
- Produces: policy JSON consumed by `bin/reconcile-config`; `run_test`, `assert_eq`, `assert_json`, and `make_temp_home` test helpers.

- [ ] **Step 1: Write the failing policy contract test**

Create `tests/policy_test.sh` that asserts literal provider IDs and ownership fields, exactly five profile IDs/names, no permanent Integration profile, worker-only allowed provider IDs, and no secret-like keys. It must fail because `policy/*.json` do not exist.

```bash
bash tests/policy_test.sh
```

Expected: nonzero with `policy/providers.json: missing`.

- [ ] **Step 2: Add the minimal policy files**

`policy/providers.json` owns only `extends`, `label`, and worker `paseoTools`:

```json
{
  "codex-lead": {"extends":"codex","label":"Codex Lead"},
  "codex-worker": {"extends":"codex","label":"Codex Worker","paseoTools":{"enabled":false}},
  "opencode-worker": {"extends":"opencode","label":"OpenCode Worker","paseoTools":{"enabled":false}}
}
```

`policy/profiles.json` records the five stable IDs, exact role notes, and allowed provider order. Fresh profiles omit model/thinking unless a compatible user preference exists. Review provider order is evaluated against Implementation to prefer diversity.

- [ ] **Step 3: Document ownership and sanitized preflight evidence**

The ownership document must state field-level behavior, model compatibility blocking, backup/rollback, and the distinction between fixtures and real-host tests. The preflight record includes versions/statuses and the five observed differences above, but no raw config, tokens, runtime IDs, or session data.

- [ ] **Step 4: Run policy validation**

```bash
bash tests/policy_test.sh && bash tests/test.sh
```

Expected: all policy tests pass; test runner reports `failures=0`.

- [ ] **Step 5: Commit**

```bash
git add policy docs/architecture records/validation tests
git commit -m "docs: define V0.2 bootstrap ownership policy"
```

### Task 2: Implement the ownership-aware configuration reconciler with TDD

**Files:**
- Create: `lib/reconcile-config.jq`
- Create: `bin/reconcile-config`
- Create: `tests/config_merge_test.sh`
- Create: `tests/fixtures/config/*.json`
- Create: `tests/fixtures/models/{codex,opencode}.json`
- Modify: `tests/test.sh`

**Interfaces:**
- Consumes: `policy/providers.json`, `policy/profiles.json`, an existing or absent `config.json`, and provider model catalogs.
- Produces: `bin/reconcile-config --input PATH|--empty --output PATH --codex-models PATH --opencode-models PATH`; exit 0 writes a mode-0600 candidate and prints a sanitized change summary, exit 3 reports a compatibility blocker without output.

- [ ] **Step 1: Add literal fixture tests before production code**

Tests cover fresh/no config, valid config, unknown nested fields, unrelated provider/profile, incorrect required profile provider, custom model/thinking preservation, credentials/auth fields, partial installation, already-correct state, invalid policy, unavailable model, and a second reconciliation producing byte-identical normalized JSON.

```bash
bash tests/config_merge_test.sh
```

Expected: nonzero because `bin/reconcile-config` is missing.

- [ ] **Step 2: Implement the smallest deterministic jq transform**

The transform sets `$schema`, `version`, required MCP booleans, and only repository-owned fields under the three required providers. It indexes profiles by stable V0.2 ID, preserves unrelated entries and user-owned settings, selects an allowed restricted provider that supports an existing model, and never emits credentials in its summary.

Provider selection rules are literal:

```text
Lead: codex-lead
Planning: opencode-worker, then codex-worker
Implementation: codex-worker, then opencode-worker
Review: restricted provider different from Implementation when compatible, then either restricted provider
Specialist: preserve a compatible restricted provider, then codex-worker, then opencode-worker
```

- [ ] **Step 3: Implement the wrapper safety contract**

The wrapper creates output in the caller-selected path with `umask 077`, rejects malformed JSON/policy, cleans temporary files through `trap`, and prints only field paths and profile/provider IDs.

- [ ] **Step 4: Prove RED→GREEN and full fixture behavior**

```bash
bash tests/config_merge_test.sh && bash tests/test.sh
```

Expected: every named fixture passes; unavailable-model case exits 3; `failures=0`.

- [ ] **Step 5: Commit**

```bash
git add lib bin tests
git commit -m "feat: add ownership-aware Paseo config reconciliation"
```

### Task 3: Implement safe machine bootstrap and rollback

**Files:**
- Create: `config/bootstrap.env`
- Create: `lib/common.sh`
- Create: `install.sh`
- Create: `tests/install_test.sh`
- Create: `tests/fixtures/fake-bin/{paseo,npm,apt-get,sudo,curl}`
- Modify: `tests/test.sh`

**Interfaces:**
- Consumes: reconciler, `PASEO_HOME`/`--home`, pinned `PASEO_VERSION=0.9.1`, and native CLI validation/reload.
- Produces: final `READY`, `AUTH_REQUIRED`, or `BLOCKED`; timestamped mode-0600 backup only when a write is required; rollback evidence on failed apply.

- [ ] **Step 1: Write installer behavior tests**

Run `install.sh` in isolated fake WSL homes. Assert platform rejection, dependency detection, pinned npm command, no-op rerun without backup, changed config with backup, candidate validation before mutation, atomic same-directory rename, reload targeting a healthy external daemon, start only when no daemon is healthy, and exact rollback after simulated reload failure.

```bash
bash tests/install_test.sh
```

Expected: nonzero because `install.sh` is missing.

- [ ] **Step 2: Implement preflight and dependency setup**

Require WSL2 plus Ubuntu. Install missing `curl git jq nodejs npm` through apt only after printing the package plan. Install or upgrade with:

```bash
npm install -g "@getpaseo/cli@${PASEO_VERSION}"
```

Do not downgrade a newer compatible Paseo automatically; report the mismatch and require an explicit future policy decision.

- [ ] **Step 3: Implement candidate validation, backup, atomic write, and rollback**

Validate a candidate in a temporary home using the installed native CLI. Before mutation, copy the exact live file to `config.json.backup-bootstrap-<UTC>` with mode 0600 and record its SHA-256. Write a mode-0600 same-directory temporary file and rename atomically. On reload or post-apply verification failure, atomically restore the backup, reload the restored state, and return `BLOCKED`.

- [ ] **Step 4: Implement daemon topology selection**

Use local supervisor status first. If it is stopped, probe the configured loopback health endpoint. A healthy endpoint is treated as externally/unmanaged and receives explicit-host reload; a missing endpoint permits `paseo daemon start --home`. Never restart a running daemon implicitly.

- [ ] **Step 5: Run installer tests and syntax checks**

```bash
bash -n install.sh lib/common.sh bin/reconcile-config
bash tests/install_test.sh
bash tests/test.sh
```

Expected: syntax clean; rollback fixture restores the original SHA; `failures=0`.

- [ ] **Step 6: Commit**

```bash
git add config lib install.sh tests
git commit -m "feat: add safe idempotent WSL Paseo bootstrap"
```

### Task 4: Implement native skill reconciliation and read-only verification

**Files:**
- Create: `verify.sh`
- Create: `tests/verify_test.sh`
- Modify: `install.sh`
- Modify: `tests/test.sh`

**Interfaces:**
- Consumes: live config, `paseo provider ls/models/diagnostic`, daemon status/health, and installed native skill paths.
- Produces: human and `--json` reports with distinct fixture/static/runtime evidence and a bootstrap status.

- [ ] **Step 1: Write failing verification/status tests**

Fixtures cover all-ready, missing skill, unavailable required provider, missing authentication, wrong profile capability class, unreachable daemon, and public-schema/profile runtime mismatch. Tests assert `READY`, `AUTH_REQUIRED`, or `BLOCKED` without secret values.

```bash
bash tests/verify_test.sh
```

Expected: nonzero because `verify.sh` is missing.

- [ ] **Step 2: Implement native skill reconciliation in `install.sh`**

When any required skill is absent, run the official command:

```bash
npx --yes skills add getpaseo/paseo
```

Verify `/paseo`, `/paseo-handoff`, `/paseo-committee`, and `/paseo-advisor` from installed host skill roots. Do not copy or recreate skill content in this repository.

- [ ] **Step 3: Implement `verify.sh`**

Static checks validate policy/config and configured profiles; runtime checks use native provider CLI and daemon health. The report explicitly marks runtime profile discovery and capability calls as `not tested` until MCP host validation runs. Provider authentication failure maps to `AUTH_REQUIRED`; policy/config/runtime contradictions map to `BLOCKED`.

- [ ] **Step 4: Run verification fixtures and suite**

```bash
bash -n verify.sh install.sh
bash tests/verify_test.sh
bash tests/test.sh
```

Expected: status matrix passes and `failures=0`.

- [ ] **Step 5: Commit**

```bash
git add verify.sh install.sh tests
git commit -m "feat: verify Paseo bootstrap and native skills"
```

### Task 5: Implement project-runtime inspection without guessing

**Files:**
- Create: `install-project.sh`
- Create: `tests/install_project_test.sh`
- Create: `tests/fixtures/projects/{missing-manifest,node-existing-runtime,node-no-runtime,unknown}/**`
- Modify: `tests/test.sh`

**Interfaces:**
- Consumes: an existing repository path and its real manifests/scripts plus optional existing `paseo.json`.
- Produces: read-only assessment and `PROJECT_RUNTIME_READY`, `PROJECT_RUNTIME_PENDING`, or `BLOCKED`; no project mutation in V1.

- [ ] **Step 1: Write project-assessment tests**

Assert missing path, non-git directory, existing valid `paseo.json`, Node manifest with real scripts but no runtime, and unknown manifest. Confirm the target tree hash never changes.

```bash
bash tests/install_project_test.sh
```

Expected: nonzero because `install-project.sh` is missing.

- [ ] **Step 2: Implement read-only derivation**

Inspect Git state, `paseo.json`, and known manifests. Report only commands literally present in the project. If no validated runtime exists, return `PROJECT_RUNTIME_PENDING` with evidence and a human-reviewed next action; never create `paseo.json` automatically.

- [ ] **Step 3: Run tests and commit**

```bash
bash -n install-project.sh
bash tests/install_project_test.sh
bash tests/test.sh
git add install-project.sh tests
git commit -m "feat: inspect project runtime without assumptions"
```

Expected: target hashes unchanged and `failures=0`.

### Task 6: Complete operator documentation and CI

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Create: `docs/SETUP.md`
- Create: `docs/CONFIGURATION.md`
- Create: `docs/VALIDATION.md`
- Create: `docs/TROUBLESHOOTING.md`
- Create: `SECURITY.md`
- Create: `CONTRIBUTING.md`
- Create: `.github/workflows/test.yml`
- Create: `tests/secret_safety_test.sh`
- Modify: `tests/test.sh`

**Interfaces:**
- Consumes: implemented entrypoints and accepted authority/invariants.
- Produces: clone-and-agent-run onboarding, operational status semantics, troubleshooting, public contribution/security guidance, and CI.

- [ ] **Step 1: Add the failing secret-safety test**

Scan tracked files for private key blocks, token/password assignments, live backup names, runtime UUID records, and accidental `~/.paseo/config.json` copies. Use explicit sanitized allowlist fixtures only.

```bash
bash tests/secret_safety_test.sh
```

Expected: initial nonzero until documentation/ignore rules and scanner allowlists agree.

- [ ] **Step 2: Write English operator documentation**

Document one-command setup, human authentication checkpoint, ownership, exact rollback location, status meanings, model/provider independence, tool-policy limitation, project-runtime pending behavior, A-G gate, and current runtime/schema differences. `AGENTS.md` becomes the complete operational entrypoint without redefining V0.2.

- [ ] **Step 3: Add CI**

CI runs `bash -n`, `jq empty` over policy/fixtures, `bash tests/test.sh`, and `git diff --check` on Ubuntu. It does not mutate a real home or require provider credentials.

- [ ] **Step 4: Verify and commit**

```bash
bash tests/secret_safety_test.sh
bash tests/test.sh
git diff --check
git add README.md AGENTS.md docs SECURITY.md CONTRIBUTING.md .github tests .gitignore
git commit -m "docs: add Paseo bootstrap operations and CI"
```

Expected: fixture/secret suite passes; no whitespace errors.

### Task 7: Apply and validate on the actual Paseo host

**Files:**
- Create: `records/validation/2026-09-24-host-bootstrap.md`
- Modify only through `install.sh`: selected host `config.json` and native skill installation state.

**Interfaces:**
- Consumes: fully green fixture suite and live host state.
- Produces: backup path/SHA, sanitized changed-field list, two-run idempotency evidence, real provider/profile/skill discovery, and capability-boundary results.

- [ ] **Step 1: Run full repository verification before host mutation**

```bash
bash tests/test.sh && git diff --check
```

Expected: `failures=0`; clean diff check.

- [ ] **Step 2: Run a dry-run against the selected host**

```bash
bash install.sh --dry-run
```

Expected on the currently observed host: only `Planning / Research.provider` and `Review.provider` change from `codex` to `codex-worker`; models/thinking and unrelated fields remain unchanged. Any wider or secret-bearing diff is a stop condition.

- [ ] **Step 3: Apply the safe reconciliation**

```bash
bash install.sh
bash verify.sh --json
```

Expected: timestamped backup with SHA, atomic apply, native reload, all three provider IDs available, five configured profiles, four native skills, and `READY` or an evidence-backed `AUTH_REQUIRED`. Reload failure triggers automatic restore and `BLOCKED`.

- [ ] **Step 4: Prove idempotency**

Record config SHA and backup count, run `bash install.sh` twice more, then compare. Expected: identical config SHA, no new backup on no-op runs, no duplicate providers/profiles.

- [ ] **Step 5: Prove the capability boundary with new sessions**

Use native Paseo MCP to create fresh Lead, Codex worker, and OpenCode worker sessions. Lead must successfully access `list_profiles`, `create_agent`, and `create_workspace`. Each worker must attempt `create_agent` and receive denial/unavailability while retaining normal read/coding tools. Archive only test agents/workspaces created by this phase.

- [ ] **Step 6: Record sanitized evidence and commit**

The record distinguishes implemented, fixture-tested, runtime-tested, and blocked/not tested. It includes no raw config, credentials, agent IDs, session IDs, or transcript dump.

```bash
git add records/validation/2026-09-24-host-bootstrap.md
git commit -m "test: record Paseo host bootstrap validation"
```

### Task 8: Run smoke tests A-G and publish the final implementation report

**Files:**
- Create: `records/validation/2026-09-24-smoke-tests.md`
- Create: `records/validation/2026-09-24-final-report.md`
- Modify: `README.md` status only after evidence is complete.

**Interfaces:**
- Consumes: passing capability boundary, clean test repository, native Paseo agents/workspaces/skills/permissions.
- Produces: observable A-G evidence, failure classification, final required report, and the only allowed operational-validation decision.

- [ ] **Step 1: Run smoke Preflight and Test A**

Prove daemon/MCP/profile/provider/skill readiness, then launch three restricted read-only researchers concurrently in the same workspace. Record parentage, provider/profile, clean Git state, reports, and Lead synthesis.

- [ ] **Step 2: Run Tests B and C**

Create one Paseo worktree workspace, launch a restricted Implementer for one bounded fixture change, commit the exact state, and launch a fresh restricted Reviewer in the same workspace. Record isolation, verification, commit SHA, no reviewer mutation, and `ACCEPT` or `REQUEST_CHANGES`.

- [ ] **Step 3: Run Test D**

Create two different worktree workspaces for non-overlapping fixture changes and run both Implementers concurrently. Record distinct workspace/worktree/branch state, clean base checkout, separate verification, and integration reasoning. Archive only these test workspaces after evidence is preserved.

- [ ] **Step 4: Run Test E with native skills**

Use `/paseo-handoff`, `/paseo-advisor`, and `/paseo-committee` exactly as installed. Record compact responsibility transfer, non-mutating advisor result, two independent committee analyses, and Lead synthesis.

- [ ] **Step 5: Run Test F**

Create a test worker, follow up in the same context, observe status/activity, start a safe long-enough turn, cancel it, prove the agent remains reusable, then archive it. Do not use permanent kill.

- [ ] **Step 6: Run Test G**

Trigger a safe provider permission request, verify it is visible, prove the worker cannot self-approve, exercise deny, and allow only a low-risk request when policy permits. No destructive/high-impact action is used.

- [ ] **Step 7: Classify every non-pass and write the final report**

Use only `CONFIG`, `PROMPT/POLICY`, `PASEO GAP`, `PROJECT GAP`, `MODEL/PROVIDER GAP`, or `ARCHITECTURE GAP`. Report Paseo version, bootstrap status, host policy, provider/profile/skill status, ownership/backup/idempotency/secret results, boundary result, A-G matrix, gaps/mismatches, architecture changes, remaining project runtime work, and next action.

- [ ] **Step 8: Apply the operational-validation gate and commit**

Set `OPERATIONALLY VALIDATED` only if real-host Preflight and every A-G test pass. Otherwise set `DESIGN COMPLETE / OPERATIONAL VALIDATION PENDING` with explicit FAIL/BLOCKED entries.

```bash
bash tests/test.sh
git diff --check
git add records/validation README.md
git commit -m "test: report Design Agent Team V0.2 validation"
```

Expected: repository suite green; report wording matches actual A-G evidence exactly.

## Human-gated stop points

Stop before any architecture change, broader-than-planned config mutation, removal of unrelated providers/profiles, credential/auth-state change, production access, destructive workspace action outside test-owned workspaces, canonical merge, or publication/push of the implementation branch. A model/provider incompatibility that cannot preserve both the user preference and a restricted capability class is reported as `MODEL/PROVIDER GAP`, not silently repaired.
