# Paseo Workflow

`paseo-workflow` is the reproducible WSL bootstrap distribution for the
Design Agent Team V0.2 architecture.

The repository is currently in the specification phase. The accepted
implementation brief is:

- [`docs/specs/2026-09-24-paseo-workflow-bootstrap-v1.md`](docs/specs/2026-09-24-paseo-workflow-bootstrap-v1.md)

The bootstrap implementation must remain Paseo-native. It must not introduce a
custom workflow controller, agent runtime, workspace manager, provider router,
permission queue, scheduler, or orchestration state machine.

## Status

```text
DESIGN COMPLETE / IMPLEMENTATION PLAN PENDING
```

Do not report `OPERATIONALLY VALIDATED` until the required real-host preflight
and smoke tests A-G all pass with observable evidence.

## License

MIT. See [`LICENSE`](LICENSE).
