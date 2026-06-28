# レポート設計方針（main.bqn を育てる）

位置づけ:
- 長期の方針: `docs/ROADMAP.md`
- 計算/データフロー: `docs/ARCHITECTURE.md`
- 時間モデル: `docs/TIME_AS_AXIS.md`

この家計簿のレポートは、当面 **`bqn main.bqn` の1コマンド**を入口として育てます。

将来「スナップショットだけ見たい」「年初来だけ見たい」などでコマンドを分けたくなっても、
**内部ロジックを部品化しておけば分割は容易**、という方針です。

## 方針（重要）

- ユーザー向けの入口は原則 `main.bqn` のまま（1コマンド運用）
- ただし `main.bqn` は「計算・整形・表示」をベタ書きで増やし続けない
- 追加機能は **importできる部品（モジュール）**として切り出し、`main.bqn` はそれらを組み立てる

## 時間と観察時点の共通規則

- Eventやprojectionの`date` / `coordinate`は、出来事を配置する時間座標。
- `as_of`は、どの時点からviewを観察するかを表すレポート基準日。
- `system_today`はOS時計由来の実行日であり、`--as-of`未指定時の既定値だけを供給する。
- `generated_at`は出力生成日時であり、現在は未実装。
- `data_cutoff`は入力採用境界、`horizon_end`は将来観察範囲の候補で、`as_of`と同義にしない。
- `as_of`によってEventの日付を書き換えない。
- cycle、月、週は時間座標上の区間viewであり、Eventの固定属性ではない。
- 同じPlan Layerを使っても、outlook、daily-trend、envelopes、cycle-consultでは問いと合成規則が異なる。
- Planは具体的に意識した予定Event、Envelopeは発生日未確定でも確保する資金枠と残り枠。

現状ではCube残高snapshot、YTD、current cycle、residualなどは`as_of`境界を明示する。一方でrecentなどraw/file-order表示のsectionもある。表示や計算を変更する前に、sectionごとの`as_of`契約をfixtureで固定する。

これにより、後で

- `bqn snapshot.bqn`
- `bqn ytd.bqn`

のような“薄いラッパー”を作っても、計算本体は共有できます。

## 想定モジュール構成（目安・将来計画）

以下のリストは将来的な分割案を含んでいます。**現在の確定した構造については `docs/ARCHITECTURE.md` を参照してください。**

- `cycle.bqn` / `cycle.tsv` : サイクル期間の決定（設定で切替） **[実在]**
- `report_engine.bqn` : 共有計算エンジンのハブ **[実在]**
- `engine/report_balances.bqn` : 残高・資産集約 **[実在]**
- `engine/report_cycle_metrics.bqn` : サイクル内集計 **[実在]**
- `engine/report_outlook.bqn` : 見通し・予定抽出 **[実在]**
- `engine/report_trend.bqn` : 日割り推移計算 **[実在]**
- `engine/report_envelope_trend.bqn` : 封筒健康診断 **[実在]**
- `engine/report_snapshot.bqn` : 資産状況のみの薄いラッパー **[未実在/将来]**
- `engine/report_ytd.bqn` : 年初来サマリのみの薄いラッパー **[未実在/将来]**

## 設定は TSV を source of truth にする

- サイクル期間は `cycle.tsv` を編集して切り替える（コード変更なし）
  - 詳細: `docs/CYCLE.md`
- 固定費/変動費などの分類は `accounts.tsv` のメタ情報で運用できる形を優先する

## outlook について

見通し・日割りは `main.bqn` の outlook section に統一します。

```sh
bqn main.bqn --section outlook
```

現在の outlook は「予測」というより、`cycle.tsv` の現在サイクルに対する **日割り金額** と **流動資産・予算の全体像** です。

- 基準日は通常、起動時に1回取得した`system_today`を既定`as_of`として使う
- fixture/snapshot 等では `--as-of YYYY-MM-DD` で固定可能
- 残日数は当日を含む（`cycle_end_exclusive - as_of`）
- journal 最終記録日との差は警告ではなく文脈情報として表示する
- **予定（plan）の扱いと安全確保**:
  - rawな現金残高（`liq_total`）自体は変更しません。
  - **将来固定費の確保**: `as_of`（今日）以降の予定固定費は事前に確保（Reserve）し、引いたものを安全な流動資産残高（`safe_liq_total` / `seed_possible`）として扱います。
- **Dynamic Unassigned Budget (Asset-Based)**:
  - `budget:unassigned` は手入力の残高ではなく、「安全な流動資産残高（変動費原資）」から「現在各封筒にある残高の合計」を差し引いた値として動的に計算・表示されます。これにより、システム全体の予算整合性が一目で分かります。
  - レポート表示上、`budget:opening`（期首の原資投入口）の残高は隠蔽（0表示）されます。

## daily-trend について

`daily-trend` は、`cycle.tsv` の現在サイクル内で、生活用の日割り金額がどう推移したかを見るためのセクションです。

```sh
bqn main.bqn --section daily-trend
```

分類は `accounts.tsv` の `spend_class=...` と `fixed=1` を使います。
詳細は `docs/SPEND_CLASS.md` を参照してください。

- `fixed`: 未払い固定費として予約控除し、支払い済み額を `fixed` 列に出す
- `variable`: 日々の変動費を `variable` 列に出す
- `saving`: 貯金/投資口座の同日純増減を別列に出す（プラスは積立、マイナスは取り崩し）

`liquid` は `day_balances`、`variable` / `saving` / `fixed` は `day_updates` の Actual 列から計算します。

`Δdaily` は、前回の記録日から見て、1日あたりの日割り金額がどれだけ増減したかを表します。

**予定（plan）の扱い**: 未来の固定費予定（`spend_class=fixed` または `fixed=1`）のみを「確保分（Reserve）」として現金残高から事前に差し引いて計算します。変動費の予定は差し引きません。

## 封筒（envelopes）の健康診断について

**予定（plan）の扱い**: その封筒に関連付けられた（`budget=...` メタを持つ）未来 of 変動費予定のみを、封筒残高から事前に差し引いて「実質的な残高」として枯渇予測を計算します。

**封筒の分類と役割**:
封筒（`budget:*`）は `budget_group` に応じて以下のように意味と表示を分ける。
- `daily`/`flex`: 生活費として「使う生活封筒」。SAFE / WARN / SHORT のペース評価を行う。
- `reserve`: 貯金・投資などの「仮確保封筒」。使い切る対象ではなく、サイクル末または月末まで維持できた分を確定分として見る。ステータスは HELD (仮確保中), DONE (維持確定), DRAWN (取り崩しあり) を使用する。
また、レポート表示上の合計欄において、生活封筒の合計（`daily+flex`）と仮確保封筒の合計（`reserve`）を分けて集計し、混同を防ぐ。



## レポート削除候補 / 数日運用して判断

以下のレポート・exportは、現在の生活運用で本当に役に立つかを数日観察してから、削除・残置・改善を決めた候補です。

重要:

- 削除する場合も、正データ TSV (`journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv`) や canonical engine の意味を変えない。
- 残す場合は「何の判断に使うか」を明文化し、不要な相談ロジックを core へ混ぜない。

| 候補 | 現在の入口 | 現状評価 | 数日運用で見ること | 判断案 |
|---|---|---|---|---|
| cashflow mock | (削除済み) | (不要と判断されセクション削除完了) | - | - |
| AI次サイクル相談 | (削除済み) | (不要と判断されエクスポート削除完了) | - | - |
| residual | (削除済み) | Plan履行確認は `planned` セクションで概ね代替でき、実運用では `actual_only` 一覧に寄りやすかった。 | Actual同士の期間比較を新設する方が、生活上の増減を読みやすいか。 | sectionは削除。`actual-comparison` に置き換え。`residual_table` / residual export は互換用派生出力として当面残す。 |

### actual-comparison

2026-06-21時点の相談では、現行の Plan vs Actual residual よりも、集計できる範囲での **Actual同士の比較** が有力と判断し、`actual-comparison` section を新設した。

優先候補:

1. `current_cycle_elapsed` vs `previous_cycle_same_elapsed`
   - 今サイクル開始から `as_of` までの経過日数と、前サイクル開始から同じ日数分を比較する。
   - 年金サイクルなど `incomeAnchor` 運用と相性がよい。
   - 前サイクルanchorまたは比較日数分の履歴が足りない場合は、推測せず `unavailable` とする。
2. `ratio` / `%` 表示
   - `current`, `baseline`, `diff` に加えて増減率を出す。
   - `baseline=0` の扱い（`new` / `n/a` / `∞` など）は実装前に決める。

詳細計画は `docs/ACTUAL_COMPARISON_REPORT_PLAN.md` に移した。新方針では、収入・変動費・固定/定期支出・単発支出をlaneで分け、初期比較単位は account name 優先、envelope は variable spending の文脈として扱う。

実装前に固定する主な点:

- `current_end_exclusive = as_of + 1日` とする。
- 初期対象は `role=income` / `role=expense` に限定し、資産移動・負債元本返済・期首残高は除外する。
- oneoff / irregular は明示metadataなしに自動推測しない。
- `current_count` / `baseline_count` / `diff_count` も補助列として持つ。
- 履歴不足時は日割り推測で埋めず `insufficient_history` とする。

## check について

`check` は家計評価ではなく、**レポート表示に必要なデータ/メタ情報が揃っているか** を見るセクションです。

```sh
bqn main.bqn --section check
```

現在は以下を確認します。

- strict check が通っているか（壊れた行があればここに来る前に停止）
- `assets:*` に `type=liquid|savings|invest` が付いているか
- `expenses:*` に `spend_class=...` が付いているか
- `spend_class=variable` の費目に `budget=...` が付いているか

これは「使いすぎ」などの家計診断ではありません。
