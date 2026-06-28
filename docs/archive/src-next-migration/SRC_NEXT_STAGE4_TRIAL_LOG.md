# src_next Stage 4 観察ログ

状態: **日本語を正本とする観察 template / 本番動作の変更なし**

この文書は、`src_next` の Stage 4 をどう観察するかを決める手順書です。

重要:

- compact summary を横で見るだけでは、まだ「使いながら1サイクル観察」ではありません。
- `src_next` 側のレポートが日々の家計判断に使える状態になってから、1サイクル以上の daily-use trial を始めます。
- その前の作業は **Stage 4a: 普段使い観察の準備** と呼びます。
- 実際に日々の判断で `src_next` を読む段階を **Stage 4b: 1サイクル以上の daily-use trial** と呼びます。
- Snapshot は Stage 4a で優先して育てる観測画面です。設計は `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` を参照します。

最新境界:

- Stage 4b はまだ開始していません。
- 将来 Stage 4b を開始しても、production default は `bqn main.bqn` のままです。
- `src_next` は observation-only であり、production advice として扱いません。
- Stage 4b 開始には別の明示的な start decision が必要です。

この文書は実際の金額や private な判断メモを含みません。

---

## 1. 目的

この文書は、`src_next` replacement readiness gate の Stage 4 観察 template です。
詳しい gate は `docs/SRC_NEXT_REPLACEMENT_READINESS.md` を参照します。

Stage 4 の目的は、次の2つを分けることです。

### Stage 4a: 普段使い観察の準備

- `src_next` に本番レポート相当の section を増やす。
- compact output と current engine の比較面を増やす。
- 本番 12 section のうち、matched / partial / missing / fallback / intentionally replaced を整理する。
- Snapshot を「数値 + 状態ラベル + 観測コメント + 必要なら ASCII art」の観測画面として育てる。
- まだ運用者が普段の家計判断に使えないなら、daily-use trial 開始とはみなさない。

### Stage 4b: 1サイクル以上の daily-use trial

- `src_next` 側のレポートを、実際の日々の家計判断で読める状態にする。
- 少なくとも1 full cycle、実生活の入力・確認・判断に合わせて観察する。
- `bqn main.bqn` は rollback として残す。
- 家計判断に影響する divergence は、Stage 5 前に修正するか、意図的な差分として文書化する。

この文書で定義すること:

- 観察の rhythm と commands
- Stage 4a / 4b の checklist
- divergence log の書き方
- exit criteria
- private / local notes の扱い

---

## 2. privacy note

**実際の家計金額、private な日々の判断メモ、個人を特定できる金融情報を、この public repository に commit してはいけません。**

この文書は template と手順書です。
実際の観察値は private / local log に書きます。

Stage 4b daily-use trial の future private log path は次で定義します:

```text
private/src-next-stage4b/daily-use-trial-log.md
```

この path は `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` の docs-only pretrial 定義です。file を作成・commit せず、この定義だけでは Stage 4b を開始しません。

repo の public docs には、実金額ではなく「private log をこの規則で残す」とだけ書きます。

---

## 3. 試験用 commands

### trusted production default

```sh
bqn main.bqn
```

これは現在の本番です。
日々の家計判断で信頼する既定ルートです。

### src_next full diagnostic output

```sh
tools/report-next
```

これは `bqn src_next/main.bqn data` 相当です。
AccountKey、projection rows、cube、household policy などの diagnostic output を含みます。

### src_next compact daily observation surface

```sh
tools/report-next-summary
```

これは `bqn src_next/summary.bqn data` 相当です。
cycle info と compact src_next sections を出します。

すべての command は既定で `data/` を読みます。
すべて read-only であり、TSV file を編集しません。

---

## 4. compact summary の現在の内容

2026-06-24 時点で、`src_next` output には `--- SrcNext Minimal Report Summary ---` があり、次の machine-checkable fields を出します。

- `src_next_cycle_range` — cycle start..end
- `src_next_valid_projection_rows` / `src_next_skipped_projection_rows` — projection partition counts
- `src_next_actual_total` / `src_next_plan_total` — signed layer totals
- `src_next_actual_expense_total` / `src_next_plan_expense_total` — debit-side expense totals
- `src_next_actual_account_total` / `src_next_plan_account_total` — nonzero per-account totals

これらは `checks/check-src-next-minimal-summary.sh` で確認します。
check は field presence、format validity、internal consistency を見ます。
この check は `src_next` fixtures に対して実行され、`tools/check.sh` に含まれています。

2026-06-24 時点で、`tools/report-next-summary` には `--- SrcNext Cycle Summary ---` もあります。

- `src_next_cycle_start`
- `src_next_cycle_end_exclusive`
- `src_next_cycle_day_count`
- `src_next_cycle_income_actual`
- `src_next_cycle_expense_actual`
- `src_next_cycle_net_actual`
- `src_next_cycle_plan_expense`

`checks/check-src-next-cycle-summary.sh` は、current exporter が走れる fixtures で、cycle start/end、income actual、expense actual、net actual を `src/reports/exporters/export-cycle-summary.bqn` と比較します。

---

## 5. compact summary に含まれる partial sections

2026-06-24 時点で、compact summary は次の partial sections を含みます。

### `--- SrcNext YTD Summary ---`

- `src_next_ytd_range`
- `src_next_ytd_income_actual`
- `src_next_ytd_expense_actual`
- `src_next_ytd_net_actual`
- calendar year start から loaded cycle end boundary までの actual journal rows を見る。
- supported fixtures では `summary.bqn` YTD fields と比較される。

### `--- SrcNext Cycle Expense Breakdown ---`

- `src_next_cycle_expense_breakdown_total`
- `src_next_cycle_expense_breakdown: <account_key> <amount>`
- actual layer、expense kind、debit side only。
- `check-src-next-expense-breakdown.sh` で確認される。

### `--- SrcNext Recent Journal ---`

- `src_next_recent_journal: <date> <memo/source_id> <from> -> <to> <amount>`
- last 10 actual source journal rows を出す。
- completion inference はしない。

### `--- SrcNext Planned Payments ---`

- `src_next_planned_payment: <date> <status> <memo/source_id> <from> <to> <amount>`
- current-cycle source plan rows を出す。
- status は exact date/memo/from/to/amount matching に基づき、conservative に `planned` / `paid` / `ambiguous` を使う。

### `--- SrcNext Balances ---`

- `src_next_balance: <account_key> <amount>`
- nonzero actual account totals のみ。
- liquid / savings / invest grouping はまだない。

### `--- SrcNext Readiness Check ---`

- projection valid/skipped counts
- skipped category counts
- unknown-account count
- out-of-cycle skipped count
- production Sec8 hygiene warnings より小さい。

### `--- SrcNext Actual Comparison ---`

- `src_next_actual_comparison_status: not_implemented`
- `src_next_actual_comparison_reason: requires historical cycle comparison`
- explicit placeholder のみ。
- parity claim ではない。

これらは **Stage 4a の観察面** です。
これだけで `src_next` が production-ready になったわけではありません。
section-level parity は `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` を見ます。

---

## 6. Snapshot 観測画面

Snapshot は、Stage 4a で優先して育てる画面です。

目的:

- 毎日最初に見る入口にする。
- 数字だけでなく、状態ラベルと短い観測コメントを出す。
- 必要なら ASCII art を表示できるようにする。
- ただし、計算層と表示層を混ぜない。

設計の正本:

- `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md`

Stage 4a では、Snapshot が次を示せるようにします。

- どの数字が `src_next` 由来か。
- どの数字が current engine fallback 由来か。
- どの情報がまだ missing か。
- ASCII art が表示専用であり、計算結果に影響しないこと。

---

## 7. machine-readable exports

field ごとの systematic comparison には、current engine の exporter を使います。

例:

- `tools/export-cycle-summary.bqn`
- `tools/export-plan-summary.bqn`

`src_next` に同等 exporter がない場合は、`missing src_next feature` として記録します。

---

## 8. 観察 rhythm

Stage 4 は、Stage 4a と Stage 4b で意味が違います。

| stage | rhythm | what |
|---|---|---|
| Stage 4a | PR / 実装ごと | compact output、partial section、comparison field、Snapshot 観測画面を育てる。日常判断にはまだ使わない。 |
| Stage 4a | 必要に応じて | current engine との差分を fixture や exporter で確認する。 |
| Stage 4b | daily or near-daily 推奨 | `src_next` 側のレポートを普段の確認に使い、違和感を private log に残す。 |
| Stage 4b | cycle-end mandatory | 1 cycle 終了時に systematic comparison を行い、divergence を分類する。 |

Stage 4b の gate が満たされるのは、少なくとも1 full cycle の daily-use trial と cycle-end review が終わり、divergence が分類されたときです。

---

## 9. Stage 4a checklist: 普段使い観察の準備

`src_next` を日々の判断で使う前に、この checklist を確認します。

| # | item | status | note |
|---|---|---|---|
| 1 | 本番 12 section の parity matrix が更新されている | | `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` |
| 2 | missing section が生活判断に影響するか確認済み | | 影響するなら Stage 4b は開始しない |
| 3 | partial section が日常判断を壊さない理由を書いている | | 未説明なら Stage 4b は開始しない |
| 4 | fallback section があるなら、どの command で見るか決めている | | current engine fallback など |
| 5 | `tools/report-next` / `tools/report-next-summary` の役割が日本語で説明されている | | 運用者が読めること |
| 6 | Snapshot 観測画面の方針が文書化されている | | `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` |
| 7 | ASCII art は表示専用で、計算層に混ぜないと明記されている | | Snapshot doc を参照 |
| 8 | `bqn main.bqn` が rollback として残る | | default switch しない |

---

## 10. Stage 4b checklist: 1サイクル以上の daily-use trial

Stage 4b を開始したら、cycle-end review でこの表を private log に copy して使います。

| # | item | main.bqn | src_next / fallback | match? | classification |
|---|---|---|---|---|---|
| 1 | 現在サイクル集計 | | | | |
| 2 | 次回収入日までの残り | | | | |
| 3 | 食費 / Daily の残額 | | | | |
| 4 | plan vs actual difference | | | | |
| 5 | 未完了の予定支払い | | | | |
| 6 | checks / warnings / unavailable sections | | | | |
| 7 | envelope / household policy diagnostics | | | | |
| 8 | 日々の workflow で使う machine-readable export equivalents | | | | |
| 9 | 本番 12 section のうち、読めなくなった section がないか | | | | |
| 10 | Snapshot が日々の入口として読めるか | | | | |

`match?` は `yes` / `no` / `n/a` で書きます。
`n/a` は `src_next` にまだ実装されていない場合です。
`no` と `n/a` は必ず分類します。

---

## 11. item notes

1. **現在サイクル集計**
   - cycle range、start/end、day count、active cycle window が一致するかを見る。
2. **次回収入日までの残り**
   - days remaining、next income date、両 engine の計算が同じかを見る。
3. **食費 / Daily の残額**
   - `src_next` ではまだ未実装なら、`missing src_next feature` として扱う。
   - 生活判断に使うなら Stage 4b の blocker。
4. **plan vs actual difference**
   - expense totals、plan remaining、household-accounting numbers が一致するかを見る。
5. **未完了の予定支払い**
   - plan rows と journaled rows の対応を確認する。
6. **checks / warnings / unavailable sections**
   - error messages、lint warnings、safety surface differences を見る。
   - known difference: current engine は future / unknown rows で fail closed し、`src_next` は skip する場合がある。
7. **envelope / household policy diagnostics**
   - envelope balances、budget group summaries、policy shape visibility を見る。
8. **machine-readable export equivalents**
   - 日々の workflow で使う exporter に `src_next` equivalent があるかを見る。
9. **本番 12 section の読みやすさ**
   - `src_next` で情報が欠ける、分かりづらい、生活判断を支えない section がないかを見る。
10. **Snapshot が日々の入口として読めるか**
   - 数字、状態ラベル、観測コメント、fallback 表示が分かるかを見る。
   - ASCII art が邪魔をせず、表示専用として扱われているかを見る。

---

## 12. divergence log format

差分を見つけたら、private log に次の形式で記録します。

| date | stage | item # | observation | src_next / fallback value | main.bqn value | classification | action |
|---|---|---|---|---|---|---|---|
| YYYY-MM-DD | 4a or 4b | 1-10 | short description | | | category | next step |

実金額は public repo に書きません。
必要なら private log にだけ書きます。

---

## 13. 分類 categories

`docs/SRC_NEXT_REPLACEMENT_READINESS.md` §5 と同じ分類を使います。

| category | 使う場面 | action |
|---|---|---|
| `intentional replacement` | current engine の値や section をやめ、新しい意味へ置き換える場合 | 判断理由を記録する。 |
| `missing src_next feature` | current engine が出す値を `src_next` がまだ出せない場合 | blocking gap として扱う。 |
| `current-engine compatibility requirement` | 両者の意味が意図的に違い、互換契約が必要な場合 | 契約を文書化する。 |
| `regression candidate` | 重要な値が説明なく違う場合 | どちらの engine も安易に変えず調査する。 |
| `unknown / needs investigation` | 証拠が足りず判断できない場合 | 小さい fixture や exporter で調査する。 |

---

## 14. private log convention

実際の Stage 4b daily-use trial log は private path に置きます。

定義済み path:

```text
private/src-next-stage4b/daily-use-trial-log.md
```

この path は private-only です。actual divergence values、private daily notes、household amounts を public docs / PR / summary に含めません。

Public summary を作る場合は、`docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` の public-safe summary rule に従い、status / classification / guardrail summaries のみにします。

---

## 15. Stage 4a exit criteria

Stage 4a が終わる条件:

- [ ] `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` が最新。
- [ ] 本番 12 section のうち、daily-use trial に必要な情報が matched / intentionally replaced / fallback のいずれかで読める。
- [ ] missing section が生活判断に影響する場合、それを blocker として残している。
- [ ] partial section がある場合、日常判断を壊さない理由が文書化されている。
- [ ] Snapshot 観測画面の方針が `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` に書かれている。
- [ ] `tools/report-next` / `tools/report-next-summary` の読み方が日本語で分かる。
- [ ] `bqn main.bqn` が rollback として残っている。

Stage 4a 完了は、production-ready を意味しません。
Stage 4b を始める準備ができた、という意味です。

---

## 16. Stage 4b exit criteria

Stage 4b が終わる条件:

- [ ] Stage 4a の条件が満たされている。
- [ ] 少なくとも 1 full cycle、`src_next` 側のレポートを実生活の確認に使った。
- [ ] `bqn main.bqn` は rollback として残っていた。
- [ ] cycle-end review を完了した。
- [ ] すべての divergence を分類した。
- [ ] real household decision に影響する unclassified divergence がない。
- [ ] `regression candidate` は調査済みで、resolved または reclassified されている。
- [ ] Stage 5 は、この文書だけでは許可されない。

Stage 4b 完了は、`src_next` が production-ready だという意味ではありません。
「1サイクル以上の daily-use trial が終わり、差分の分類ができた」という意味です。

---

## 17. report-section parity observation

Stage 4 の観察では、compact comparable fields だけでなく、report-section parity も見ます。

`tools/report-next` や `tools/report-next-summary` を見たときに、現在の本番 section が欠けている、分かりづらい、実際の家計 workflow を支えない場合は、divergence log に記録します。

full section-level parity matrix は `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` を参照します。

`bqn main.bqn` には存在するが `src_next` に equivalent がない section は、意図的な置き換えが文書化されていない限り、`missing src_next feature` として扱います。
