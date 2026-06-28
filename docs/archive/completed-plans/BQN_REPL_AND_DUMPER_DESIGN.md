# BQN REPL and Dumper Design

Status: Phase 1 implemented (`tools/bqn-eval`) / Phase 2 implemented (`tools/bqn-dump`) / Phase 3+ not implemented
Date: 2026-06-22

This document defines a small AI-development-efficiency tool family for inspecting BQN expressions, shapes, and intermediate values in `bqn-ledger`.

It does not replace the existing BQN interpreter or REPL. It wraps the existing BQN execution path with repository-aware loading, compact output, and safety boundaries.

## 1. Why this exists

The AI efficiency notes repeatedly identify BQN debugging as a high-token, high-turn-cost area:

- BQN errors can be abstract and require repeated mental tracing.
- Homogenization, Enclose (`<`), Disclose (`>`), string/list shape changes, and boxed values are easy for AI agents to misread.
- Full report output is often too large when the question is only "what is the shape/value of this expression?"
- The useful debugging target is usually a tiny expression, helper, fixture, or intermediate value.

Goal:

```text
make small BQN questions cheap, local, reproducible, and AI-readable
```

## 2. Existing BQN REPL vs repo-aware probe

Existing BQN REPL / interpreter:

```text
best for: language experiments
examples: shape, Enclose/Disclose, simple arrays, tiny reproductions
```

Repo-aware probe / dumper:

```text
best for: bqn-ledger debugging
examples: load repo modules, load fixture data, run one helper, print compact shape/value/type-ish output
```

Decision:

```text
Do not build a new BQN implementation.
Do not replace BQN's own REPL.
Build thin wrappers around the existing BQN executable when needed.
```

Useful metaphor:

```text
BQN REPL     = flashlight
repo probe   = flashlight adapter for the bqn-ledger switchboard
sqz-report   = report squeezer
```

## 3. Scope

Allowed:

- run a tiny BQN expression
- load selected repo modules for inspection in a later approved phase
- load fixture data by `--base <dir>` in a later approved phase when explicitly requested
- print value preview, shape, rank-ish information, and boxed/string hints in a later dumper phase
- print compact machine-readable output for AI agents in a later structured-output phase
- help diagnose BQN type/shape errors
- support copy-pasteable reproduction commands

Forbidden:

- writing `data/*.tsv`
- modifying source TSV files
- becoming a second report engine
- calculating household accounting values outside BQN canonical code
- replacing `tools/sqz-report`
- dumping huge reports by default
- silently importing real `data/` unless explicitly requested

## 4. Tool family

The design starts as a small family of commands rather than one overloaded tool.

```text
tools/bqn-eval    evaluate a tiny expression with minimal repo context (implemented Phase 1)
tools/bqn-probe   load repo helpers/modules and inspect named expressions (not implemented)
tools/bqn-dump    print compact shape/value diagnostics for selected values (not implemented)
```

Possible later aliases:

```text
rtk bqn-eval
rtk bqn-probe
rtk bqn-dump
```

Only `tools/bqn-eval` is implemented. The other names are candidates, not implementation approval.

## 5. Command sketches

### 5.1 `tools/bqn-eval` (implemented Phase 1)

Purpose: cheap language-level checks.

```sh
bash tools/bqn-eval '≢ "OK"'
bash tools/bqn-eval '<"OK"'
bash tools/bqn-eval '⟨<"OK", <"WARN"⟩'
```

It also accepts stdin:

```sh
printf '≢ "OK"\n' | bash tools/bqn-eval
```

Current output modes:

```text
--format text    default; run the expression and print BQN output
--format raw     same as text in Phase 1; reserved for future contrast
```

`--format json` is intentionally rejected in Phase 1.

Implementation note:

```text
The wrapper writes the expression to a temporary `.bqn` file and runs the existing BQN executable on that file.
It does not rely on a special `bqn -e` option.
```

### 5.2 `tools/bqn-probe` (not implemented)

Purpose: repo-aware checks.

```sh
tools/bqn-probe --module src/reports/report_engine.bqn --expr '<expression>'
tools/bqn-probe --base fixtures/basic --expr '<expression>'
```

Possible future mode:

```sh
tools/bqn-probe --case section-status --base fixtures/empty-journal
```

A probe case is a documented, named mini-debug path. It should not be an ad-hoc second report engine.

### 5.3 `tools/bqn-dump` (Phase 2: implemented 2026-06-27)

Purpose: show compact diagnostics for a value.

```sh
bash tools/bqn-dump '5'
bash tools/bqn-dump '"OK"'
bash tools/bqn-dump '⟨<"OK", <"WARN"⟩'
bash tools/bqn-dump '<"OK"'
```

Actual output format:

```text
kind: list_boxed
shape: ⟨ 2 ⟩
preview: ⟨<"OK", <"WARN"⟩ (via •Fmt; multi-line for boxed)
boxed: elements_boxed
```

Kind vocabulary:
- `number`: plain number (•Type = 1)
- `string`: rank-1 non-empty character array
- `list`: plain array (not string, not boxed)
- `list_boxed`: array whose first element is boxed
- `boxed`: boxed scalar
- `unknown`: anything else

Boxed hint:
- `none`: no boxing
- `scalar_boxed`: the value itself is a boxed scalar
- `elements_boxed`: a list whose first element is boxed

Limitations (Phase 2):
- HasBoxedEls checks only the first element
- Empty rank-1 array classified as "list" (BQN ambiguity between `""` and `⟨⟩`)
- Preview uses •Fmt which produces multi-line output for boxed/complex values
- No `--format` flag; output is always the 4-line text format

JSON is not implemented in this phase.

## 6. Output policy

Default output should be small.

Rules:

- never print full report output by default
- truncate large arrays with a clear `truncated=true` or `...` marker in later dump/probe phases
- include enough shape information to debug Enclose / Disclose / homogenization issues in later dump/probe phases
- include the command that reproduced the output when useful
- return non-zero on BQN errors
- keep stderr for execution errors and stdout for structured result output when possible

Suggested future output modes:

```text
--format text    human/AI readable default
--format json    stable machine-readable output, later phase only
--format raw     raw BQN output, only when requested
```

## 7. Relationship to existing tools

### `tools/sqz-report`

`tools/sqz-report` asks:

```text
What did the report/export say about this key or section?
```

REPL/probe/dumper asks:

```text
What does this small BQN expression/value look like?
```

Do not merge them yet.

### `checks/*`

Checks ask:

```text
Does the repo still satisfy its contracts?
```

Probe asks:

```text
Why is this one BQN value shaped this way?
```

### future Variable Dumper

Variable Dumper may become an implementation helper, but the first design should avoid invasive changes to BQN modules.

Early version can be explicit:

```bqn
Dump "name" value
```

Later version may support named debug cases.

## 8. Safety boundary

The tool family must be read-only by design.

Read-only means:

- no writes to `data/*.tsv`
- no writes to source TSV fixtures unless a future test explicitly writes to temporary copied fixtures
- no mutation of `out/*` unless an explicit future mode is approved
- no backup creation needed for normal probe/eval commands
- no hidden cleanup of source files

Default base should preferably be a fixture or no base.

Real `data/` should require explicit `--base data` if a future probe ever needs it.

## 9. Implementation phases

### Phase 0: docs-only

Status: done.

- define tool purpose and non-goals
- decide command names
- decide output shape vocabulary
- decide first debug cases

### Phase 1: language-level eval wrapper

Status: implemented v1 (2026-06-22) as `tools/bqn-eval`.

Implemented scope:

```text
tools/bqn-eval only
no repo module loading
no TSV loading
no source writes
text/raw output only
```

Current acceptance:

- evaluates tiny expressions by writing a temporary `.bqn` file and running `bqn <tempfile>`
- returns non-zero on wrapper argument errors and BQN execution errors
- supports text output
- has negative tests for missing expression, invalid option, missing format argument, rejected JSON format, and multiple expressions

Known review point:

```text
GitHub Contents API may not preserve executable bit for newly created scripts.
Until confirmed locally, use `bash ./tools/bqn-eval ...` in tests and AI task packets.
```

### Phase 2: explicit value dumper helper

Status: implemented (2026-06-27) as `tools/bqn-dump` + `tools/bqn-dump.bqn`.

Implemented scope:

```text
small BQN helper for value diagnostics: tools/bqn-dump (shell) + tools/bqn-dump.bqn (module)
no repo module loading
no TSV loading
no source writes
no report engine behavior changes
```

Output format (fixed, no --format flag):

```text
kind: <string|number|list|list_boxed|boxed|unknown>
shape: <shape via •Fmt>
preview: <truncated •Fmt of value>
boxed: <none|scalar_boxed|elements_boxed>
```

Acceptance satisfied:

- stable compact output for number, string, list, boxed list, mixed list ✓
- test cases for homogenization / Enclose / Disclose issues ✓
- tests: `tests/test_bqn_dump.bqn` (40+ assertions)

Implementation notes:

- Uses `•Fmt` not `•Show` (CBQN `•Show` prints to stdout)
- Avoids `←` variables in `? ;` else branches (CBQN scoping quirk)
- Puts constants left of `=` to avoid `•Type 𝕩 = 0` being parsed as `•Type (𝕩 = 0)`
- `IsStr`: rank-1 non-empty arrays with character first element
- `HasBoxedEls`: checks first element only (Phase 2 limitation)
- Empty rank-1 array (`⟨⟩`) classified as "list" (BQN ambiguity)
- No `--format json` in this phase

### Phase 3: repo-aware probe cases

Possible scope after approval:

```text
named probe cases for known pain points
fixture-only by default
```

Candidate first probe cases:

- section status value shape
- `SplitKeepEmpty` behavior on empty memo rows
- account metadata parsing shape
- plan_id open/closed detection helper shape

## 10. First recommended debug cases

The first cases should come from already observed AI pain:

```text
homogenization:
  "OK" + "OK" vs "WARN" + "OK"

boxing:
  ⟨"OK", "OK"⟩ vs ⟨<"OK", <"OK"⟩

extraction:
  idx ⊏ values
  >⊑idx⊏values

string/list output:
  why BQN says Trying to output non-character
```

These cases are small enough that they should not require real data.

## 11. Open questions

- Should JSON output be part of Phase 2 or Phase 3?
- Should probe cases live in shell scripts, BQN files, or both?
- Should `rtk` wrap these commands from the beginning?
- How much type vocabulary is useful without pretending BQN has a foreign type system?
- Should failures include a short hint table for Enclose / Disclose / homogenization?
- Should the executable bit be fixed locally if GitHub-created `tools/bqn-eval` is not executable?

## 12. Implementation gate for next phases

Phases 1 and 2 are implemented.

A future approval should say something like:

```text
Approve Phase 3: repo-aware probe cases.
No TSV loading of real data/.
No source TSV writes.
No report engine behavior changes.
Fixture-only by default.
```

Until then, Phase 3+ remains design-only for the AI development efficiency track.
