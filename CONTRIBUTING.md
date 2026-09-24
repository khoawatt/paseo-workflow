# Contributing

Changes must preserve the accepted V0.2 authority order and architecture
invariants. Do not introduce a custom orchestration controller or rebuild a
native Paseo capability without measured runtime evidence and an explicit
architecture decision.

Before submitting a change:

```bash
bash -n install.sh verify.sh install-project.sh bin/reconcile-config
bash tests/test.sh
git diff --check
```

Add fixture tests before behavior changes. Keep host mutation out of tests and
CI. Preserve unknown/user-owned configuration, keep records sanitized, and do
not commit auth material, live configs/backups, or runtime IDs.

Document whether evidence is implemented, fixture-tested, runtime-tested, or
not tested/blocked. Any real-host destructive or high-impact validation remains
human-gated.
