# V0.2 Core Smoke Tests A-G

Date: 2026-09-24  
Host: WSL2 Ubuntu, sanitized  
Source: `paseo-orchestration-smoke-tests-v0.2.md`  
Overall status: `PASS`
Bootstrap V1 status: `OPERATIONALLY VALIDATED`
Scope: bootstrap/orchestration distribution only; no application project is
project-runtime validated by this result.

## Evidence policy

This record stores sanitized outcomes, provider/profile selections, git state,
verification results, and lifecycle behavior. Live agent, session, workspace,
and temporary worktree IDs are intentionally omitted. Fixture evidence is not
substituted for real-host agent execution.

## Preflight

Status: `PASS`

- Paseo CLI/daemon: `0.9.1`.
- `verify.sh --json` outside the restricted command sandbox: `READY` with
  config, providers, profiles, skills, and daemon available.
- Daemon MCP and agent injection settings: enabled.
- Native MCP discovery: required Lead and worker provider IDs available; all
  five profiles returned.
- Required native orchestration skills: installed and discoverable.
- Dedicated disposable smoke repository: clean `main` checkout; baseline shell
  verification passed.
- Call-level provider-policy prerequisite: PASS, as recorded in
  [Host Bootstrap and Capability Boundary
  Evidence](2026-09-24-host-bootstrap.md).

The managed command sandbox blocks loopback sockets. Running the verifier inside
that sandbox therefore reported the daemon unreachable even while native MCP
worked. Repeating the same verifier with loopback access returned `READY`, and a
direct loopback health request exited successfully. This is a validation-shell
constraint, not a Paseo runtime failure.

## A - Fan-out read-only research

Status: `PASS`

- One Lead used the `Planning / Research` profile to launch exactly three
  `codex-worker/gpt-5.6-sol` subagents in the same workspace.
- The three run windows overlapped and all were observed running concurrently.
- Researchers independently traced the Bash call path, assessed test coverage,
  and inspected dependency/configuration impact.
- All three returned reports and confirmed they created no subagents.
- Lead synthesized the shared finding: the fixture works for its documented
  case, while input/error behavior is intentionally minimal and undocumented.
- Every researcher reported a clean tree; final branch and commit matched the
  baseline, `git status --short` was empty, and `git diff --check` passed.

The ChatGPT advisory bridge was unavailable because its lock path was
read-only. Agents were redirected to continue without claiming consultation.
This did not alter the Paseo delegation outcome. A follow-up notification edge
required the Lead to be redirected to synthesize reports already present in its
timeline; no agent was respawned.

## B - One isolated implementation worktree

Status: `PASS`

- Lead created one Paseo-managed worktree on a dedicated branch from the clean
  baseline and launched exactly one Implementation-profile agent.
- Implementer used
  `opencode-worker/opencode/muse-spark-1.3-contributor-free` in `build/default`.
- Scope was exactly two new executable files: a standalone subtract function
  and its focused test.
- Existing add test and the new subtract test passed; `git diff --check`
  passed.
- Implementer reported native `create_agent` absent and created no child.
- Base `main` stayed clean and unchanged; implementation worktree finished
  clean at reviewable commit `e7fa96c1a6359a7aba930ecd881e20af39085575`.
- Worktree remained active for the independent review in Test C.

## C - Implement then independent review

Status: `PASS`

- Lead launched one fresh Review-profile session in the exact Test B worktree.
- Reviewer used restricted `codex-worker/gpt-5.6-sol`, providing provider
  diversity from the OpenCode Implementer.
- Initial and final HEAD matched reviewed commit
  `e7fa96c1a6359a7aba930ecd881e20af39085575`.
- Reviewer inspected the exact two-file scope, reran both tests and
  `git diff --check`, and confirmed the tree stayed clean.
- Verdict: `ACCEPT`.
- No code was modified and no child was delegated. Broader operand validation
  was recorded as outside the bounded acceptance criteria.

## D - Two parallel implementation worktrees

Status: `PASS`

- Lead created two distinct managed worktrees from the same clean baseline and
  launched one restricted OpenCode Implementation agent in each.
- Run windows overlapped. Worktree directories, branches, Git directories, and
  index files were distinct.
- Multiply branch committed only its source/test pair; absolute-value branch
  committed only its separate source/test pair. Both baseline and focused tests
  passed, both diff checks passed, and both trees finished clean.
- Commits were distinct and shared the unchanged clean `main` parent. Neither
  worktree contained the other task's files; base `main` remained clean.
- Lead assessed low integration conflict because the commits add disjoint file
  paths. No merge or cherry-pick was performed.

## E - Native handoff, advisor, and committee

Status: `PASS`

- Handoff: a self-contained briefing transferred completed A-D context,
  relevant files, decisions, failed attempts, constraints, and acceptance
  criteria. The receiving restricted agent produced an executable Test F
  checklist without needing the full transcript and made no edits.
- Advisor: a fresh restricted advisor independently recommended keeping the
  B-D branches unintegrated and using clean `main` for F-G. It identified the
  remaining lifecycle/permission evidence and made no edits.
- Committee: first Codex and Gemini launches failed before analysis because of
  account usage and model quota limits. This is classified
  `MODEL/PROVIDER GAP`; failed agents were archived and their errors were not
  treated as committee opinions. A restricted OpenCode fallback committee used
  two model families in read-only plan mode and produced two independent
  analyses.
- Committee members initially differed on whether Test F should use fresh
  agents per subcase. After exchanging arguments, both returned `CONVERGE` on
  the official same-agent sequence: follow-up/redirect, running-state cancel,
  post-cancel reuse, then archive last.
- Committee consensus for G was deny-first, no-persistence probing with three
  separately evidenced layers: Paseo tool policy, provider-native
  sandbox/permission, and human approval.
- All E agents made no repository edits. Provider diversity was attempted and
  was not practical because Codex and Gemini quota failures occurred before
  analysis; model-family diversity within the restricted OpenCode provider was
  used and the limitation is recorded rather than hidden.

## F - Follow-up, redirect, cancel, and archive

Status: `PASS`

- One restricted OpenCode worker/session was used for the complete sequence.
- Initial turn read the fixture; a follow-up on the same agent ran the baseline
  test and returned the unique follow-up marker.
- A corrective prompt sent while the agent was running replaced the old result
  marker with the redirect marker in the same timeline; no new agent appeared.
- A separate 90-second read-only turn was observed `running` with its shell wait
  active, then `cancel_agent` returned success. Status moved to idle and the old
  completion marker never appeared.
- The canceled agent accepted a later prompt and returned the expected reuse
  marker, proving cancel did not kill the session.
- `archive_agent` succeeded; the active list became empty and the same agent
  appeared closed in the archived list.
- Fixture `main` remained clean at its original commit with one local worktree
  and no repository mutation.

## G - Runtime permission boundary

Status: `PASS`

- A fresh restricted `opencode-worker` ran with provider auto-accept disabled.
- Low-risk read inside the workspace succeeded without a permission request.
- One native read of the non-sensitive external path `/etc/hostname` produced
  an `external_directory` permission request scoped to `/etc/*`.
- The request was observable through both agent status and the global pending
  permission list while the agent remained running.
- The worker did not self-approve or retry. A separate control-plane action
  selected `deny`; the request list returned to zero and the agent reported the
  external read denied.
- Fixture HEAD, clean status, and SHA-256 of all tracked files were identical
  before and after the probe. No write, network call, child agent, or shell
  workaround occurred.
- This proves the human/provider permission path separately from the already
  proven Paseo orchestration-catalog boundary. It is not described as a hard
  host security sandbox.

## Bootstrap V1 operational result

Preflight and core tests A-G all passed with real-host observable evidence.
All test-owned agents and workspaces were archived; managed worktree directories
were removed by Paseo. The local fixture checkout was verified clean, then its
task-owned temporary directory was removed during post-validation cleanup.

The complete project-agnostic Bootstrap V1 gate also passed:

- bootstrap regression suite: 98 assertions, zero failures;
- live idempotency: two no-op reruns preserved the config SHA-256 and backup
  count;
- secret-safety checks: PASS.

Bootstrap V1 is therefore `OPERATIONALLY VALIDATED`. This classification proves
the bootstrap/orchestration distribution only. It does not validate runtime for
any application repository. The existing disposable fixture already supplied
the real Git/worktree evidence for B-D, so no redundant project repository was
created.

Future projects adopt the bootstrap, run `install-project.sh <repo>`, derive
runtime only from the inspected repository, and perform project-specific
validation locally.

Observed execution gaps that did not invalidate core results:

- managed shell sandbox blocks loopback sockets, causing an in-sandbox daemon
  health false negative;
- completion notifications can be duplicated or remain stale across follow-up
  turns, so status/activity correlation was required;
- no dedicated redirect tool was present; `send_agent_prompt` applied a
  corrective prompt to the running OpenCode turn and produced the new marker;
- Codex account usage and Gemini quota blocked the first committee composition;
  restricted OpenCode model-family fallback completed the committee.
