# AI Working Feedback Classification Review — 2026-07-05

Status: review snapshot / no implementation authorization

この文書は、AI 作業品質・トークン効率・デバッグ効率・安全性・開発体験に関する current repo state と active feedback を再評価した第2回 classification snapshot です。

**この文書は実装計画ではありません。**

- Feedback entry is not an implementation request.
- Classification is not an implementation backlog.
- Only an approved plan authorizes implementation work.
- `candidate-for-plan` は Planning stage への signal であり、実装許可ではありません。

Process:

```text
Intake
  ↓
Classification / Triage
  ↓
Planning
  ↓
Execution
  ↓
Review / Learning
```

Current process:

- `docs/AI_WORKING_FEEDBACK_PROCESS.md`

## Sources reviewed

Current policy / navigation:

- `AGENTS.md`
- `TODO.md`
- `docs/QUALITY_BAR.md`
- `docs/AI_CODEMAP.md`
- `docs/AI_WORKING_FEEDBACK_PROCESS.md`
- `docs/archive/active-plans/README.md`

Feedback / prior review:

- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`
- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md`

Older efficiency proposal sets:

- `docs/archive/active-plans/AI_AGENT_EFFICIENCY_PLAN.md`
- `docs/archive/completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md`

Current devtool / test surfaces inspected:

- `tools/repo-index`
- `tools/scaffold-check.sh`
- `tools/devtools-check.sh`
- `tools/query`
- `tools/check.sh`
- `tests/test_lib.bqn`
- `tests/test_src_next_config_required_negative.bqn`
- `checks/check-absolute-links.sh`
- `checks/check-src-next-golden.sh`
- `docs/CONVENTIONS.md`

Recent completion evidence reviewed:

- PR #40: A5 duplicate exact assertion cleanup
- PR #41–#58: A4 config semantics workstream through final closure
- PR #58: A4 completion decision merged

## Current repo snapshot

### Current priority

`TODO.md` does not place AI-efficiency implementation at the current top priority.

Current project selection remains centered on the listed envelope/report/docs/fintech slices. AI workflow improvement must therefore enter through the documented feedback process rather than being treated as an implicit standing TODO.

### Old efficiency plan is not current TODO

`docs/archive/active-plans/README.md` classifies:

```text
AI_AGENT_EFFICIENCY_PLAN.md -> parked
```

Therefore its old recommended sequence is not a current implementation queue.

### Current devtools already present

The current tree and `AGENTS.md` expose at least:

```text
rtk
sqz
tools/bqn-eval
tools/bqn-dump
tools/query
tools/repo-index
tools/scaffold-check.sh
tools/devtools-check.sh
```

`tools/repo-index` currently supports:

```text
tools/repo-index
tools/repo-index --baseline
tools/repo-index --diff
```

`tools/devtools-check.sh` checks repo-index freshness, query coverage, bqn-eval / bqn-dump liveness, optional rtk / sqz availability, stale tool references, and scaffolder existence.

This means old proposals to design and implement repo-index or a check scaffolder cannot be reused as unresolved TODO items.

### A4 and A5 state

```text
A4 Partial config.tsv semantics -> resolved / completed enough for now
A5 Golden + exact grep duplication -> resolved
```

A4 must not be reopened by momentum. Future config work must re-enter as a newly selected concrete problem.

## Classification layers

| Code | Layer | 判断基準 |
|---|---|---|
| A | Tool / Environment | 観測、実行、検索、圧縮、デバッグの道具や実行環境が不足している |
| B | Coding / Implementation | 言語固有の罠、局所的なコード記法、実装パターンに問題がある |
| C | Architecture / Design | 責務、契約、SSOT、データ表現、副作用境界、設定意味論に問題がある |
| D | Verification / Test | test、lint、CI、negative path、drift detection、assertion ownership に問題がある |
| E | Workflow / Information Architecture | 作業順序、handoff、docs導線、監査方法、context persistence に問題がある |

## Older efficiency plan re-evaluation

| Old candidate | Current status | Current evidence / interpretation |
|---|---|---|
| AI output checklist | mitigated | Current task packets, handoffs, and completion-report patterns already preserve changed / executed / not-executed / untouched / risk information. Do not add a new tool. |
| Fragile test prevention | observe-more | A5 removed one concrete duplicate ownership problem, but exact human error text is still asserted in some negative tests. No broad error-code migration is authorized. |
| CodeGraph-lite / repo-index | resolved | `tools/repo-index`, `--baseline`, `--diff`, AGENTS usage rules, and devtools freshness checks exist. |
| check script scaffolder | resolved | `tools/scaffold-check.sh` exists and is checked by `tools/devtools-check.sh`. |
| sqz-report impact summary | superseded | Old `tools/sqz-report` is removed. Current narrow surfaces include `tools/query`, structured report sections, `rtk`, `sqz`, and `repo-index --diff`; do not resurrect the old plan automatically. |
| Full CodeGraph / Semmle / CodeQL | rejected | Still disproportionate for current BQN-centered needs; explicitly outside this review. |

## Previous item status update

The first snapshot is retained as historical classification evidence. The table below updates its items against the current tree.

| ID | Item | Status | Current assessment |
|---|---|---|---|
| 1 | Output Squeezer | superseded | `tools/sqz-report` is removed. `tools/query`, section-specific outputs, `rtk`, and `sqz` cover narrower current paths. Do not revive by old name. |
| 2 | BQN REPL / Variable Dumper | mitigated | `tools/bqn-eval` and `tools/bqn-dump` are implemented, documented, and liveness-checked. Their scopes remain intentionally limited. |
| 3 | TSV Alignment Linter | mitigated | Account / role / budget-target lint exists. This does not prove every cross-file invariant is solved. |
| 4 | Structured TSV Patch Applier | superseded | The old Go-centered patch idea no longer matches current architecture. Go is retired; current write boundary is BQN validation plus shell safe-write/editor paths. |
| 5 | Golden Diff Summary | observe-more | Historical implementation claims do not map cleanly to current src_next golden path; current `check-src-next-golden.sh` emits raw `diff -u`. No repeated current friction justifies a new tool yet. |
| 6 | Context Unload / Task-focused Subagents | mitigated | L1/L2/L3 reading paths, current-only TODO, focused handoffs, and task packets reduce context loading. No autonomous subagent framework is needed. |
| 7 | Fail-safe Path automatic verification | mitigated | Negative tests and fail-closed checks exist across current surfaces, but coverage remains surface-specific. |
| 8 | System Defaults SSOT | mitigated | A4 established raw/effective separation and typed semantics for selected keys without adopting a global merged config table. |
| 9 | Docs / Code Drift Linter | mitigated | Current checks include stale-tool references, workflow drift, absolute-link policy, and repo-index freshness. No general docs/code linter exists. |
| 10 | BQN Homogenization / shape drift | mitigated | `bqn-dump` provides kind / shape / preview / boxed hints. Representation mistakes are easier to observe, but no global representation contract is claimed. |
| 11 | `git diff` Self-review | mitigated | `AGENTS.md` standardizes `rtk git status` / `rtk git diff` usage and small-change review practice. |
| 12 | Docs update omission detection | mitigated | Specific update rules and drift checks exist. Generic automatic docs synchronization would risk duplicate ownership. |
| 13 | Check Scaffolder | resolved | `tools/scaffold-check.sh` exists and is part of devtool self-checking. |
| 14 | Fragile Test prevention | observe-more | A5 fixed one duplicate exact-value surface, while exact human message assertions still exist. Treat concrete breakage separately rather than launching broad rewrites. |
| 15 | Impact Summary | observe-more | `repo-index --diff` gives structural change visibility and `tools/query` gives narrow report queries, but no dedicated numerical impact summary exists. No current repeated friction is recorded. |
| 16 | `git mv` priority | observe-more | Docs hygiene favors small explicit moves, but no current repeated rename-intent failure warrants a dedicated rule change. |
| 17 | No-Mutation Assertions | mitigated | Source TSV protection and write-boundary checks are strong current policy; no global checksum framework is justified by current evidence. |
| 18 | Migration / Handoff Template | mitigated | Task packets, handoff docs, current process stages, allowed/forbidden boundaries, and completion reports cover the main persistence need. |
| 19 | Audit → Drift Table → Fix Plan | mitigated | The current Intake → Classification → Planning → Execution → Review process formalizes separation of finding, triage, authorization, and implementation. |
| 20 | Nonexistent Guard | mitigated | Current devtools checks, stale-reference checks, safety docs, and evidence-oriented quality rules reduce claim/evidence drift. No complete guard registry is claimed. |
| 21 | Command Wrapper measurement | observe-more | `rtk` / `sqz` availability is checked, but the new intermittent exit 141 report means wrapper/pipeline behavior still needs evidence before design changes. |
| 22 | Soft-gated Tests | observe-more | Top-level check paths are mostly strict, while some `|| true`, optional tools, and suppression patterns are intentional or local. No fresh semantic audit has been completed. |
| 23 | Historical Docs Status Note | resolved | `AI_CODEMAP.md` explicitly separates current vs historical paths, and `active-plans/README.md` classifies active / parked / historical documents. |
| 24 | Follow-up TODO | mitigated | `TODO.md` is current-only, archive inventory records stale plans, and handoff/process docs preserve next-step context. |
| A1 | Archive move link validation | observe-more | `checks/check-absolute-links.sh` checks `file://` links, not general relative Markdown target validity. The original friction remains plausible but is not yet frequent enough for automatic implementation. |
| A2 | BQN precedence / function role gotchas | resolved | `docs/CONVENTIONS.md` now contains the logged 2026-06-30 traps: immediate block evaluation, right-associative function application, role inference, and lowercase-function `Double Subjects`. |
| A3 | BQN `⎊` outer-scope catch | candidate-for-plan | Concrete crash evidence exists, but the current conventions inspected do not yet fix this exact safe idiom. Prefer a minimal existing-doc rule over a new large guide. |
| A4 | Partial `config.tsv` | resolved | Closed by the A4 workstream and PR #58. Do not reopen. |
| A5 | Golden + exact grep duplication | resolved | PR #40 removed duplicate exact assertions while preserving negative / human boundary checks. |

## New feedback classification

### N1. Subprocess testing debug visibility

Status:

```text
candidate-for-plan
```

Classification:

| Field | Assessment |
|---|---|
| Primary | D — Verification / Test |
| Secondary | A — Tool / Environment |
| Symptom | A subprocess probe fails, while the parent test reports a generic assertion / exit result; diagnosis requires manual probe rerun. |
| Root cause hypothesis | Failure evidence is flattened across nested test surfaces. The problem is not simply absence of a helper; failure-output ownership is inconsistent. |
| Local fix hypothesis | A focused `test_lib.bqn` subprocess assertion/helper could emit command, exit code, stdout, stderr only when the expectation fails. |
| Systemic fix hypothesis | Define a small failure-output contract: green path silent, red path evidence-rich. Preserve original subprocess evidence at the nearest owner. |
| Toolify? | maybe, but first prefer a small shared test helper or assertion pattern over a new standalone devtool |

Current evidence:

- `tests/test_lib.bqn` currently emits generic assertion text.
- `tests/test_src_next_config_required_negative.bqn` calls `•SH` and then asserts over result fields.
- `tools/check.sh` uses different failure visibility patterns across surfaces: unit tests rerun on failure, many child checks redirect stdout, and nested BQN assertions may flatten the original probe evidence.
- `docs/QUALITY_BAR.md` already requires failures to be diagnosable and warns against hiding test output.

Interpretation:

This is stronger than a speculative tool idea because it occurred during real A4 negative-test work and is likely repeatable when subprocess probes are used again.

However, classification does **not** authorize implementation. Planning must first confirm the smallest owner and acceptance criteria.

### N2. Temporary pipeline SIGPIPE / exit 141

Status:

```text
observe-more
```

Classification:

| Field | Assessment |
|---|---|
| Primary | A — Tool / Environment |
| Secondary | D — Verification / Test |
| Symptom | Intermittent exit 141 during `check.sh` under `rtk`, without a clear BQN trace. |
| Root cause hypothesis | Unknown. Possible wrapper / producer / early consumer / pipefail interaction, but current evidence is insufficient. |
| Local fix hypothesis | None until a reproducible command boundary is identified. |
| Systemic fix hypothesis | Record exact producer, consumer, wrapper, exit-status propagation, and stderr before changing policy. |
| Toolify? | no, not yet |

Current evidence:

- The feedback is intermittent and lacks a stable reproduction.
- `tools/query` already uses a temporary file specifically to avoid pipefail SIGPIPE with early `awk` exit, showing that a safe pattern exists in one current path.
- That pattern does not prove the reported `rtk` failure has the same root cause.

Decision:

Do not implement broad SIGPIPE handling or exit-code rewriting from this classification.

### N3. BQN gotchas rule fixation

Status split:

```text
2026-06-30 precedence / immediate evaluation / role issues -> resolved
2026-07-04 ⎊ outer-scope catch issue                    -> candidate-for-plan
```

Reason:

The exact 2026-06-30 traps are already present in `docs/CONVENTIONS.md`. Creating another large BQN gotchas document would duplicate current knowledge ownership.

For `⎊`, the preferred direction is a minimal safe-idiom addition to the existing BQN pitfalls section if Planning confirms the rule.

### N4. Archive move relative-link validation

Status:

```text
observe-more
```

Reason:

A current check exists for absolute `file://` links, but not for general relative Markdown target resolution. The gap is real, yet one logged event is not enough to authorize a new checker without first defining active/archive policy and false-positive handling.

## Cross-cutting root-cause clusters update

### 1. Contract ownership duplication

Status: still valid, with one concrete reduction.

Resolved example:

- A5 removed exact machine-summary ownership duplication between golden and shell `grep` assertions.

Still relevant examples:

- human error string vs machine failure contract
- code field contract vs docs/check copies

Review principle:

> One expectation should have one primary owner.

### 2. Semantic ambiguity

Status: still valid, but A4 is a successful reduction example.

A4 showed that apparent token/tool friction can actually be architecture/design ambiguity:

```text
partial config friction
  ↓
file replacement vs effective override ambiguity
  ↓
raw/effective boundary + typed semantics
```

This reduced repeated inference without adding a giant config framework.

Review principle:

> Before adding tooling, ask whether the meaning itself can be fixed.

### 3. Observation surface shortage

Status: still valid, but current tools have reduced part of it.

Mitigations already present:

- `tools/query`
- report section exports
- `tools/bqn-eval`
- `tools/bqn-dump`
- `tools/repo-index`
- `rtk` / `sqz`

Remaining signal:

- nested subprocess failure evidence is not consistently available at the parent failure point.

Refined principle:

```text
green path -> silent / narrow
red path   -> evidence-rich
```

This is not an argument for noisy normal output.

### 4. Safety claim / executable evidence separation

Status: still valid.

Current checks reduce the gap, but claims should still be tied to executable evidence and current-tree ownership.

Review principle:

> Safety wording is not a substitute for an executable check or a clearly named unsupported boundary.

### 5. Language-specific knowledge not fixed

Status: reduced substantially, not eliminated.

Resolved current examples:

- right-associative function application
- immediate block evaluation
- function/subject role inference
- lowercase function `Double Subjects`

Remaining example:

- `⎊` left-operand outer-scope catch behavior

Review principle:

> Fix a proven language trap once in the smallest current guidance owner.

### 6. Context persistence shortage

Status: reduced.

Current mitigations:

- L1/L2/L3 reading paths
- current-only `TODO.md`
- active/parked/historical inventory
- task packets and handoffs
- explicit feedback process stages

Remaining risk:

- old parked plans can still look like future TODO when read without current-tree inspection.

Review principle:

> Current tree and current navigation outrank historical plan momentum.

## Planning signals only

The following are **not approved plans**.

### Priority 1: Subprocess debug visibility

Status:

```text
candidate-for-plan
```

Why it is the strongest next Planning candidate:

- observed during real work
- likely repeatable for subprocess negative tests
- directly reduces manual debug reruns
- can keep normal output silent
- architecture-neutral
- source-TSV-neutral
- runtime-neutral if kept in test infrastructure
- aligns with current Quality Bar diagnostic requirements

Planning must answer before implementation:

1. Is the smallest owner `tests/test_lib.bqn`, the individual negative test, or the parent runner?
2. What exactly does `•SH` return in the supported failure modes?
3. Which evidence is already preserved and which is currently lost?
4. Should the helper print command, exit code, stdout, stderr, or only available fields?
5. How is green-path silence tested?
6. How is red-path evidence tested without asserting long human prose?
7. Can existing assertion helpers be extended without creating a second subprocess framework?

Suggested plan boundary:

```text
docs-only Planning PR first
no runtime code
no source TSV
no A4 reopening
no SIGPIPE work bundled
```

### Priority 2: BQN `⎊` catch safe idiom

Status:

```text
candidate-for-plan
```

Reason:

- concrete language-specific failure exists
- nearby 2026-06-30 gotchas are already fixed in `docs/CONVENTIONS.md`
- likely smallest solution is one focused rule / example in the existing BQN pitfalls owner
- a new giant document or linter is not justified

Planning should first confirm the exact semantics and minimal wording. No implementation is authorized here.

## Not promoted to Planning

### Temporary SIGPIPE

Keep `observe-more` until a reproducible producer / consumer / wrapper boundary exists.

### Archive relative-link checker

Keep `observe-more` until active/archive failure policy and false-positive expectations are defined and recurrence is stronger.

### Old impact-summary proposal

Do not resurrect `sqz-report` or create a new impact dashboard from historical momentum alone.

## Review conclusion

The second review confirms that the old efficiency documents cannot be treated as a tooling backlog.

Several old candidates are already implemented or structurally superseded:

```text
repo-index       -> resolved
check scaffolder -> resolved
bqn-eval/dump    -> mitigated by implemented tools
Output Squeezer  -> superseded by current narrow surfaces
A4               -> resolved
A5               -> resolved
A2 logged gotchas-> resolved in existing conventions
```

The strongest remaining current signal is:

```text
Subprocess debug visibility
```

But the root cause should be framed as:

```text
nested failure evidence contract inconsistency
```

not automatically as:

```text
missing new tool
```

Recommended next stage:

```text
Classification complete
  ↓
select Subprocess debug visibility
  ↓
create a separate docs-only approved Planning candidate
  ↓
only then consider implementation
```

This snapshot authorizes no runtime change, no new devtool, no source TSV mutation, no A4 reopening, and no A5 reopening.
