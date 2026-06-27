# src_next Stage 4b Start Decision Checklist

Status: docs-only checklist / no Stage 4b start / no implementation change / no production replacement / no production advice
Branch: `docs-src-next-stage4b-start-decision-checklist`
Date: 2026-06-25

この文書は、`src_next` Stage 4b daily-use trial を **実際に開始する直前** に確認する checklist です。

重要:

- **この文書自体は Stage 4b を開始しない。**
- **この文書は production replacement readiness を意味しない。**
- **production default は変更しない。**
- **この文書に実装変更は含まれない。**
- **この checklist を満たしても、別途明示的な開始宣言がない限り Stage 4b は開始されない。**

合言葉:

```text
まだドラゴンは起こさない。鍵を揃えて、札を確認するだけ。
```

---

## 1. Purpose

この checklist の目的:

- Stage 4b daily-use trial を開始する直前に、すべての前提が揃っていることを確認する。
- P0-4（defer → start の明示的判断）と P0-6（observation-only terms 再表明）を実際に行う際の最終確認項目を整理する。
- この checklist 自体が Stage 4b 開始宣言ではないことを明文化する。
- 開始判断の誤り（準備不足のまま開始、production advice への混入）を防ぐ。

この checklist は、将来 P0-4 の明示的な開始判断を検討する時に使う。
この文書自体は `docs/SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md` の decision を変更しない。

---

## 2. Non-goals

この文書では以下を行わない。

| # | Non-goal |
|:---|:---|
| 1 | Stage 4b を開始しない |
| 2 | production default を変更しない |
| 3 | `bqn main.bqn` を置き換えない |
| 4 | production advice を開始しない |
| 5 | `data/*.tsv` を編集しない |
| 6 | `src_next` に `data/*.tsv` を編集させない |
| 7 | private comparison log を public repo に commit しない |
| 8 | production data の具体的な金額を public docs / commit に含めない |
| 9 | BQN 実装を変更しない |
| 10 | fixtures を変更しない |
| 11 | check script を変更しない |
| 12 | `safe_remaining` を実装しない |
| 13 | `daily_amount` を実装しない |
| 14 | outlook を実装しない |
| 15 | envelope advice を開始しない |
| 16 | budget advice を開始しない |
| 17 | production replacement を宣言しない |

---

## 3. Current state (before any start decision)

この checklist 作成時点の状態:

| Item | State |
|:---|:---|
| Stage 4b | **not started** |
| production default | `bqn main.bqn` |
| `src_next` role | observation-only |
| entry decision | **defer**（`docs/SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md` §11） |
| P0-5 (trial log location) | ✅ defined（`docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md`） |
| P0-4 (decision change) | ⏳ deferred |
| P0-6 (observation-only restatement) | ⏳ required at start |

---

## 4. Pre-start checklist

Stage 4b を開始する直前に、以下の全項目を確認する。

チェック欄は、実際に開始判断をする時に埋める。

### 4.1 Technical checks

| # | Item | Check | Reference |
|:---|:---|:---|:---|
| T-1 | `tools/check.sh` が pass | [ ] | |
| T-2 | latest dry run で `bug/src_next = 0` | [ ] | `docs/SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md` §5 |
| T-3 | latest dry run で `unclassified = 0` | [ ] | 同上 |
| T-4 | latest dry run で `requires-contract = 0` | [ ] | 同上 |
| T-5 | known differences がすべて分類済み | [ ] | 同上 §6 |
| T-6 | envelope production guard が通過 | [ ] | `tools/check.sh` に統合済み |
| T-7 | `src_next` が `data/*.tsv` を編集しないことが維持されている | [ ] | read-only hard guardrail |
| T-8 | `computed` envelope status が production data に出ていない | [ ] | Gate C |
| T-9 | `unavailable/src_next` が production data で維持されている | [ ] | Gate C |

### 4.2 Documentation checks

| # | Item | Check | Reference |
|:---|:---|:---|:---|
| D-1 | trial scope が定義済み | [ ] | `docs/SRC_NEXT_STAGE4B_TRIAL_SCOPE.md` |
| D-2 | readiness gate が定義済み | [ ] | `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` |
| D-3 | snapshot equivalence criteria が定義済み | [ ] | `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` |
| D-4 | manual comparison procedure が定義済み | [ ] | `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` |
| D-5 | daily-use trial log policy が定義済み | [ ] | `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` |
| D-6 | pretrial backlog が定義済み | [ ] | `docs/SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md` |
| D-7 | entry decision record が最新 | [ ] | `docs/SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md` |
| D-8 | この checklist が main に merge 済み | [ ] | `docs/SRC_NEXT_STAGE4B_START_DECISION_CHECKLIST.md` |

### 4.3 P0 backlog checks

| # | Item | Check | Reference |
|:---|:---|:---|:---|
| P-1 | P0-1〜P0-3（`bug/src_next`/`unclassified`/`requires-contract` = 0）が維持されている | [ ] | pretrial backlog §5 |
| P-2 | P0-5（trial log location）が定義済み・公開されていない | [ ] | daily-use trial log policy |
| P-3 | P0-7（`src_next` が `data/*.tsv` を編集しない）が維持されている | [ ] | pretrial backlog §5 |
| P-4 | P0-8（unsupported/unavailable fields を生活判断に使わない）が維持されている | [ ] | 同上 |
| P-5 | P0-9（production default が `bqn main.bqn`）が維持されている | [ ] | 同上 |
| P-6 | P0-10（public-safe documentation only）が維持されている | [ ] | 同上 |

### 4.4 P0-6 observation-only terms restatement

P0-6 は Stage 4b 開始時に observation-only terms を再表明することを要求している。
開始宣言の中で、以下の全項目を明示的に再表明すること。

| # | Restatement item | Confirmed |
|:---|:---|:---|
| R-1 | `src_next` は observation-only であり、production advice engine ではない | [ ] |
| R-2 | `src_next` output を支出判断の主根拠にしない | [ ] |
| R-3 | `src_next` output を封筒判断の主根拠にしない | [ ] |
| R-4 | `src_next` output を予算判断の主根拠にしない | [ ] |
| R-5 | `src_next` output を生活判断（「今日あといくら使える」等）の主根拠にしない | [ ] |
| R-6 | production reference は current engine（`bqn main.bqn`）であり続ける | [ ] |
| R-7 | daily-use trial log は `private/src-next-stage4b/daily-use-trial-log.md` に置き、commit しない | [ ] |
| R-8 | public summary は status / classification / guardrail summaries のみ。production amounts / private log contents / production advice を含めない | [ ] |
| R-9 | unsupported / unavailable fields を黙って補完・推測して使わない | [ ] |
| R-10 | pause conditions（`docs/SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md` §9）を理解し、発生時に停止できる | [ ] |

### 4.5 Manual confirmation

以下の項目は、運用者（人間）が明示的に理解・確認する。

| # | Item | Confirmed |
|:---|:---|:---|
| M-1 | Stage 4b は daily-use trial であり、production replacement ではないことを理解している | [ ] |
| M-2 | Stage 4b 中も家計判断には `bqn main.bqn` の出力を使うことを理解している | [ ] |
| M-3 | `src_next` の出力を見て「今日はあといくら使える」と判断しないことを理解している | [ ] |
| M-4 | `src_next` の envelope output を封筒安全判断に使わないことを理解している | [ ] |
| M-5 | 差分が出た場合は分類・記録し、判断できない差分を無視しないことを理解している | [ ] |
| M-6 | pause conditions に該当した場合、trial を停止して current engine に戻すことを理解している | [ ] |
| M-7 | private log を誤って commit しないよう注意することを理解している | [ ] |
| M-8 | この checklist を満たしても、start decision がない限り Stage 4b は開始されないことを理解している | [ ] |

---

## 5. Future start decision requirements

この checklist の全項目が確認された後でも、この文書だけでは Stage 4b は開始されない。
Stage 4b を開始するには、将来の別 PR / 別 decision record で P0-4 を明示的に満たす必要がある。

### 5.1 Decision change requirement (P0-4)

P0-4 は、`docs/SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md` の decision を `defer` のままにせず、将来の別変更で明示的に開始判断へ変更することを要求する。

その将来の開始判断には、少なくとも以下を明記する必要がある:

- この checklist の全項目が確認済みであること
- P0-6 observation-only terms が再表明されていること
- Stage 4b daily-use trial は production replacement ではないこと
- production default は `bqn main.bqn` のままであること
- `src_next` は observation-only のままであること
- private daily-use trial log のパスと visibility rule が定義済みであること

### 5.2 If the start decision is not made

この checklist の項目が揃っていても、開始しない判断は常に可能。
開始しない場合、entry decision record の decision は `defer` のまま維持し、この checklist は未使用のまま残す。

---

## 6. Guardrails

この checklist が守る不変条件:

- Stage 4b は checklist の確認と明示的な開始宣言なしに開始されない。
- `src_next` は checklist を通過しても production advice engine にならない。
- production default は常に `bqn main.bqn`。
- private log は commit されない。
- public docs に production data amounts は含まれない。
- unsupported / unavailable fields は生活判断に使われない。
- `data/*.tsv` は `src_next` によって編集されない。

---

## 7. Related documents

- [SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md](SRC_NEXT_STAGE4B_ENTRY_DECISION_RECORD.md) — Stage 4b entry decision record（decision: defer）
- [SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md](SRC_NEXT_STAGE4B_PRETRIAL_BACKLOG.md) — P0 backlog items（P0-4, P0-6 の定義元）
- [SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md](SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md) — Daily-use trial log path と public-safe summary rule
- [SRC_NEXT_STAGE4B_TRIAL_SCOPE.md](SRC_NEXT_STAGE4B_TRIAL_SCOPE.md) — Observation-only trial scope、prohibited advice usage
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](SRC_NEXT_STAGE4B_READINESS_GATE.md) — Stage 4b readiness gate（Gate A–F）
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md) — Snapshot equivalence criteria
- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md) — Manual comparison procedure
- [SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md](SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md) — Comparison record template
- [SRC_NEXT_STAGE4_TRIAL_LOG.md](SRC_NEXT_STAGE4_TRIAL_LOG.md) — Stage 4 observation log template
- [SRC_NEXT_REPLACEMENT_READINESS.md](SRC_NEXT_REPLACEMENT_READINESS.md) — Replacement readiness checklist
