# Layered debugging and evidence diagnostics

Use this methodology after an engineering failure, an unexpected result, or a
behavioral evaluation finding needs diagnosis. It improves how the Lead and
scoped workers reason from observations to an authorized correction. It does
not execute checks, diagnose automatically, retry work, monitor systems, or
grant authority.

The authority and runtime flow remains:

```text
Human commitments and constraints
        ↓
Lead reasoning and policy
        ↓
Paseo runtime
        ↓
Paseo Profiles and scoped workers
```

Keep the four layers in order. A later layer may reveal that more evidence is
needed; return to the evidence layer instead of promoting a guess to a root
issue.

## 1. Symptom layer

Describe what was observed before explaining why it happened. A useful symptom
record contains:

- the exact state, command, check, or interaction observed;
- the expected result and the actual result;
- the smallest reproducible boundary currently known;
- the time or state identity when freshness matters; and
- what is missing or still unknown.

Examples include a failed validation, unexpected output, missing evidence,
incorrect scope, or an integration conflict. Write `root issue not determined`
when the available observation does not establish a cause. Do not turn an error
message, a historical incident, or a proposed workaround into a root-cause
claim.

## 2. Evidence layer

Collect only evidence relevant to the symptom, in this order:

1. Read the current task contract: goal, authority, scope, acceptance criteria,
   verification plan, stop conditions, and exact starting state.
2. Inspect the current changed paths and diff without discarding pre-existing
   work.
3. Read the focused test or validation command, its complete current outcome,
   and any directly related logs or artifacts.
4. Inspect current runtime output only when the symptom depends on runtime
   behavior and the observation is authorized and safe.
5. Read applicable repository instructions and canonical architecture or
   project rules, following their authority order.
6. Consult previous decisions, incidents, or evaluation records only after the
   current state is known. Record their identity and verify any drift-prone
   claim before using it as current evidence.

For each item, distinguish:

- **observed:** directly supported by the current command, file, diff, or
  runtime observation;
- **reported:** stated by a task, worker, or historical record but not yet
  independently observed in the current state;
- **inferred:** a hypothesis that explains evidence but still needs a
  discriminating check; and
- **unknown:** evidence is missing, unsafe to collect, or blocked.

Evidence collection is proportional. Do not open broad logs, histories, or
unrelated files when a focused observation can distinguish the hypotheses. Do
not collect credentials, private runtime state, or Paseo-owned identifiers in a
committed record.

## 3. Classification layer

Choose the narrowest diagnostic category supported by the evidence. These are
plain-language diagnostic categories, not new finding codes, outcomes, or an
additional failure taxonomy.

| Category | Use when | Existing integration |
|---|---|---|
| Governance issue | Authority, mode, evidence, review, or human-checkpoint policy is missing, ambiguous, or not followed | Apply [Phase 1 Governance](../GOVERNANCE.md); operational disposition is commonly `PROMPT/POLICY` when the evidence supports it |
| Task-contract issue | Scope, acceptance, verification, constraints, or escalation terms are missing or ambiguous | Correct the [adaptive task contract](../templates/task-contract.md) prospectively; do not broaden it retroactively |
| Behavioral evaluation finding | Observed subject behavior matches an existing canonical `BE-*` condition | Record only codes from the [failure taxonomy](../evals/failure-taxonomy.md) and preserve the evaluation outcome |
| Recovery issue | Diagnosis, authorized correction, verification, or closure does not satisfy the existing recovery protocol | Use the [recovery playbooks](../evals/recovery-playbooks.md); a retry or disappearing symptom is not closure |
| Repository/test issue | Current source, configuration committed to the project, test, fixture, build, or integration evidence establishes a project-local defect | Use the repository's existing checks and report the applicable operational disposition only when supported |
| Environment issue | Current host, toolchain, provider, dependency, authentication, or runtime evidence establishes an external execution condition | Use only the repository's existing operational classifications and escalate when current evidence cannot distinguish them |

The diagnostic category answers where to investigate or correct. It does not
replace:

- evaluation outcomes: `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN`;
- canonical `BE-*` findings;
- operational classifications: `CONFIG`, `PROMPT/POLICY`, `PASEO GAP`,
  `PROJECT GAP`, `MODEL/PROVIDER GAP`, or `ARCHITECTURE GAP`; or
- repository-specific test and error names.

Record more than one category only when separate observations independently
support them. In particular, do not label a symptom `PASEO GAP` merely because
a proposed workaround would run outside Paseo. A `PASEO GAP` requires current
runtime evidence that a required native capability is absent.

## 4. Correction layer

Select the smallest correction that addresses the supported root issue and is
inside the current authority and write scope.

1. State the supported root issue, or keep it `not determined` and name the next
   discriminating observation.
2. Identify the smallest authorized correction. Do not bundle cleanup,
   architecture changes, or unrelated improvements.
3. Name the focused verification that can show whether the correction worked.
4. Add broader regression, integration, runtime, or independent-review checks
   required by the task contract and repository policy.
5. Preserve failed evaluation evidence. A corrected run is new evidence and
   does not rewrite the original `FAIL`.

Escalate instead of correcting when:

- evidence cannot distinguish causes safely;
- the correction would exceed the write scope or granted authority;
- sources conflict and the authority order does not resolve them;
- a destructive, production, credential, or other human commitment boundary is
  reached;
- current evidence indicates a possible architecture or Paseo capability gap;
- the same technical approach repeatedly fails; or
- required verification or independent review cannot be obtained.

Do not treat retrying the same action as diagnosis or verification. A retry is
permitted only when already authorized and justified by evidence; its result is
another observation, not proof of a root issue or durable correction.

## Proportional diagnostic record

Attach a diagnostic record to the existing task, evaluation, review, issue, or
handoff. Do not create an incident or debugging database.

```text
SYMPTOM: <expected versus observed behavior>
EXACT_STATE: <commit, tree, command context, or sanitized runtime state>
EVIDENCE: <ordered observed, reported, inferred, and unknown items>
DIAGNOSTIC_CATEGORY: <one existing category, or multiple with separate evidence>
BE_FINDINGS: <canonical BE-* codes, none, or not evaluated>
OPERATIONAL_CLASSIFICATION: <existing repository class or not determined>
ROOT_ISSUE: <evidence-supported cause or not determined>
AUTHORIZED_CORRECTION: <smallest in-scope action or escalation>
VERIFICATION: <required commands or observations and outcomes>
REVIEW: <exact reviewed state and verdict when required>
RESIDUAL_UNCERTAINTY: <remaining unknowns>
```

The [static debugging calibration examples](../../tests/fixtures/behavioral-evals/debugging-cases.json)
show common reasoning failures and expected diagnostic responses. They are
documentation and reviewer-calibration data only. They do not execute an agent,
infer a cause, retry work, or establish live behavior.
