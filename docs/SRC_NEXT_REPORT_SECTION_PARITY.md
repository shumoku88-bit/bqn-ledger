# src_next レポート section parity

状態: **日本語を正本とする parity gate / 本番動作の変更なし**

この文書は、`src_next` が現在の本番レポートをどこまで代替できているかを、section ごとに確認するための表です。

ここでの目的は、AI が「何を作っていて、何がまだ足りないのか」を運用者が読めるようにすることです。
英語だけの分類では、日々の家計判断に使えるかどうかを運用者が判断できないため、この文書では日本語で状態を書きます。

Stage 4b completion target:
**本番レポートの12 section すべてを `src_next` で再現する。**

---

## 1. 目的

現在の本番レポート（`bqn main.bqn`）には 12 section があります。
この 12 section は、実際の日々の家計 workflow で使われています。

`src_next` は compact summary から始めてもよいですが、本番切り替え時に情報量を黙って減らしてはいけません。

この文書では、次を定義します。

- Stage 5 default switch 前に必要な section-level parity
- 本番 12 section ごとの `src_next` 対応状況
- matched ではない section に必要な次の行動
- Stage 4a / Stage 4b の判断材料
- **Stage 4b で 12/12 を src_next 側で再現するための4段階実装計画**

---

## 2. この文書で使う分類

Stage 5 default switch 前に、すべての section は次のどれかになっている必要があります。

| 状態 | 意味 |
|---|---|
| **matched** | `src_next` が現在の本番 section と同等の情報を出す。field-level comparison で確認済み。 |
| **partial** | `src_next` が一部を出すが、まだ本番 section の完全な代わりではない。 |
| **intentionally replaced** | section を別の `src_next` output で置き換える。設計判断として文書化済み。 |
| **fallback to current engine** | default switch 後も、その section は current engine から出す。fallback が文書化・テスト済み。 |
| **missing src_next feature** | `src_next` がその section をまだ実装していない。blocking gap。 |

重要:

- compact summary parity は、本番置き換えには足りません。
- Stage 4b の「1サイクル以上、使いながら観察」を始めるには、生活判断に必要な section が欠けていてはいけません。
- つまり、すべての section が matched / intentionally replaced / fallback のどれかになるか、少なくとも daily-use trial で必要な情報を失わない状態にする必要があります。

---

## 3. 12-report parity target（全 section 対応表）

現在の本番 12 section と `src_next` の状態です。

| # | section name | 日々の役割 | 既存 src_next module | 現在の状態 | 必要な作業 | 実装段階 |
|---|---|---|---|---|---|---|
| 1 | 全体サマリ (Snapshot) | 資産全体・残高のざっくり確認。毎日最初に見る観測画面の入口。 | `src_next/snapshot.bqn` | partial | cycle-scoped fallback（net_worth/living系）を減らし matched に近づける。ASCII art は表示層だけで選ぶ。 | 第2段階 |
| 2 | 年初来サマリ (YTD Summary) | 年初来の収入・支出・net、固定/変動の傾向確認 | `src_next/ytd_summary.bqn` | matched | 完了（数値一致。account key suffix 表示差のみ） | 第1段階 |
| 3 | 勘定科目一覧 (Balances) | account ごとの残高確認 | `src_next/balances.bqn` | partial | 現状は cycle-scoped。負債グループ化は unsupported/src_next。 | 第1段階 |
| 4 | 今サイクル集計 (Cycle Summary) | 今サイクルの income/expense/net、支出 breakdown | `src_next/cycle_summary.bqn`, `src_next/expense_breakdown.bqn` | matched | 完了（金額降順ソート修正済み） | 第1段階 |
| 5 | 封筒・予算残高 (Envelopes & Balances) | envelope health、daily/flex/reserve、seedable amount | `src_next/envelope_computation.bqn` | partial | fixture-scoped 実装あり。production envelope guard 維持、seedable amount と本番Sec5突合が残り。 | 第3段階 |
| 6 | 未来の支払い等予定 (Planned Payments) | 支払い予定の見通し、予定の消化状態 | `src_next/planned_payments.bqn` | matched | 完了（plan_id マッチング修正済み。anchor日未対応は unsupported/src_next として残す） | 第2段階 |
| 7 | 直近の取引 (Recent Journal) | 最近の入力確認、取引 review | `src_next/recent_journal.bqn` | matched | 完了（newest first 修正済み） | 第1段階 |
| 8 | レポート準備チェック (Report Readiness Check) | data hygiene warning、plan/journal overlap、missing metadata | `src_next/readiness_check.bqn`, `src_next/household_metadata.bqn`, `src_next/plan_journal_overlap.bqn` | partial | hygiene warning 表示済み。検出方法差分と envelopes spent without alloc / redundant budget allocations が残り。 | 第2段階 |
| 9 | 見通し・日割り (Outlook / Daily Amount) | daily budget guidance、per-envelope remaining/day | `src_next/outlook.bqn` | matched | 完了（封筒予算日割りは envelope production guard により保留） | 第3段階 |
| 10 | 日割り推移 (Daily Trend) | daily trend history、spending velocity | `src_next/daily_trend.bqn` | matched | 完了（journal記録日 + as_of の in-memory observation） | 第3段階 |
| 11 | Actual比較観察 (Actual Comparison) | cycle-over-cycle actual comparison、異常値観察 | `src_next/actual_comparison.bqn` | matched | 完了（数値一致。行順序に merge-keys 由来の微差あり） | 第3段階 |
| 12 | デバッグ・由来 (Debug & Provenance) | invariant check、formula provenance、source row counts | `src_next/cube.bqn` | partial | invariant check の可読整形、formula provenance 表示、source row counts。 | 第2段階 |

---

## 4. 分類まとめ

| 分類 | 数 | section |
|---|---:|---|
| matched | 7 | 2, 4, 6, 7, 9, 10, 11 |
| partial | 5 | 1, 3, 5, 8, 12 |
| missing src_next feature | 0 | なし |
| intentionally replaced | 0 | なし |
| fallback to current engine | 0 | なし |

Stage 4 integration surface:

- `src_next/summary.bqn`: compact machine-readable observation output.
- `src_next/report.bqn`: human-readable 12 section report surface（observation-only）。
- `checks/check-src-next-report.sh`: section presence smoke test。
- `checks/check-src-next-stage4-fields.sh`: public fixture の comparable fields を current engine exporter と突合する field-level smoke test。

---

## 5. Stage 4b 実装計画（4段階）

Stage 4b completion target: **12/12 section を src_next で再現する。**

以下、4段階に分けて実装を進める。各段階は独立した observation + PR として実施する。

### 第1段階: すでに src_next に材料があるレポートから作る

対象: 2 (YTD Summary), 3 (Balances), 4 (Cycle Summary), 7 (Recent Journal)

この段階では、すでに `src_next` 側で数値計算が完了している section を、本番同等の人間向け整形表示で出力する。新しい計算ロジックは必要なく、表示層（`Format` 関数）の拡充のみ。

| section | 現在の出力 | 必要な表示整形 |
|---|---|---|
| 2 (YTD Summary) | compact YTD totals（income/expense/net） | 固定費/変動費 breakdown、spend_class 分類表示 |
| 3 (Balances) | nonzero actual account totals（machine format） | 人間向け整形（Amount カラム、負債グループ） |
| 4 (Cycle Summary) | compact cycle totals + expense breakdown（machine format） | 本番同等の見出し・整形。cycle mode 表示 |
| 7 (Recent Journal) | last 10 journal rows（machine format） | Date/From→To/Memo/Amount 整形 |

**完了条件**: 4 section が production 同等の整形表示を出せる。
**推定工数**: 小（表示層の拡充のみ。計算ロジック変更なし）

### 第2段階: current report と比較してズレが小さいものを埋める

対象: 1 (Snapshot), 6 (Planned Payments), 8 (Readiness Check), 12 (Debug & Provenance)

この段階では、すでに部分的な実装があるが表示整形や一部フィールドが不足している section を仕上げる。計算ロジックの追加は軽微。

| section | 現在の出力 | 必要な作業 |
|---|---|---|
| 1 (Snapshot) | observation surface（partial fields、fallback あり） | 資産分類（liquid/savings/invest）、net worth 算出、グループ化表示。fallback を減らし matched に近づける |
| 6 (Planned Payments) | source plan rows + conservative planned/paid/ambiguous | plan status 表示（future_open/due_open/overdue_open/completed）、本番同等の予定状態テーブル |
| 8 (Readiness Check) | valid/skipped counts、unknown count、plan/journal overlap（machine format） | 本番同等の hygiene warning 整形表示 |
| 12 (Debug) | cube numeric verification（machine format） | invariant check の可読整形、formula provenance、source row counts |

**完了条件**: 4 section が production 同等の表示を出せる。
**推定工数**: 中（一部計算ロジック追加 + 表示整形）

### 第3段階: 封筒・予算・残額系など、依存が多いものを作る

対象: 5 (Envelopes), 9 (Outlook/Daily Amount), 10 (Daily Trend), 11 (Actual Comparison)

この段階では、まだ `src_next` 側に計算ロジックが存在しないか、fixture-only prototype にとどまっている section に着手する。依存関係が多いため、順序に注意。

依存グラフ:
```
budget_alloc.tsv 読み込み → budget layer materialize
    ↓
envelope computation (Sec 5)
    ↓
outlook / daily amount (Sec 9)
daily trend (Sec 10) ← daily observation-point 保存が必要
actual comparison (Sec 11) ← 前サイクルデータの参照が必要
```

| section | 依存 | 必要な作業 |
|---|---|---|
| 5 (Envelopes) | budget layer materialize、household policy config | budget layer の cube materialize、envelope balance 計算、seedable amount、health label。production envelope guard は別契約で解除 |
| 9 (Outlook/Daily Amount) | Sec 5、remaining days | per-envelope daily amount、liquid assets daily、残日数計算 |
| 10 (Daily Trend) | daily observation points | 日次スナップショット保存、Δdaily 計算、下落日 Top10 |
| 11 (Actual Comparison) | historical cycle data | 前サイクル同経過日数との比較 |

**完了条件**: 4 section が production 同等の計算・表示を出せる。
**推定工数**: 大（新規計算ロジック + 設計判断 + 契約更新）

### 第4段階: 12個すべてを src_next report として出す

対象: 全 section の最終確認

第1〜3段階で実装した12 section を `src_next/summary.bqn` または `src_next/main.bqn` から一括出力できる状態にする。

| 作業項目 | 内容 |
|---|---|
| 全 section の統合出力 | `src_next/summary.bqn` または新規 `src_next/report.bqn` から全12 section を順に出力 |
| field-level comparison | 全 section で current engine 出力と比較し、差分を分類 |
| private trial log への記録 | `private/src-next-stage4b/daily-use-trial-log.md` に観測結果を記録 |
| Stage 4b exit criteria 確認 | `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` §6 を満たすか確認 |

**完了条件**: `bqn src_next/report.bqn data` が12 section すべてを出力し、current engine 出力と比較可能な状態。
**推定工数**: 小（統合 + 確認。実装の大部分は第1〜3段階で完了）

---

## 6. Stage 4a / Stage 4b との関係

### Stage 4a: 普段使い観察の準備

この parity matrix を埋めていく段階です。

compact summary や partial section を追加して、current engine と比較できる面を増やします。
ただし、この段階ではまだ「使いながら1サイクル観察」とは呼びません。

Snapshot は Stage 4a で優先して育てる画面です。
最小実装は入っていますが、まだ partial improved であり、matched ではありません。
設計の正本は `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` です。

### Stage 4b: 1サイクル以上の daily-use trial

運用者が `src_next` 側のレポートを普段の家計判断に使える状態になってから始めます。
この段階で、上記4段階の実装計画を順次実行します。

開始条件の目安:

- matched / intentionally replaced / fallback が十分にそろっている。
- missing src_next feature が、生活判断に必要な section に残っていない。
- partial section があっても、日常判断を壊さない理由が文書化されている。
- `bqn main.bqn` は rollback として残る。

---

## 7. いまはやらないこと

- すべての missing section を1回の作業で実装しようとしない。
- compact summary parity だけで production replacement 可能と言わない。
- `main.bqn` や production engine behavior を変えない。
- TSV format や production data をこの文書のために変えない。
- `src_next` を production-ready と書かない。
- Stage 5 default switch を始めない。
- 英語だけで重要な計画を追加しない。
- ASCII art を計算層に混ぜない。
- production envelope guard を緩和しない（Stage 4b 中は `unavailable/src_next` を維持する）。

---

## 8. 関連文書

- `docs/MAIN_SECTIONS.md` — 現在の本番 section map と IO / side effects
- `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` — Stage 4b daily-use trial readiness gate 定義
- `docs/SRC_NEXT_STAGE4B_TRIAL_SCOPE.md` — Stage 4b daily-use trial scope
- `docs/SRC_NEXT_REPLACEMENT_READINESS.md` — Stage 1〜5 の gate checklist
- `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` — Stage 4a / 4b の観察ログ template
- `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` — Snapshot を観測画面へ育てる設計メモ
- `docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md` — production-equivalent Snapshot criteria 定義
- `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` — Stage 2 field-level comparison notes
- `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` — envelope computation / remaining / unavailable 境界 contract
- `docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md` — current engine と src_next の手動比較手順
- `docs/SRC_NEXT_COMPARISON_RECORD_TEMPLATE.md` — Private/manual comparison record template
- `docs/ARCHITECTURE_NEXT.md` — architecture next design notes
