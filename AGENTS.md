# AGENTS.md

This repository distributes the existing Design Agent Team V0.2 architecture.
It does not define a new orchestration architecture.

## Current phase

Implementation has not started. Read the accepted specification before making
changes:

```text
docs/specs/2026-09-24-paseo-workflow-bootstrap-v1.md
```

Do not invent bootstrap behavior beyond that specification. In particular, do
not add a custom TypeScript workflow controller or rebuild capabilities already
provided by Paseo.

## Authority order

1. Actual current Paseo runtime behavior.
2. Current official Paseo documentation.
3. `paseo-codex-execution-brief-v0.2.md`.
4. V0.2 architecture/specification files referenced by that brief.
5. The accepted bootstrap specification in this repository.
6. Operational instructions in this file.

If current runtime behavior contradicts an architecture document, inspect and
report the mismatch, then propose the smallest Paseo-native compatible change.
Do not work around it by creating custom orchestration infrastructure.

## Safety

- Preserve existing credentials, providers, profiles, models, and unrelated
  Paseo configuration unless the accepted ownership policy explicitly owns a
  field.
- Inspect and create a timestamped backup before changing Paseo configuration.
- Use atomic writes and validate immediately after every meaningful phase.
- Stop for human approval before high-impact or destructive actions.
- Never commit credentials, authentication state, live host backups, agent IDs,
  workspace IDs, session IDs, or other transient runtime state.
- Treat `READY` as bootstrap readiness, not operational validation.
