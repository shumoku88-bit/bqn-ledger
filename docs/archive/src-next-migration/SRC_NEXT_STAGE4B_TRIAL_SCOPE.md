# src_next Stage 4b Trial Scope

Status: docs-only scope definition / no implementation change / no Stage 4b start
Branch: `docs-define-src-next-stage4b-trial-scope`

この文書は、将来の `src_next` Stage 4b daily-use trial に入る前に、`src_next` output を **observation-only** でどこまで見てよいか、どこから先を production advice として禁止するかを定義する。

重要:

- **この文書は Stage 4b daily-use trial の開始宣言ではない。**
- **この文書は production replacement readiness を意味しない。**
- **production default は変更しない。**

合言葉:

```text
まだドラゴンは起こさない。首輪の長さを測るだけ。
```

---

## 1. Purpose

この文書の目的:

- Stage 4b daily-use trial の scope を、開始前に docs-only で定義する。
- Stage 4b が production replacement ではなく、observation-only daily-use trial であることを明文化する。
- current engine と `src_next` を並走させるため、何を観察対象にしてよいかを固定する。
- `src_next` output を生活判断、支出判断、封筒判断、予算判断の主根拠にしないことを明文化する。

Stage 4b 中も、current engine が production reference であり続ける。
`src_next` は observation target であり、production advice engine ではない。

---

## 2. Non-goals

この trial scope は、以下を扱わない。

| # | Non-goal |
|:---|:---|
| 1 | production default を変更しない |
| 2 | `bqn main.bqn` を置き換えない |
| 3 | `data/*.tsv` を編集しない |
| 4 | BQN 実装を変更しない |
| 5 | fixtures を変更しない |
| 6 | check script を変更しない |
| 7 | `safe_remaining` / `daily_amount` / outlook を実装しない |
| 8 | envelope advice を開始しない |
| 9 | budget advice を開始しない |
| 10 | Stage 4b daily-use trial を開始しない |
| 11 | production replacement を宣言しない |

---

## 3. Production default

The production default remains `bqn main.bqn`.

Stage 4b daily-use trial 中でも、`src_next` は observation target のままである。
`src_next` を production advice engine として扱わない。
`src_next` output を current engine の代替レポートとして使わない。

---

## 4. Observation-only rule

Stage 4b trial 中の基本ルール:

- `src_next` output は観察・比較・記録のためだけに使う。
- `src_next` output を支出判断、封筒判断、予算判断、生活判断の主根拠にしない。
- current engine の output が production reference であり続ける。
- 差分が出た場合は、分類して記録する。
- 分類不能な差分を無視して trial を進めない。
- match 済みの observation area であっても、production advice には使わない。

---

## 5. Allowed observation areas

Stage 4b trial で observation 対象にしてよい areas は以下に限定する。

| Area | Trial use | Notes |
|:---|:---|:---|
| cycle boundary | 観察・比較・記録のみ | cycle range は半開区間 `[cycle_start, cycle_end_exclusive)` として扱う。 |
| actual totals | 観察・比較・記録のみ | income / expense / net actual など。production advice には使わない。 |
| account balances | 観察・比較・記録のみ | nonzero actual account totals の比較。生活判断の主根拠にしない。 |
| unknown accounts | 観察・比較・記録のみ | unknown count / list の確認。黙って補正しない。 |
| envelope production guard | guard 状態の確認のみ | production data で `unavailable/src_next` が維持されることを見る。advice として使わない。 |
| next income | 観察・比較・記録のみ | current engine との比較対象。支出判断の主根拠にしない。 |
| plan totals baseline / cycle-bounded | 観察・比較・記録のみ | PR #44 の boundary semantics に従い、`cycle_end_exclusive` 当日の plan rows は current cycle に含めない。 |
| plan totals export semantics | scope 差の記録のみ | current engine export と `src_next` observation の scope 差を記録する。 |
| remaining days | 観察・比較・記録のみ | `as_of` 差により `expected/current-engine-difference` になり得ることを明記して観察する。 |

注意:

- plan totals は半開区間 `[cycle_start, cycle_end_exclusive)` に従って見る。
- `cycle_end_exclusive` 当日の `plan.tsv` rows は current cycle に含めない。
- 境界日 plan rows による差分が分類済みなら、`expected/current-engine-difference` として記録し、単独では Gate A blocker としない。
- remaining days は `as_of` 差に影響されるため、差分原因を記録する。
- allowed observation area で一致しても、production advice への利用は許可されない。

---

## 6. Out-of-scope areas

以下は Stage 4b trial scope 外であり、daily-use trial の判断材料にしない。

| Area / field | Scope status | Reason |
|:---|:---|:---|
| budget totals | `unsupported/src_next` | `src_next` 側の budget layer / budget total parity は未対応。 |
| skipped rows | `unsupported/src_next` | current engine と `src_next` で row model が異なるため、daily-use trial 判断材料にしない。 |
| valid row count | `unsupported/src_next` | raw row count と projection row model を混同しない。 |
| actual_comparison | `unsupported/src_next` | `src_next` では `not_implemented` / placeholder の範囲。 |
| net_worth | `unavailable/src_next` | 概念は current engine 側にあるが、`src_next` trial 判断材料にしない。 |
| daily_remaining | `unavailable/src_next` | fallback/current-engine または unavailable として扱い、`src_next` advice にしない。 |
| envelopes | `unavailable/src_next` | production data では guard を維持し、封筒 advice に使わない。 |
| daily_amount | `unsupported/src_next` | 未実装。 |
| safe_remaining | `unsupported/src_next` | 未実装。 |
| outlook | `unsupported/src_next` | 未実装。 |
| envelope advice | out of scope | `src_next` envelope output を production advice として使わない。 |
| budget advice | out of scope | `src_next` output を予算配分判断に使わない。 |

分類の考え方:

- 概念はあるが `src_next` で観測できないものは `unavailable` とする。
- 機能や概念が `src_next` にまだないものは `unsupported` とする。
- unsupported / unavailable fields は daily-use trial の判断材料にしない。
- unsupported / unavailable を黙って補完・推測して使わない。

---

## 7. Prohibited advice usage

Stage 4b trial scope では、以下を明確に禁止する。

- `src_next` の envelope output を production advice として使う。
- `src_next` の未実装 field を補完推測して使う。
- `src_next` を見て「今日はあといくら使える」と判断する。
- `src_next` を見て「封筒が安全」と判断する。
- `src_next` を見て budget allocation を変更する。
- `src_next` を production replacement として扱う。
- `src_next` output を current engine の production report の代替として扱う。
- unsupported / unavailable field を生活判断の主根拠にする。

---

## 8. Mismatch handling

差分が出た場合は、必ず分類して記録する。
判断できない差分を `expected/current-engine-difference` にしない。

分類:

| Classification | Meaning | Trial handling |
|:---|:---|:---|
| `expected/current-engine-difference` | current engine と `src_next` の責任境界や既知 semantics 差による差分 | 理由を記録して継続可能。 |
| `bug/src_next` | `src_next` 側の計算・投影・表示の疑い | pause candidate。 |
| `bug/current-engine` | current engine 側の既知または疑いのある問題 | 別途調査。current engine を安易に変えない。 |
| `unsupported/src_next` | `src_next` がまだ対応していない field / behavior | scope 外として記録する。 |
| `policy/not-engine` | household policy の問題であり engine equivalence ではない | 別 contract / policy docs で扱う。 |
| `requires-contract` | 契約なしには判断できないもの | pause candidate。 |
| `unclassified` | どの分類にも入れられない差分 | pause candidate。 |
| `unavailable` | 概念はあるが `src_next` で観測・出力できない状態 | scope 外として記録する。 |

ルール:

- `expected/current-engine-difference` は記録して継続可能。
- `unsupported/src_next` / `unavailable` は scope 外として記録する。
- `bug/src_next` は pause candidate。
- `requires-contract` は pause candidate。
- `unclassified` は pause candidate。
- 判断できない差分を expected にしない。

---

## 9. Pause conditions

この PR では Stage 4b を開始しない。
将来 Stage 4b trial を開始した後、以下が発生した場合は trial の一時停止候補とする。

- `bug/src_next` が出た。
- `unclassified` difference が出た。
- `requires-contract` が出た。
- production output と `src_next` output の差分が説明不能。
- unsupported / unavailable field を生活判断に使いそうになった。
- `src_next` output を production advice として使いそうになった。
- `data/*.tsv` を `src_next` 経由で編集しそうになった。
- envelope / budget / safe_remaining / daily_amount / outlook を advice として扱いそうになった。
- `src_next` を production replacement として扱いそうになった。

停止時は current engine（`bqn main.bqn`）を production reference として使い続け、差分を分類・記録してから再開可否を判断する。

---

## 10. Entry conditions

Stage 4b daily-use trial に入る前の条件:

- [ ] `tools/check.sh` が pass している。
- [ ] latest manual comparison が記録済みである。
- [ ] `bug/src_next = 0`。
- [ ] `unclassified = 0`。
- [ ] `requires-contract = 0`。
- [ ] known differences が分類済みである。
- [ ] unsupported / unavailable fields が trial scope 外として明示済みである。
- [ ] production default が `bqn main.bqn` のままである。
- [ ] daily-use trial log location が `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` で定義されている。
- [ ] daily-use trial log が private-only であり、public summary は status / classification / guardrail summaries のみに制限されている。
- [ ] private comparison log が commit されていない。
- [ ] production data の具体的な金額が public docs / PR / summary に含まれていない。
- [ ] `src_next` が `data/*.tsv` を編集しないことが維持されている。

これらを満たしても、この文書単独では Stage 4b 開始宣言にはならない。
Stage 4b 開始判断は別途行う。

---

## 11. Exit criteria

Stage 4b trial を終える、または次段階へ進むための条件:

- 複数日の daily observation で重大な未分類差分がない。
- known differences が安定して分類できる。
- production advice に使ってはいけない fields が運用に混入していない。
- unsupported / unavailable areas の扱いが明確である。
- envelope / budget / safe_remaining / daily_amount / outlook を advice として扱っていない。
- `data/*.tsv` を `src_next` 経由で編集していない。
- Stage 4c 以降へ進む場合は、別 PR / 別 docs で判断する。
- この docs 自体を replacement readiness とみなしていない。

この docs は trial scope を定義するだけであり、production replacement readiness を意味しない。

---

## 12. Relationship to readiness gate

`docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` は、Stage 4b daily-use trial に入るための readiness gate を定義する。
この文書は、その readiness gate の一部を補助し、trial 中に `src_next` output をどう扱うかの scope を明文化する。

関係:

- この文書は readiness gate の補助文書である。
- この文書は Stage 4b 開始宣言ではない。
- Stage 4b 開始判断は別途行う。
- trial scope が定義されただけでは production replacement できない。
- production default は `bqn main.bqn` のままである。

---

## 13. Related Documents

- [SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md](SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md) — Public-safe pretrial backlog before any Stage 4b start decision
- [SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md](SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md) — Daily-use trial private log path and public-safe summary rule
- [SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md](SRC_NEXT_STAGE4B_THIRD_DRY_RUN_PLAN.md) — Public-safe plan for a third manual comparison dry run before any Stage 4b start decision
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md) — Stage 4b daily-use trial readiness gate
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md) — Snapshot equivalence criteria and difference classification
- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md) — Manual comparison procedure
- [SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md](SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md) — Private/manual comparison record template
- [SRC_NEXT_STAGE4_TRIAL_LOG.md](SRC_NEXT_STAGE4_TRIAL_LOG.md) — Stage 4 observation log template
- [SRC_NEXT_REPLACEMENT_READINESS.md](SRC_NEXT_REPLACEMENT_READINESS.md) — Replacement readiness checklist
