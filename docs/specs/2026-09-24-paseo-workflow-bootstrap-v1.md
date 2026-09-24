# Paseo Workflow Bootstrap V1

## V0.2-Aligned Implementation Brief

Status: **Accepted design specification**  
Platform: **WSL2 Ubuntu only**  
License: **MIT**

## 1. Objective

Upgrade this repository from a knowledge/documentation repository into a
reproducible bootstrap distribution for the existing Design Agent Team V0.2
architecture.

The bootstrap must reproduce the host/runtime state defined by:

```text
ai-agent/architecture/paseo-codex-execution-brief-v0.2.md
```

and its current V0.2 source-of-truth documents.

The bootstrap is not a new orchestration architecture.

```text
Design Agent Team V0.2 = runtime architecture
paseo-workflow bootstrap = reproducible distribution of that architecture
```

Target experience:

```text
Fresh WSL Ubuntu Paseo host
with user-installed/authenticated Codex and OpenCode prerequisites
        ↓
git clone <paseo-workflow-repo>
        ↓
Agent reads AGENTS.md
        ↓
bash install.sh
        ↓
Paseo installed/configured
        ↓
Providers + Profiles + Skills reconciled
        ↓
Verification
        ↓
READY / AUTH_REQUIRED / BLOCKED
        ↓
Core smoke tests A-G
        ↓
Bootstrap regression suite + idempotency + secret safety
        ↓
OPERATIONALLY VALIDATED
for the bootstrap/orchestration distribution only,
and only if the complete gate actually passes
```

## 2. Authority order

The bootstrap repository must not silently redefine V0.2 runtime behavior.

1. Actual current Paseo runtime behavior.
2. Current official Paseo documentation.
3. `paseo-codex-execution-brief-v0.2.md`.
4. V0.2 architecture/specification files referenced by that brief.
5. Bootstrap implementation policy.
6. `AGENTS.md` operational instructions.

If current Paseo runtime/docs contradict the V0.2 architecture:

```text
inspect
→ report mismatch
→ propose smallest Paseo-native adjustment
→ continue only with the compatible solution
```

Do not work around a mismatch by creating a custom orchestration controller.

## 3. Mandatory architecture invariants

Preserve these V0.2 decisions:

```text
Paseo = orchestration runtime
Lead Agent = technical orchestrator
Workers = scoped execution
GitHub = durable engineering collaboration
storage = curated long-lived architecture/knowledge
custom workflow controller = NOT REQUIRED
```

Do not build a custom TypeScript Workflow Controller, agent runtime, spawn
service, workspace/worktree manager, provider router, message bus, permission
queue, scheduler/heartbeat system, report database, or orchestration state
machine unless a measured Paseo gap from real validation proves such
infrastructure necessary.

Configuration or prompt/policy failures must not be solved by inventing
infrastructure.

## 4. V1 platform scope

V1 supports WSL2, Ubuntu, Bash, apt-compatible dependencies, Node.js/npm, and
the Paseo CLI/runtime. Codex and OpenCode CLIs are external user/host-owned
prerequisites: the user installs, updates, selects, and authenticates them.
Bootstrap V1 only preflights their native Paseo diagnostics and availability.
Do not expand V1 to macOS or native Linux yet.

## 5. Bootstrap architecture

```text
git clone paseo-workflow
        ↓
Agent reads AGENTS.md
        ↓
bash install.sh
        ↓
Preflight WSL / Ubuntu
        ↓
Inspect actual host state
        ↓
Install required dependencies
        ↓
Install/upgrade pinned supported Paseo version
        ↓
Preflight user-managed Codex/OpenCode runtimes and authentication
        ↓
Inspect ~/.paseo/config.json
        ↓
Timestamped backup
        ↓
Ownership-aware configuration merge
        ↓
Reconcile required provider capability classes
        ↓
Reconcile V0.2 Agent Profiles
        ↓
Install/verify native orchestration skills
        ↓
Reload/start native Paseo runtime
        ↓
Run verification
        ↓
READY / AUTH_REQUIRED / BLOCKED
```

The bootstrap must be idempotent. Repeated `bash install.sh` executions must
converge to the same valid state without duplication or corruption.

## 6. Bootstrap is not runtime orchestration

`install.sh` only prepares and reconciles a host. It must not become part of
the normal Design Agent Team execution path.

Correct:

```text
install.sh → configure host → finish
Human → Paseo → Lead → Workers
```

Incorrect:

```text
Lead → bootstrap controller → custom workflow state → worker → Paseo
```

After installation, native Paseo orchestration remains in control.

## 7. Required entrypoints

### `install.sh`

The machine-level, idempotent bootstrap validates the platform; inspects the
actual host; installs/checks dependencies and Paseo; backs up configuration;
performs the ownership-aware merge; reconciles providers, profiles, and skills;
reloads Paseo; runs `verify.sh`; and returns the final state.

It must not install, upgrade, replace, or authenticate Codex/OpenCode provider
runtimes. A missing external runtime is `BLOCKED` with an exact installation and
PATH next action. An installed runtime requiring interactive login is
`AUTH_REQUIRED`. A healthy existing runtime is reused unchanged.

### `verify.sh`

Verification must use actual Paseo state:

```text
repository invariants
        ↓
Paseo runtime/config inspection
        ↓
provider/profile discovery
        ↓
capability checks
        ↓
bootstrap status
```

Prefer native Paseo commands/runtime responses. Do not unnecessarily rebuild
Paseo's own validator.

### `tests/test.sh`

Fixture tests must cover configuration merge, preservation, idempotency,
unknown-field preservation, secret safety, provider/profile reconciliation,
model-preference preservation, backup behavior, and atomic-write behavior.

### `install-project.sh <repo>`

This entrypoint may prepare an existing project for Paseo use, but it must
follow the V0.2 project-runtime contract and inspect the real project first.

```text
target repository exists?
        ├─ NO → PROJECT_RUNTIME_PENDING
        └─ YES
             ↓
        inspect actual scripts
             ↓
        inspect services / environment
             ↓
        derive smallest valid Paseo project runtime
             ↓
        verify against real repository
```

Do not assume test/dev commands, ports, services, or frontend/backend topology.
Do not invent `<repo>/paseo.json` or any project runtime before the target
repository exists and its real scripts are inspectable.

Bootstrap validation is project-agnostic. It proves host bootstrap,
provider/profile policy, native orchestration primitives, worktree isolation,
review flow, lifecycle controls, skills, permissions, idempotency,
preservation, and secret safety. Project-specific validation occurs later and
locally when an actual repository adopts this bootstrap; it is not a
prerequisite for Bootstrap V1 operational validation.

## 8. Configuration ownership

### Repository-owned

The bootstrap may reconcile required provider capability classes, architecture-
owned Paseo tool policy, required Agent Profile role mapping and behavioral
notes, required native orchestration skills, required daemon MCP injection
settings, and bootstrap invariants.

### User-owned

Preserve credentials, tokens, authentication state, preferred models, thinking-
level preferences, personal provider configuration, unrelated Agent Profiles,
and unrelated Paseo configuration unless explicitly instructed otherwise.

### Runtime/host-owned

Do not version-control agent/session/workspace IDs, daemon transient state,
runtime worktree state, temporary host state, or live configuration backups.

## 9. Merge policy

Never replace the user's complete configuration with a golden configuration.

```text
existing host config
        +
repository-owned V0.2 policy
        ↓
ownership-aware merge
        ↓
validation
        ↓
atomic write
        ↓
paseo reload
```

Rules:

1. Inspect before mutation.
2. Back up before mutation.
3. Preserve unknown fields unless explicitly repository-owned.
4. Preserve credentials.
5. Preserve unrelated providers.
6. Preserve unrelated profiles.
7. Preserve user model preferences where architecture permits.
8. Reconcile architecture-owned provider/profile policy.
9. Write atomically.
10. Reload Paseo.
11. Validate immediately.
12. Never report success when validation failed.

## 10. Required V0.2 provider capability classes

```text
codex-lead
→ extends codex
→ Lead-capable
→ receives Paseo orchestration catalog

codex-worker
→ extends codex
→ paseoTools.enabled = false

opencode-worker
→ extends opencode
→ paseoTools.enabled = false
```

Use the actual current Paseo schema. Do not blindly copy examples if runtime
field names or structures differ.

## 11. No mandatory `*-isolated` class

A future `*-isolated` capability class may help with untrusted workloads but is
not required for V0.2. Prefer provider-native sandbox controls or stronger host/
container isolation when needed. Do not add provider classes without a current
architecture or measured runtime requirement.

## 12. Provider policy terminology

Provider ID plus `paseoTools` defines a Paseo tool-capability boundary, not a
hard host security boundary.

```json
"paseoTools": {
  "enabled": false
}
```

This means Paseo orchestration tools are not injected into the worker's tool
catalog. It does not prove that the process can never reach Paseo through a
shell/CLI or other host capability. Document this limitation clearly.

## 13. Runtime permission model

Keep these independent:

```text
Paseo tool policy → Paseo orchestration catalog
provider-native sandbox/permissions → filesystem/network/command capabilities
human approval boundary → whether a high-impact action may proceed
```

Default direction:

- Lead: broad engineering capability, Paseo orchestration tools, with high-
  impact actions human-gated.
- Planning/Research: restricted provider, read-only where practical, no
  orchestration tools.
- Implementation: restricted provider, assigned-worktree write access, no
  orchestration tools.
- Review: restricted provider, read-only where practical, no orchestration
  tools.

Use provider-native options rather than inventing a universal sandbox schema.

## 14. Required V0.2 Agent Profiles

Reconcile exactly these role profiles:

```text
Lead
Planning / Research
Implementation
Review
Specialist
```

Do not create a permanent Integration profile in V0.2. Integration remains an
optional temporary role.

## 15. Profile routing preserves V0.2 preferences

Do not canonicalize every worker role to `codex-worker`.

```text
Lead
→ codex-lead

Planning / Research
→ opencode-worker preferred
→ another worker-restricted provider as fallback

Implementation
→ codex-worker preferred
→ another strong restricted coding provider as fallback

Review
→ restricted provider
→ fresh context
→ prefer provider/model diversity from Implementation when practical
→ diversity is a preference, not an absolute rule

Specialist
→ restricted provider/model chosen according to domain
```

A role maps to a capability class. Provider/model selection inside the allowed
class may still vary.

## 16. Profile is not provider ID

```text
Agent Profile = role-oriented launch preset + delegation notes
Provider ID = runtime capability/tool-policy identity
```

The Lead resolves profile settings into native Paseo launch parameters. Do not
invent unsupported profile fields; use the actual schema.

## 17. Model-selection policy

Model strength remains independent from orchestration authority:

```text
changing model must not silently elevate the provider capability class
```

Selection precedence:

1. Explicit human-requested model.
2. Existing/user profile preference.
3. Profile default.
4. Lead discovers/selects an appropriate available model.

If the human requests the strongest Review model, use a restricted review-
capable provider plus a strong model. Do not switch Review to `codex-lead` merely
because that model is stronger.

## 18. Preserve user model preferences

When a required profile currently uses an unrestricted provider but has a user-
preferred model/thinking level, the bootstrap may change the architecture-owned
provider while preserving compatible user-owned model and thinking settings.

If the preferred model is unavailable on the required provider, report the
incompatibility rather than silently weakening architecture boundaries.

## 19. Required native Paseo settings

Inspect actual host configuration and ensure the current equivalents of these
V0.2 requirements are satisfied:

```text
daemon.mcp.enabled = true
daemon.mcp.injectIntoAgents = true
```

Use the actual schema and do not duplicate equivalent configuration. After host
configuration changes, run `paseo reload` and verify new sessions receive the
expected catalog. Existing sessions may retain their launch-time catalog.

## 20. Required native orchestration skills

Ensure these native skills are installed and available:

```text
/paseo
/paseo-handoff
/paseo-committee
/paseo-advisor
```

Use Paseo-native installation/settings. Do not create replacements.

Current public Paseo documentation exposes the upstream
`npx skills add getpaseo/paseo` installation flow and host startup refresh, but
does not document a reproducible skill-version pin contract. V1 therefore
records this upstream dependency and verifies installed skill presence; it does
not vendor the skills or build a custom installer.

## 21. Authentication

Authentication remains human-controlled where credentials or authorization are
interactive. The bootstrap must never collect passwords, commit credentials,
copy tokens into repository configuration, write live auth state into records,
or pretend authentication succeeded.

Return `AUTH_REQUIRED` with an exact next action when user interaction is
necessary, then allow verification to be rerun. Missing external provider
binaries are `BLOCKED`, not `AUTH_REQUIRED`; the bootstrap reports the exact
host installation/PATH action and never installs them itself.

## 22. Bootstrap status

### `READY`

Host/bootstrap prerequisites, required provider/profile/skill policy, and
configuration validation are satisfied. This does not mean the architecture is
operationally validated.

### `AUTH_REQUIRED`

Structural bootstrap is valid, but a required provider/account needs human
authentication.

### `BLOCKED`

A prerequisite or safety issue prevents completion. Report the reason, affected
component, evidence, and recommended next action.

## 23. Bootstrap readiness vs operational validation

```text
BOOTSTRAP READY ≠ OPERATIONALLY VALIDATED
```

Bootstrap V1 becomes `OPERATIONALLY VALIDATED` only after the required
real-host V0.2 smoke tests, bootstrap regression suite, live idempotency, and
secret-safety checks pass. This classification applies only to the bootstrap
and orchestration distribution. It does not validate project runtime for any
future adopting repository. Otherwise report:

```text
DESIGN COMPLETE / OPERATIONAL VALIDATION PENDING
```

## 24. Validate the capability boundary before smoke tests

Before Test A, prove on the real host that Lead can access expected Paseo
orchestration capabilities, while `codex-worker` and `opencode-worker` do not
receive `create_agent`. Also prove workers retain the normal coding/research
capabilities required for their roles.

If this fails, stop broader smoke tests, classify the problem, and fix
configuration/policy first. Do not compensate with new infrastructure.

## 25. Required core smoke tests A-G

Use `paseo-orchestration-smoke-tests-v0.2.md` and run in order:

```text
Preflight
A. Fan-out read-only research
B. One isolated implementation worktree
C. Implement + fresh independent review
D. Two parallel implementation worktrees
E. Native handoff / advisor / committee
F. Follow-up / redirect / cancel / archive
G. Runtime permission boundary
```

A test passes only with observable evidence, never assumption or prose alone.

## 26. Review rule

For code-writing flows:

```text
Implementer
→ exact reviewable state
→ fresh Reviewer
→ ACCEPT or REQUEST_CHANGES
```

Prefer a clean implementation state and commit SHA.

Any implementation change after a review invalidates that review. The exact
final implementation state must receive a fresh independent Reviewer `ACCEPT`
before the Lead may report the work as `DONE`.

Independent write workers must use separate Paseo worktrees by default. A
shared working tree is allowed only as an explicit fallback, must be reported
clearly, and Git history must not be reconstructed afterward to imply isolation
that did not actually occur.

The Reviewer must not patch code and approve its own patch. Allow at most two
automatic rework rounds for the same technical approach, then return control to
Lead for diagnosis.

## 27. Failure classification

Classify validation failures before changing architecture:

```text
CONFIG
PROMPT/POLICY
PASEO GAP
PROJECT GAP
MODEL/PROVIDER GAP
ARCHITECTURE GAP
```

Configuration or prompt/policy failures must not trigger a custom controller or
orchestration subsystem.

## 28. High-impact actions

Destructive and high-impact actions remain human-gated, including removing
unrelated providers, deleting user profiles, overwriting credentials,
destructive migration, data deletion, production changes, security/compliance
tradeoffs, large scope expansion, canonical-branch merge, and destructive
workspace/worktree actions. Stop and request human approval; do not guess.

## 29. `AGENTS.md`

`AGENTS.md` is the operational bootstrap entrypoint. It must explain what the
repository and Paseo each own; V0.2 source-of-truth order; supported platform;
installation; authentication; provider capability classes; Agent Profile
routing; model selection; configuration ownership; verification and statuses;
smoke tests; tool-policy limitations; and troubleshooting. It must point to the
official architecture artifacts rather than redefine them.

## 30. Repository layers

```text
paseo-workflow
│
├── Bootstrap
│   ├── install.sh
│   ├── install-project.sh
│   └── verify.sh
│
├── Policy
│   ├── provider policy
│   ├── profile policy
│   ├── ownership policy
│   └── model-selection rules
│
├── Knowledge
│   ├── AGENTS.md
│   ├── skills/
│   └── docs/
│
└── Validation
    ├── fixture tests
    ├── capability checks
    └── V0.2 smoke tests
```

Adapt this to existing repository structure; do not create duplicate trees when
appropriate files already exist.

## 31. Configuration-merge tests

At minimum cover:

- Fresh host/no configuration.
- Existing valid configuration.
- Existing unknown fields.
- Existing unrelated provider.
- Existing unrelated profile.
- Required profile with incorrect provider.
- Required profile with custom user model.
- Required profile with custom thinking level.
- Existing credentials/authentication fields.
- Partially installed Paseo.
- Already-correct installation.
- Invalid bootstrap configuration fragment.
- Rerun/idempotency behavior.

Expected behavior must be explicit for each fixture.

## 32. Secret safety

Never commit or store API/OAuth tokens, session cookies, passwords, refresh
tokens, live host backups, runtime agent/session IDs, or private authentication
state in repository-controlled files.

## 33. Records

If `records/` is used, limit it to sanitized bootstrap smoke reports, migration
notes, release verification reports, and host-validation summaries. Never copy
real `~/.paseo/config.json` backups there.

## 34. Paseo-native-first rule

Before implementing any mechanism, check whether Paseo already provides it. Do
not rebuild agent lifecycle/delegation, handoff/advisor/committee, workspace and
worktree management, agent messaging/status/activity, cancel/archive, provider
and model discovery, Agent Profiles, permissions, schedules, heartbeats, Hub
dispatch, or remote daemon control.

## 35. Implementation order

1. Read the V0.2 execution brief and referenced architecture files.
2. Inspect the current repository structure.
3. Inspect the actual current Paseo host/runtime/schema.
4. Compare actual host state with V0.2 requirements.
5. Define repository-owned, user-owned, and runtime-owned fields.
6. Implement/test ownership-aware configuration merge.
7. Implement `install.sh`.
8. Reconcile `codex-lead`, `codex-worker`, and `opencode-worker`.
9. Reconcile the five V0.2 Agent Profiles.
10. Install/verify native orchestration skills.
11. Implement `verify.sh`.
12. Implement fixture tests.
13. Implement `install-project.sh` without inventing project runtime.
14. Update `AGENTS.md`.
15. Update supporting bootstrap documentation.
16. Run idempotency tests.
17. Run capability-boundary validation.
18. Run V0.2 smoke tests A-G where the real host permits.
19. Produce one sanitized final implementation report.

Validate after every meaningful phase.

## 36. Required final report

Report:

```text
Paseo version

Bootstrap status: READY / AUTH_REQUIRED / BLOCKED

Host policy status

Provider IDs created/updated

Agent Profiles status

Skills status

Config ownership policy implemented

Backup/merge behavior

Idempotency result

Secret-safety result

Capability-boundary result

Smoke tests A-G: PASS / FAIL / BLOCKED

Observed Paseo gaps

Observed runtime/docs vs V0.2 mismatches

Architecture changes required, if any

Future adopter/project-runtime considerations, if any

Next recommended action
```

For every important result, distinguish implemented, fixture-tested, runtime-
tested, and not-tested/blocked. Do not claim success from static inspection.

## 37. Operational-validation gate

Only report `OPERATIONALLY VALIDATED` for Bootstrap V1 when all of the following
pass with observable evidence:

```text
Preflight
+ A + B + C + D + E + F + G
+ bootstrap regression suite
+ live idempotency
+ secret-safety checks
```

This classification applies only to the bootstrap/orchestration distribution.
Project-specific validation remains local to each future adopting repository.
Otherwise report `DESIGN COMPLETE / OPERATIONAL VALIDATION PENDING` or the
appropriate blocked/failure status.

## 38. V1 non-goals

Do not implement a custom TypeScript workflow controller, orchestration engine,
workflow-state database, provider router, permission queue, scheduler, macOS
bootstrap, native Linux bootstrap, mandatory `*-isolated` class, hard OS-level
sandbox framework, automatic credential collection, golden-config replacement,
or project-runtime assumptions for uninspected repositories.

## 39. Frozen V1 architecture invariants

- Paseo is the orchestration runtime.
- The Lead is the technical orchestrator.
- Workers perform scoped execution.
- The bootstrap reproduces V0.2; it does not redefine V0.2.
- There is no custom Workflow Controller in V0.2.
- Provider IDs represent runtime capability classes.
- Agent Profiles represent engineering-role launch presets.
- Model intelligence is independent from orchestration authority.
- `codex-lead` is the required Lead capability class.
- `codex-worker` and `opencode-worker` are required restricted worker classes.
- Planning/Research prefers `opencode-worker`.
- Implementation prefers `codex-worker`.
- Review uses a fresh restricted provider/session and prefers diversity when
  practical.
- Specialist uses a domain-appropriate restricted provider.
- `paseoTools.enabled = false` is a tool-capability boundary, not a host security
  sandbox.
- Provider-native sandbox/permissions remain separate.
- High-impact actions remain human-gated.
- Preserve existing unrelated configuration and credentials.
- Preserve compatible user model preferences.
- Configuration writes require backup and atomic mutation.
- The bootstrap must be idempotent.
- Project runtime must be derived from the real project, never guessed.
- `READY` means bootstrap-ready, not operationally validated.
- Any implementation change after a review invalidates that review. The exact
  final implementation state must receive a fresh independent Reviewer
  `ACCEPT` before the Lead may report the work as `DONE`.
- Independent write workers must use separate Paseo worktrees by default. A
  shared working tree is allowed only as an explicit fallback, must be reported
  clearly, and Git history must not be reconstructed afterward to imply
  isolation that did not actually occur.
- Preflight, A-G, the bootstrap regression suite, live idempotency, and
  secret-safety checks form the Bootstrap V1 operational-validation gate.
- Project-specific validation is separate, local to the adopting repository,
  and not a Bootstrap V1 completion prerequisite.

Implement against these constraints using the smallest Paseo-native solution
possible.
