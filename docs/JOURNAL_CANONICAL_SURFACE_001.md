# Canonical Journal Surface 001

Status: current contract

`bqn-ledger` の native Journal 物理表記を、会計意味を変えずに安全に標準化するための規範的契約です。

## Canonical 化するもの

Canonical Surface 001 が変更してよいのは次だけです。

1. Posting 行
   - インデントを ASCII SPACE 4 文字へ統一
   - Account と amount の区切りを ASCII SPACE 4 文字へ統一
2. 冗長 transaction metadata
   - `; layer: actual`
   - `; currency: JPY`

Identity metadata (`event-id`, `plan-id`, `txn-id` 等)、非冗長 metadata (`tax`, `biz` 等)、宣言、コメント、transaction 順序、Posting 順序、Account、amount、Commodity は保持します。

## Owner boundary

Supported public entrypoint は `tools/edit` です。

```text
tools/edit
  -> tools/journal-canonical-surface
       filesystem identity / snapshot / publication
       -> BQN Canonical Surface owners
            classification / rewrite / semantic equivalence / candidate bytes
```

`tools/edit-bqn` に残る旧 Canonical branch は移行中の内部 residue であり、現在の public filesystem authority ではありません。削除・reachability 整理は repository-wide dead-surface audit で行います。

Canonical Household source は canonical data root 直下の `actual.journal` だけです。historical な `<base>/data/actual.journal` fallback は writer authority ではありません。

## 3 commands

### `journal canonical-surface-plan`

Read-only classification/summary。

```bash
tools/edit journal canonical-surface-plan [--format text|tsv]
```

- `text`: 人間向け summary
- `tsv`: aggregate metrics のみ。description / Account / amount は出力しません。

### `journal canonical-surface-preview`

別 artifact へ verified candidate を出力します。

```bash
tools/edit journal canonical-surface-preview --output /path/to/preview.journal
```

Public shell boundary は output path を filesystem identity として扱います。

- canonical source と同じ path alias は拒否
- source を指す symlink は拒否
- source と同じ inode の hard link は拒否
- distinct caller-owned artifact は許可

BQN は candidate の semantic equivalence を確認してから bytes を書き、書いた artifact を read-back して exact bytes を確認します。

### `journal canonical-surface-apply`

Canonical source を checked rewrite します。

```bash
tools/edit journal canonical-surface-apply [--dry-run | --apply] [--yes] [--post-check none|lint|full]
```

- default / `--dry-run`: source を変更しない
- `--apply --yes`: confirmation を省略して checked rewrite
- canonical source が既に canonical なら `CANONICAL_NOOP`。backup も作らない

## Safety laws

### 1. BQN semantic equivalence

`journal_canonical_surface_rewrite.bqn` は before/after を `historical_external_plan` profile で parse し、次を比較します。

- transaction cardinality/order
- date / status / description / layer
- durable/fallback identity semantics
- plan/txn/allocation/actual-event/execution-envelope coordinates
- Posting cardinality/order
- Account / exact amount / Commodity / side / posting index
- non-redundant metadata
- Account / Commodity declarations

Mismatch は fail-closed です。

### 2. One physical Posting observation

Posting line の indentation / separator / Account / amount suffix は `journal_canonical_surface_plan.bqn` の一つの observation で所有します。Plan と Rewrite が同じ物理 line を別々に再解析しません。

### 3. Candidate artifact boundary

Apply では shell が caller-owned temp file を作成し、BQN が verified candidate bytes をそこへ書きます。BQN は canonical source path を選びません。

Candidate artifact write 後は read-back byte equality を確認します。

### 4. Snapshot + safe publication

Final Apply は shell が所有します。

1. canonical source の SHA-256 / size / mtime snapshot
2. BQN candidate generation
3. publication 直前の snapshot recheck
4. `safe_rewrite_checked`
5. mandatory Canonical semantic equivalence
6. requested post-check
7. failure 時の guarded rollback

Concurrent source mutation があれば publication を拒否します。

### 5. Source-ending law

Whole-source line rewrite は map/filter ですが、final LF の補正は physical source shape law として明示的に残します。単なる compactness のため generic Join helper に隠しません。

## Idempotency

Canonical source に再度 Apply すると `CANONICAL_NOOP` になり、source bytes と backup topologyを変更しません。

## Review evidence

BQN-native / effect-boundary review:

`docs/EDITOR_PHASE_SIX_JOURNAL_CANONICAL_SURFACE_OBSERVATION-2026-08-16.md`

Public boundary check は Plan、Preview alias rejection、distinct Preview、dry-run、checked Apply、mandatory equivalence、idempotency、nested `data/` rejection を通してこの契約を保護します。
