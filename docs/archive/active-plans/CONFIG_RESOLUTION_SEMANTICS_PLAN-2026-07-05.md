# Config Resolution Semantics Plan

Status: Planning stage / implementation not yet authorized
Date: 2026-07-05
Classification item: A4 Partial `config.tsv` semantics
Primary cause layer: C Architecture / Design
Secondary cause layer: D Verification / Test

## Purpose

`config.tsv` の意味を、fixture ごとの慣習や consumer ごとの独自 fallback に任せず、明示的な configuration resolution contract として定義する。

この plan は AI Working Feedback Process の Planning stage に属する。

重要:

- この文書は実装許可ではない。
- この文書を読んだだけで runtime behavior を変更してはいけない。
- 実装開始には moko の明示承認が必要。
- external live ledger の `config.tsv` を自動変更してはいけない。

## Adopted classification item

A4 Partial `config.tsv` semantics

Observed friction:

- fixture に partial `config.tsv` を置くと `config/default_config.tsv` と merge されず、必要キー欠損で失敗した。
- 一方、一部の config accessor は独自 default を持ち、missing key を補う。
- shell consumer は同じ `<base>/config.tsv` から個別キーだけを sparse lookup する。
- config resolution timing が entrypoint によって一致しない。

Updated root-cause hypothesis:

> Configuration resolution semantics are distributed across file selection, per-key accessors, consumer-specific fallback, and entrypoint timing.

日本語では:

> 設定の意味が、ファイル選択・キー別 fallback・consumer 固有解釈・入口ごとの解決タイミングに分散している。

## Current evidence

### 1. BQN file selection is replacement, not merge

`src_next/config.bqn` は次の二者択一になっている。

```text
<base>/config.tsv exists
  yes -> read that file
  no  -> read config/default_config.tsv
```

`default_config.tsv` と local config の key merge は行わない。

### 2. BQN key behavior is already heterogeneous

現行 accessor は概ね次の意味を持つ。

```text
required
  missing -> error

built-in default
  missing -> warning + code-level default

optional
  missing -> empty / disabled / warning
```

したがって file-level semantics は replacement でも、key-level semantics は uniform ではない。

### 3. Shell consumers use sparse lookup

確認済み例:

- `tools/lib/theme.sh` reads `THEME`
- `tools/main-ui.sh` reads `FZF_PREVIEW_WINDOW`

これらは local config 全体を complete snapshot として検証せず、該当 key だけ読む。

### 4. Resolution timing differs by entrypoint

確認済み例:

- `tools/bl` resolves `--base` before sourcing theme logic.
- `tools/main-ui.sh` sources theme logic before parsing `--base`.
- `FZF_PREVIEW_WINDOW` is read after base parsing in `tools/main-ui.sh`.

同じ UI entrypoint 内でも key によって effective base resolution timing が異なる。

### 5. Fixtures reveal semantic mismatch

一部 fixture はコメント上 `Overrides` と表現されるが、replacement semantics を満たすため default-like keys を再掲している。

つまり human intent は sparse override に近いが、runtime requirement は full-ish snapshot に近い。

### 6. Dedicated config contract test is missing

現行 suite は config behavior を household policy / envelope / outlook 等の fixture 経由で間接的に検証している。

少なくとも一部既存 fixture は、missing `POLICY_BUDGET_STYLE` が accessor-level default `envelope` に落ちる挙動へ依存している。

そのため config semantics を単純に厳格化すると、既存の暗黙契約を壊す可能性がある。

## Configuration artifact roles

Planning baseline として、現行 artifact を次の役割で区別する。

```text
config/system_defaults.tsv
  system / path resolution defaults

config/default_config.tsv
  application-level documented defaults
  current runtime fallback

<data sandbox>/config.tsv
  public sandbox ledger configuration

fixtures/**/config.tsv
  test input for a specific contract or scenario

external live ledger <base>/config.tsv
  ledger-specific live configuration
```

この役割分離は、まだ runtime merge behavior を決定しない。

### External live config boundary

調査時点で external live ledger config は full-ish explicit configuration として運用されている。

Planning rule:

- 値そのものを public plan に複製しない。
- live config を自動 migration しない。
- live config compatibility を acceptance criterion に含める。
- overlay semantics を採る場合でも、既存 full-ish config を当面そのまま有効にできることを優先する。

## Decision axes

この問題を単一の A/B 選択として扱わない。

### Axis 1: File semantics

#### Option A: Complete snapshot

```text
<base>/config.tsv
  = complete configuration for that ledger
```

Properties:

- local file exists -> default file is not consulted for application keys
- missing required keys -> error
- one file can explain the complete effective config

Risks:

- one-key customization requires repeated values
- fixtures duplicate defaults
- `Overrides` wording becomes misleading

#### Option B: Sparse override

```text
config/default_config.tsv
        +
<base>/config.tsv
        =
effective config
```

Properties:

- local file contains only differences
- default values are centralized
- fixtures can become smaller

Risks:

- accidental missing keys may be silently masked by defaults
- fail-closed policy requires explicit key classification

#### Option C: Typed sparse override

```text
default_config.tsv
        +
local overrides
        +
key-class contract
        =
effective config
```

Key classes distinguish which missing behavior is legal.

This is the current recommended direction.

#### Option D: Physical config split

Example:

```text
policy.tsv
ui.tsv
system.tsv
```

Properties:

- strong ownership boundaries
- canonical BQN policy path need not share a file with UI preferences

Risks:

- file proliferation
- migration cost
- likely too large for first A4 implementation slice

Current position:

- Keep D as a later ownership review.
- Do not make physical file split a prerequisite for resolving A4.

### Axis 2: Key classes

Candidate classes:

#### `required-explicit`

Meaning:

- ledger/user must state the value explicitly
- default must not silently supply it

Missing behavior:

```text
missing -> ERROR
```

#### `defaultable`

Meaning:

- repository owns a documented application default
- local ledger may override it

Missing behavior:

```text
missing local key -> documented default
```

#### `optional`

Meaning:

- absence is a valid state
- related feature may be disabled or unavailable

Missing behavior:

```text
missing -> empty / disabled / unavailable
```

#### `ui-only`

Meaning:

- presentation or interaction preference
- must not change canonical accounting meaning

Missing behavior:

```text
missing -> documented UI fallback
```

Open question:

- whether `ui-only` keys remain in `<base>/config.tsv` or later move to a separate owner.

### Axis 3: Resolver ownership

Options to compare during implementation approval:

#### R1: Each consumer resolves independently

Current-like model.

Risk:

- semantics drift
- timing drift
- duplicated fallback logic

#### R2: BQN owns canonical application config resolution

Candidate shape:

```text
defaults + local -> effective application config
```

BQN policy/report consumers use one result.

Open issue:

- shell UI preferences still need a separate contract or export.

#### R3: Shared contract, separate implementations

BQN and shell may parse independently but must follow one documented resolution contract and executable tests.

Risk:

- still duplicates behavior

#### R4: Effective config export

One owner resolves config and exposes a machine-readable effective view for other consumers.

Risk:

- may introduce an unnecessary runtime dependency or new SSOT duplication if designed poorly

Current recommendation:

- Prefer BQN ownership for canonical application/policy meaning.
- Do not require shell UI to consume BQN output in the first slice.
- Treat UI preference ownership as a separate follow-up decision unless implementation evidence shows it must be solved together.

## Recommended direction

Current recommendation: **Option C, typed sparse override**, with physical split deferred.

Conceptual model:

```text
config/default_config.tsv
        |
        | documented application defaults
        v
<base>/config.tsv
        |
        | ledger-specific overrides
        v
ResolveConfig
        |
        v
effective application config
```

Validation behavior should be explicit by key class.

Candidate rules:

```text
missing required-explicit -> ERROR
missing defaultable       -> documented default
missing optional          -> disabled / empty / unavailable
unknown key               -> explicit policy: warning or error
invalid value             -> ERROR
duplicate key             -> ERROR
```

Important:

- The exact key-to-class mapping is not yet approved by this plan.
- Unknown-key behavior must be chosen deliberately, not inferred.
- Existing accessor-level defaults must be inventoried before moving them into a centralized resolver.

## Non-goals

This A4 plan does not authorize:

- config DSL creation
- arbitrary accounting computation in config
- Canonical Daily Cube shape configuration
- household policy redesign
- broad UI rewrite
- physical split of all config files
- automatic live-config migration
- modification of external live ledger data
- unrelated fixture cleanup
- replacement of `config/system_defaults.tsv`
- new general-purpose config framework

## Files that may be touched in a future approved execution

Possible scope, depending on the approved implementation slice:

- `src_next/config.bqn`
- a dedicated `tests/test_src_next_config.bqn`
- narrowly selected config fixtures
- `config/default_config.tsv`
- relevant config docs
- selected checks that exercise config behavior

Possible follow-up scope, not assumed for first slice:

- `tools/lib/theme.sh`
- `tools/main-ui.sh`
- `tools/bl`

## Files that must not be touched without separate explicit approval

- external live ledger `config.tsv`
- external live source TSV files
- `journal.tsv`
- `plan.tsv`
- `budget_alloc.tsv`
- `accounts.tsv`
- `cycle.tsv`
- unrelated fixture datasets

## Proposed phased execution

### Phase 0: Contract-only decision

Goal:

- decide file semantics
- define key classes
- define resolver ownership boundary
- define unknown-key / duplicate-key behavior

Runtime behavior change:

- none

Exit condition:

- moko explicitly approves one contract.

### Phase 1: Dedicated config verification

Goal:

Add focused config tests before changing runtime behavior.

Candidate cases:

1. no local config uses documented application defaults
2. full-ish local config remains valid
3. local override changes one defaultable key
4. required-explicit missing fails
5. optional missing remains valid
6. invalid enum fails
7. duplicate key fails
8. unknown key follows approved policy
9. explicit empty value is distinguished from missing key where contract requires it

Runtime behavior change:

- ideally none, except where an existing ambiguity makes test-only extraction impossible

### Phase 2: Effective application config resolution

Goal:

Implement the approved application-config resolution semantics in the canonical BQN owner.

Constraints:

- preserve external live full-ish config compatibility
- no automatic rewrite
- no UI refactor in the same slice
- small diff

### Phase 3: Fixture simplification

Goal:

Only after Phase 2 verification, remove repeated default-like keys from fixtures where sparse override is the intended scenario.

Constraints:

- fixture simplification must not be bundled with resolver implementation if it obscures behavioral review
- keep explicit full-snapshot fixtures where they test complete configuration behavior

### Phase 4: UI preference ownership review

Goal:

Decide whether UI-only keys should:

- remain in `<base>/config.tsv`
- use a prefixed namespace
- move to a separate file
- use environment-first resolution

This is a separate decision unless evidence proves it blocks application config resolution.

## Acceptance criteria

A future implementation is acceptable only if all applicable criteria pass.

### Semantics

- effective config behavior is documented
- missing behavior is defined by key class
- missing and explicit empty are not accidentally conflated where meaning differs
- duplicate keys have explicit behavior
- unknown keys have explicit behavior
- invalid enum values fail visibly

### Compatibility

- existing public sandbox behavior remains explainable
- existing full-ish external live config remains usable without forced migration
- no external live config is modified automatically
- BQN-only canonical report path remains valid

### Verification

- dedicated config tests exist
- indirect household/envelope/outlook coverage still passes
- full `tools/check.sh` passes
- negative cases prove fail-closed behavior

### Ownership

- canonical application/policy config meaning has one documented owner
- shell UI preferences are not accidentally promoted into accounting meaning
- no second undocumented default table is introduced

### Process

- implementation diff remains small enough to review
- fixture cleanup is separated if needed
- review result is recorded as `resolved`, `mitigated`, `observe-more`, `rejected`, or `superseded`

## Recommended checks

Minimum future verification candidate:

```text
bqn tests/test_src_next_config.bqn
relevant household policy tests
relevant envelope checks
relevant outlook tests
bash tools/check.sh
```

Exact command list should be finalized after the approved execution slice is chosen.

## Handoff proposal

Before Execution stage, the next worker should receive:

1. this plan
2. `docs/AI_WORKING_FEEDBACK_PROCESS.md`
3. `src_next/config.bqn`
4. `config/default_config.tsv`
5. relevant config fixtures
6. `docs/SAFETY_PROFILE.md`
7. explicit instruction that live config must not be edited

The worker must first state:

- selected phase
- exact files to touch
- exact files not to touch
- whether runtime behavior changes
- compatibility expectation for full-ish live config

## Planning decision request

Current recommendation for moko review:

```text
File semantics:   typed sparse override
Key classes:      required-explicit / defaultable / optional / ui-only
Canonical owner:  BQN application config resolution
Physical split:   defer
UI ownership:     separate follow-up review
Live migration:   none
```

No implementation begins until this direction, or a revised alternative, is explicitly approved.
