# src_next envelope computation contract

Status: contract + fixture-only Stage 4a prototype / no production behavior change

この文書は、`src_next` で Section 5「封筒・予算残高」と Section 9「見通し・日割り」を実装する前に、envelope computation の計算境界と用語を固定するための契約です。

## 1. 目的と現在の境界

この contract は **envelope computation の境界契約**です。

2026-06-25 に fixture-only / opt-in の Stage 4a prototype として、`src_next/envelope_computation.bqn` を追加しました。

この prototype では次だけを、公開 fixture 上で machine-checkable にしています。

```text
remaining = allocated - actual_spent
```

この prototype では次を行いません。

- production data 向けの polished remaining は出さない。
- `src_next` の production behavior は変えない。
- source TSV format は変えない。
- production route は変えない。
- 本番 default は引き続き `bqn main.bqn`。

これは Stage 4a の fixture-only 実装確認です。Stage 4b daily-use trial の開始ではありません。

この文書の目的は、次の値を軽く実装して意味が混ざることを防ぐことです。

- envelope / budget remaining
- food-like remaining
- daily-like remaining
- outlook / daily amount
- per-day allowance

特に、`remaining`、`safe_remaining`、`daily_amount`、signed ledger total、household spending total を混同しないことを目的にします。

## 2. 安定 key と policy label の境界

`src_next` の計算コードは、安定した metadata key を知ってよいです。
ただし、生活上の label を恒久的な engine concept として知ってはいけません。

### Stable metadata keys

計算コードが契約として扱ってよい key:

| key | 用途 |
|---|---|
| `role=expense` | expense account の識別。prefix fallback は互換の余地として扱う。 |
| `budget=...` | expense account が属する target / envelope の細かい分類候補。 |
| `budget_group=...` | broad household grouping の候補。 |
| `spend_class=...` | later reporting / diagnostics 用 metadata。 |

### Policy labels

次は policy data であり、engine concept ではありません。

- `食費`
- `daily`
- `flex`
- `reserve`
- envelope names
- budget names
- report target names

明示的な境界:

- calculation code may know stable metadata keys.
- calculation code must not permanently know household labels.
- `budget=食費` は初期 policy value であり、engine concept ではない。
- `budget_group=daily` / `budget_group=flex` / `budget_group=reserve` も policy value であり、engine concept ではない。
- account name や household label をコードに直接刻んで、将来の家計方針変更を妨げない。

## 3. envelope computation の最小用語

### `allocated`

意味:

```text
allocated = relevant period において、target / envelope に配賦された金額
```

候補 source:

- `budget_alloc.tsv`
- existing budget allocation projection
- future policy mapping

最初の prototype では、fixture-only policy helper と `budget_alloc.tsv` の公開 fixture row に限定して確認します。
production data 向けの policy source はまだ最終固定していません。

重要:

- `allocated` は actual spending ではない。
- `allocated` は plan expense と同じではない。
- `allocated` は household policy target ごとに見る。
- signed ledger total から推測しない。

### `actual_spent`

意味:

```text
actual_spent = relevant period における actual debit-side spending
```

条件:

- `role=expense` account を使う。
- prefix fallback は互換として残してよいが、名前だけを正本ルールにしない。
- target selection は `budget=...` または future policy mapping による。
- signed ledger total を household spending total として使わない。
- `src_next_actual_total` のような signed ledger-like total は参照用であり、household spending total ではない。

### `remaining`

最初の target-level remaining の意味:

```text
remaining = allocated - actual_spent
```

これは最初の実装予定の `remaining` です。

必ず守ること:

- planned spending はまだ引かない。
- `safe_remaining` ではない。
- `daily_amount` ではない。
- per-day allowance ではない。
- `remaining` を「安全に使える額」と表示しない。

### `safe_remaining` later work

後続 work の候補として、次の意味を予約します。

```text
safe_remaining = allocated - actual_spent - planned_spending
```

この PR では実装しません。
最初の `remaining` 実装にも混ぜません。

### `daily_amount` later work

後続 work の候補として、次の意味を予約します。

```text
daily_amount = remaining / remaining_days
```

この PR では実装しません。
`daily_amount` を実装する場合は、`remaining_days` の定義、除外日、cycle end exclusive の扱い、unavailable 条件を別途固定します。

## 4. target selection contract

food-like / daily-like reporting は、account name ではなく policy target によって選びます。

Future policy shape example:

```tsv
target_id	label	selector_key	selector_value
food_like	食費	budget	食費
```

これは将来の policy shape 例です。この PR では新しい TSV を追加しません。

明示的な禁止:

- account name matching で `expenses:食費` を選ばない。
- `budget=食費` を直接 engine concept として固定しない。
- `daily` / `flex` / `reserve` を engine 固定概念にしない。

将来の方針:

- future policy data により target selection を行う。
- target_id / label / selector は policy data として扱う。
- `selector_key=budget` のような stable key は計算コードが知ってよい。
- `selector_value=食費` のような concrete value は policy label として扱う。

初期 implementation PR で policy file がまだない場合の暫定策:

- fixture-only policy helper または existing account metadata selector に限定する。
- 2026-06-25 prototype は `fixtures/src-next-envelope-computation` だけを opt-in policy source とする。
- production data に polished remaining を出す前に policy source を固定する。
- policy source が未固定なら、production-like output は `unavailable/src_next` または `fallback/current-engine` として明示する。

## 5. `budget=` / `budget_group=` / `spend_class=` の役割分担

### `budget=...`

- target / envelope の細かい分類。
- food-like target などの selector 候補。
- 例: `budget=食費`。
- concrete value は policy label。
- `budget=...` 欠損時に default target へ黙って入れない。

### `budget_group=...`

- broad household grouping。
- daily/flex/reserve-style grouping の候補。
- concrete values は policy label。
- missing の場合は diagnostics に出す。
- missing のまま polished daily/flex/reserve remaining を出さない。

### `spend_class=...`

- later reporting / diagnostics 用。
- `remaining` 計算の hidden rule にしない。
- `spend_class=variable` だから daily target、のような暗黙推論をしない。
- `fixed=1` などの legacy hints を勝手に `spend_class=` へ変換しない。

## 6. production data に metadata が足りない場合

production data に household metadata が足りない場合も、source row 自体を自動 invalid にしない。
ただし、信頼できる polished remaining を出してはいけません。

必ず守ること:

- missing `budget=`, `budget_group=`, `spend_class=` は non-fatal。
- missing metadata を default category に変換しない。
- missing metadata がある状態で polished remaining を出さない。
- 必要 metadata や policy source が足りない場合は `unavailable/src_next` として明示する。
- current engine の値を見る必要がある場合は `fallback/current-engine` として明示する。
- household metadata diagnostics を参照し、欠損 count / missing account list を見える状態にする。

これは「足りない metadata を許して計算する」という意味ではありません。
「足りないことを diagnostics と unavailable / fallback として安全に見せる」という意味です。

## 7. Output boundary

将来の minimal implementation が出してよい候補です。
private な production amount は docs に書きません。

```text
--- SrcNext Envelope Computation ---
src_next_envelope_target_id: food_like
src_next_envelope_label: 食費
src_next_envelope_selector: budget=食費
src_next_envelope_allocated: <amount>
src_next_envelope_actual_spent: <amount>
src_next_envelope_remaining: <amount>
src_next_envelope_status: computed|unavailable/src_next|fallback/current-engine
```

表示上の注意:

- `allocated`、`actual_spent`、`remaining` を別 field として出す。
- `remaining` に planned spending を混ぜない。
- `safe_remaining` や `daily_amount` を未実装のまま同じ field に押し込まない。
- policy source / selector を表示または debug 可能にする。
- source row / metadata 欠損がある場合は status に反映する。

## 8. unavailable / fallback semantics

| status | 意味 |
|---|---|
| `computed` | `src_next` がこの contract に沿って計算できた値。 |
| `unavailable/src_next` | 必要 metadata や policy source が足りず、`src_next` では安全に計算しない値。 |
| `fallback/current-engine` | current engine の値を参照すべき値。 |

この PR では fallback 実装をしません。
将来 fallback を表示する場合も、`src_next` 計算値と current engine 由来値を黙って混ぜてはいけません。

## 9. Future fixture strategy

将来の implementation PR では、少なくとも次の fixture を用意します。

| fixture scenario | 確認すること |
|---|---|
| complete metadata + allocation + actual spending | `allocated`, `actual_spent`, `remaining` が契約通り出る。 |
| missing `budget_group=` | non-fatal だが diagnostics / unavailable 境界が出る。 |
| missing `budget=` | target selection できない場合に default category へ入れない。 |
| no allocation | `allocated` 不足時に polished remaining を出さない。 |
| actual spending without target policy | actual expense は存在しても target-level remaining を出さない。 |
| plan spending present but remaining does not subtract it yet | 最初の `remaining` が planned spending を引かないことを固定する。 |
| safe_remaining later fixture, implementation pending | `safe_remaining` は later work として分離する。 |

fixture 方針:

- private production amount を golden docs に書かない。
- policy label の例として `食費`, `daily`, `flex`, `reserve` を使ってもよいが、engine concept として固定しない。
- group label を変えた fixture を後続で検討する。
- signed ledger total と household debit-side spending total の違いを検査する。

## 10. Implemented fixture-only prototype boundary

2026-06-25 prototype:

- module: `src_next/envelope_computation.bqn`
- fixture: `fixtures/src-next-envelope-computation`
- compact section: `--- SrcNext Envelope Computation ---`
- computed fields: `allocated`, `actual_spent`, `remaining`
- formula: `remaining = allocated - actual_spent`
- status vocabulary used: `computed`, `unavailable/src_next`
- planned spending is not subtracted
- `safe_remaining` is not implemented
- `daily_amount` / per-day allowance is not implemented
- production polished remaining is not emitted
- production `tools/report-next-summary data` is guarded by `checks/check-src-next-envelope-production-guard.sh` and must stay `src_next_envelope_status: unavailable/src_next`
- policy source is fixture-only and not final for production

Complete fixture conditions for `computed`:

- fixture policy target exists
- allocation row exists for the target budget account in the relevant cycle
- selected expense accounts resolve via `role=expense` and `budget=...`
- actual spending is debit-side actual expense spending for selected accounts

When these conditions are not met, the prototype emits `unavailable/src_next` rather than a polished remaining value.

## 11. Non-goals

- Do not implement production envelope computation in this PR.
- Do not implement food remaining in this PR.
- Do not implement daily remaining in this PR.
- Do not implement safe_remaining in this PR.
- Do not implement daily amount / per-day allowance in this PR.
- Do not change source TSV format.
- Do not edit production data.
- Do not change `main.bqn`.
- Do not switch production default.
- Do not hard-code `食費`, `daily`, `flex`, `reserve` as engine concepts.
- Do not silently convert missing metadata to default policy labels.

## 12. Related documents

- `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` — Stage 4b daily-use trial readiness gate 定義。
- `docs/SRC_NEXT_REPLACEMENT_READINESS.md` — Stage 4a / 4b / default switch gate。
- `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` — Section 5 / 9 の missing feature 状態。
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` — household policy と stable key / policy label 境界。
- `docs/SRC_NEXT_EXPENSE_ACCOUNT_MAPPING.md` — observed account mapping / diagnostics companion。
- `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` — Snapshot の fallback / unavailable 表示境界。
- `docs/REPORT_POLICY_EXTERNALIZATION_PLAN.md` — report policy externalization の設計トラック。
- `docs/REPORT_ASSUMPTION_AUDIT.md` — hard-coded household label 棚卸し。
- `docs/ACCOUNT_ROLE_CONTRACT.md` — account role / budget_group contract。
- [SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md](SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md) — Stage 4a 観測面棚卸し

