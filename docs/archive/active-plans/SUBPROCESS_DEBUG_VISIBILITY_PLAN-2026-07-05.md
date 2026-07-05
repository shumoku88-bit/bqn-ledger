# Subprocess Debug Visibility Plan — 2026-07-05

Status: Planning-stage plan / docs-only / no implementation in this PR

Parent classification:

- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-05.md`

Selected classification item:

```text
N1 Subprocess testing debug visibility
```

Priority:

```text
1
```

## Decision

Select subprocess debug visibility as the first Planning-stage item from the 2026-07-05 classification refresh.

The current root-cause framing is:

```text
nested failure evidence contract inconsistency
```

not:

```text
missing new standalone tool
```

This plan recommends a minimal future execution slice in the existing BQN test helper layer, with one focused adoption in the current config negative test.

This plan does **not** implement that slice.

## Why this item is selected

The friction occurred during real A4 negative-test work rather than hypothetical tooling discussion.

Observed workflow:

```text
subprocess probe
  ↓
•SH result
  ↓
parent BQN negative test
  ↓
generic assertion failure
  ↓
manual probe rerun for diagnosis
```

The goal is to reduce that manual rerun loop while preserving quiet normal output.

## Current evidence

### 1. `•SH` already preserves three evidence channels

The BQN system-value contract for `•SH` is:

```text
exitcode‿stdout‿stderr
```

The command executes synchronously and the result retains exit code, stdout text, and stderr text.

Therefore the current problem is not that subprocess evidence is inherently unavailable.

### 2. The current probe deliberately emits failure evidence

`tests/config_required_probe.bqn` loads config, selects one household-group accessor, and invokes it.

For the current config failure path, `src_next/config.bqn` uses:

```text
•Out "CONFIG ERROR: ..."
•Exit 1
```

So the child process intentionally emits a diagnostic and exits non-zero.

### 3. The parent test receives the subprocess result

`tests/test_src_next_config_required_negative.bqn` currently does:

```text
result ← •SH ⟨"bqn", "tests/config_required_probe.bqn", base, key⟩
```

Then it separately checks:

```text
exit code == 1
expected message is contained in stdout
```

This proves the parent already has access to the captured result.

### 4. Generic assertions do not surface the captured result

`tests/test_lib.bqn` currently provides minimal:

```text
Assert
AssertEq
```

On mismatch, these print generic assertion text and exit.

They do not know or show:

- command
- actual subprocess exit code
- captured stdout
- captured stderr

### 5. The top-level runner cannot reconstruct nested evidence

`tools/check.sh` runs unit tests with a quiet first pass:

```text
bqn "$test_file" >/dev/null
```

and reruns a failed test without stdout redirection.

That rerun can reveal the outer generic assertion text, but the top-level runner does not own the inner `•SH` result and cannot reconstruct captured child stdout/stderr after the parent test discards that context.

## Root cause conclusion

Current evidence supports:

```text
•SH retains evidence
  ↓
parent test receives evidence
  ↓
assertion boundary flattens failure context
```

Therefore:

```text
evidence absent at source
```

is rejected as the primary explanation.

The stronger hypothesis is:

```text
evidence retained but not surfaced at the nearest useful failure owner
```

## Ownership decision

### Shared diagnostic owner

Candidate owner:

```text
tests/test_lib.bqn
```

Responsibility:

- minimal failure-only formatting / surfacing for a standard `•SH` result
- no domain-specific config semantics
- no new standalone CLI
- no global subprocess orchestration framework

### Individual test owner

Current first adopter:

```text
tests/test_src_next_config_required_negative.bqn
```

Responsibility:

- command construction
- expected exit semantics
- expected config diagnostic semantics
- deciding when the captured result is considered a failure

### Parent runner owner

```text
tools/check.sh
```

Decision:

```text
unchanged in the first execution slice
```

Reason:

The top-level runner only sees the outer BQN process. It is too far from the nested `•SH` result to be the primary owner of child command/stdout/stderr evidence.

## Important boundary: do not turn `test_lib.bqn` into a process framework

The shared helper layer should not automatically own:

- command scheduling
- retries
- timeouts
- environment mutation
- shell quoting policy
- SIGPIPE handling
- `rtk` integration
- CI orchestration

A minimal shared helper may receive already-available command/result context from the individual test and surface it only on failure.

Exact BQN API naming is deferred to Execution so the implementation can stay small.

## Intended output contract

### Green path

```text
silent / current normal output only
```

No command dump.
No captured stdout dump.
No captured stderr dump.
No extra token cost for passing subprocess assertions.

### Red path

When the parent expectation fails, emit enough evidence to diagnose without manually rerunning the probe.

Target fields:

```text
command
exit code
stdout
stderr
```

Empty channels may be shown explicitly or omitted with a clear marker; the execution slice should choose one consistent small format.

The output is diagnostic evidence, not a stable human API.

## Recommended first execution slice

Potential changed files:

```text
tests/test_lib.bqn
tests/test_src_next_config_required_negative.bqn
```

Possible focused test file only if needed to prove the helper contract:

```text
tests/test_test_lib_subprocess_visibility.bqn
```

The execution slice should remain small enough that a dedicated new test file is added only when it provides real red-path regression value.

## Acceptance criteria

A future implementation is acceptable only if all of the following hold.

### A. Green path remains quiet

Passing subprocess negative tests do not print new command/stdout/stderr diagnostics.

### B. Exit mismatch is evidence-rich

For a controlled failing expectation, visible output identifies at least:

```text
command
actual exit code
captured stdout
captured stderr
```

### C. Output-content mismatch is evidence-rich

When the expected diagnostic predicate fails, the captured child evidence is visible without manually rerunning `config_required_probe.bqn`.

### D. Domain semantics stay local

The shared helper does not know:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
CONFIG ERROR wording
A4 semantics
```

Those remain in the individual test.

### E. No long human prose becomes a new machine contract

The implementation must not create a second fragile exact-match surface for the full diagnostic block.

Prefer checking:

- presence of diagnostic field labels
- presence of captured known marker
- exit behavior

rather than exact multiline formatting.

### F. No runtime impact

No changes to:

```text
src_next/
src_edit/
production report paths
editor write paths
config semantics
```

### G. Source TSV remains untouched

Do not modify:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
accounts.tsv
```

Do not modify live config.

### H. Existing full checks remain green

Recommended verification after implementation:

```text
bqn tests/test_src_next_config_required_negative.bqn
rtk bash ./tools/check.sh
```

If a focused helper test is added, run it directly as well.

## Controlled red-path verification requirement

The execution PR must demonstrate the red path deliberately.

Acceptable approaches include a focused test or temporary controlled invocation that proves:

```text
wrong expected exit or diagnostic
  ↓
parent failure
  ↓
command + exit + stdout + stderr visible
```

The verification method must not leave the committed normal suite intentionally failing.

The completion report must distinguish:

```text
normal passing suite
controlled red-path evidence check
```

## Non-goals

Do not bundle:

- temporary pipeline SIGPIPE / exit 141 work
- `rtk` changes
- `sqz` changes
- `tools/check.sh` rewrite
- new standalone subprocess CLI
- generic agent orchestration
- global error-code migration
- all fragile-test cleanup
- A4 reopening
- A5 reopening
- BQN `⎊` gotcha rule work
- archive Markdown link checker
- source TSV mutation
- live config rewrite

## SIGPIPE separation

The 2026-07-05 intermittent exit 141 observation remains:

```text
observe-more
```

This plan must not infer that the subprocess visibility helper fixes SIGPIPE.

Reasons:

- the reported failure is intermittent
- producer/consumer/wrapper boundary is not localized
- the current `tools/query` temp-file pattern proves only that one current path intentionally avoids early-consumer pipefail SIGPIPE
- that does not establish the same root cause for the `rtk`-wrapped check failure

## Why not a new tool

Toolification gate result:

### Existing tool replacement?

No standalone tool is required for the first slice.

### Coding rule only?

Insufficient by itself because the friction occurs at runtime failure evidence surfacing.

### Design contract?

Yes, partially. The useful contract is:

```text
green path -> quiet
red path   -> evidence-rich
```

### Test ownership duplication?

Must be avoided. Domain expectations remain in the individual test; shared helper owns only generic evidence surfacing.

### Workflow issue?

Partially, but manual rerun is a consequence of missing local failure context rather than the primary fix.

### Frequent enough?

One concrete repeated-debug workflow is confirmed. That is enough for a narrowly scoped first adopter, but not enough for a large subprocess framework.

## Proposed Execution boundary

If this plan is separately approved for Execution, the first implementation should prefer:

```text
existing shared test helper
  +
one focused current adopter
```

not:

```text
new devtool
  +
global test migration
```

Suggested execution scope:

```text
tests/test_lib.bqn
  add minimal failure-only subprocess evidence support

tests/test_src_next_config_required_negative.bqn
  adopt it for the existing •SH probe result
```

Possible third file only with explicit justification:

```text
tests/test_test_lib_subprocess_visibility.bqn
```

## Review / Learning criteria after implementation

After an implementation slice, classify the result again.

Questions:

1. Did a deliberate red-path failure become diagnosable without manual probe rerun?
2. Did passing output remain quiet?
3. Did normal test token output grow materially?
4. Did helper API become more complex than the original friction?
5. Did domain semantics leak into `test_lib.bqn`?
6. Did the change create a second assertion ownership surface?
7. Is there evidence of another caller that justifies broader adoption?

Recommended result statuses:

```text
resolved
mitigated
observe-more
rejected
superseded
```

## PR boundary for this Planning stage

This Planning PR is docs-only.

It authorizes no implementation by itself unless the plan is explicitly approved for Execution after review.

Do not modify in this PR:

```text
tests/test_lib.bqn
tests/test_src_next_config_required_negative.bqn
tools/check.sh
runtime code
source TSV
live config
```

## Recommended next step

```text
review this plan
  ↓
if approved, create one small Execution PR
  ↓
implement failure-only evidence surfacing
  ↓
run normal checks + controlled red-path verification
  ↓
Review / Learning
```
