# Subprocess Debug Visibility Review / Learning — 2026-07-05

Status: completed review / resolved selected scope

## Process chain

```text
Intake
  ↓
Classification / Triage  PR #59
  ↓
Planning                 PR #60
  ↓
Execution                PR #61
  ↓
Review / Learning        this record
```

Related records:

- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`
- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-05.md`
- `docs/archive/active-plans/SUBPROCESS_DEBUG_VISIBILITY_PLAN-2026-07-05.md`

## Final result

```text
N1 Subprocess testing debug visibility -> resolved
```

`resolved` is intentionally narrow. It means the selected friction and the approved first execution slice are closed. It does not mean every subprocess test has been migrated.

## What was learned

The original friction was a manual diagnostic rerun after a nested negative-test failure.

Planning established that the process result already retained:

```text
exit code
stdout
stderr
```

The useful root-cause model became:

```text
evidence retained
  ↓
parent test receives it
  ↓
assertion boundary does not surface it
```

Therefore the problem was treated as a failure-evidence ownership issue, not as a reason to add a new standalone tool.

## Execution result

PR #61 changed only:

```text
tests/test_lib.bqn
tests/test_src_next_config_required_negative.bqn
tests/test_test_lib_subprocess_visibility.bqn
```

A small shared helper now follows this contract:

```text
green path -> quiet
red path   -> command + exit code + stdout + stderr
```

Domain-specific config expectations remain in the individual negative test.

A focused regression test deliberately exercises the red path and verifies that the parent can observe command, exit, stdout, and stderr evidence. The committed normal suite remains green.

## Verification evidence

PR #61 GitHub Actions completed successfully, including:

```text
Run check.sh
Coverage
```

Merge commit:

```text
0731b9bd919daaca14345a08e6adf87626a9862d
```

## Review questions

### Deliberate red path diagnosable without manual rerun?

```text
yes
```

The focused regression proves the evidence is visible at the parent boundary.

### Passing output remains quiet?

```text
yes
```

The helper returns immediately on a passing condition, and the full suite stayed green.

### Material normal-output growth?

```text
no material growth observed
```

No quantitative token benchmark was run. The additional diagnostic block is failure-only.

### Helper more complex than the original friction?

```text
no
```

One shared helper was added. No new standalone tool or global subprocess framework was introduced.

### Domain semantics leaked into the shared helper?

```text
no
```

Config keys and config diagnostic meaning remain local to the config negative test.

### Second assertion ownership surface created?

```text
no evidence of duplication
```

Ownership is separated by role:

```text
individual test -> expectation meaning
shared helper   -> failure evidence surfacing
```

### Broader migration justified now?

```text
no
```

Do not migrate all subprocess tests by momentum. Reuse the helper when another concrete repeated friction appears.

## Final assessment

The selected N1 workstream is `resolved` because it now has:

- a small shared owner
- one real adopter
- controlled red-path regression coverage
- green full checks
- no runtime impact
- no source-data impact
- no new standalone devtool

The retained principle is:

```text
green path -> quiet
red path   -> evidence-rich
```

## Still separate

Temporary SIGPIPE / exit 141:

```text
observe-more
```

BQN catch safe idiom:

```text
candidate-for-plan
```

Archive relative-link validation:

```text
observe-more
```

## Closure decision

```text
N1 subprocess debug visibility -> resolved
SUBPROCESS_DEBUG_VISIBILITY_PLAN-2026-07-05.md -> historical
broader subprocess migration -> not authorized
SIGPIPE work -> still observe-more
```
