# src_next 置き換え準備チェックリスト


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
状態: **日本語を正本とする移行ゲート / 本番動作の変更なし**

この文書は、AI が `src_next` で何を進めているのか、いつ本番へ近づけてよいのかを確認するための日本語の地図です。

重要な前提:

- 本番の信頼ルートは、今も **`bqn main.bqn`** です。
- `src_next` は正式な次世代候補ですが、まだ本番既定ではありません。
- `tools/report-next` は、明示的に選んだときだけ使う試験用コマンドです。
- `src_next` を普段使いにするには、現在の本番レポートで見ている情報を失わない必要があります。
- Snapshot は Stage 4a で優先して育てる検証画面です。設計は `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` を参照します。
- 英語だけの計画文書だと運用者が判断できないため、この文書では日本語でゲートを定義します。

---

## 1. 現在の状態

- `src_next` は正式な次世代パスです。
- ただし、**本番の既定ルートではありません**。
- 現在の本番は `bqn main.bqn` です。
- この文書は、`src_next` を本番へ近づける前に確認するゲートです。
- 以前の大きな blocker だった `incomeAnchor` cycle mode は、PR #20 で最小対応済みです。
  - `src_next/cycle.bqn` は journal / plan の収入日から `incomeAnchor` cycle を解決できます。
  - 公開 fixture の `incomeAnchor` golden check は `tools/check.sh` に含まれています。
- `incomeAnchor` 対応後、production data に対する current engine との比較を再実行済みです。
  - 比較可能だった `cycle_range`, `actual_expense_total`, `plan_expense_total` は一致しました。
  - private な金額は公開 docs には書いていません。

### いまの大事な判断

`src_next` は「横で比較できる段階」には来ています。
しかし、まだ「普段の家計判断を任せる段階」ではありません。

理由:

- compact summary は出ていますが、本番レポート 12 section の完全な代わりではありません。
- 予算・封筒・日割りなど、生活判断に使う section がまだ未実装または partial です。
- Snapshot は、`tools/report-next-summary` 上で最小検証画面を表示できる段階になりました。ただし、Daily / food / envelope / outlook / net worth は fallback/current-engine 明示であり、本番同等ではありません。ASCII art もまだ表示していません。
- そのため、現時点で「1サイクル以上、使いながら検証」は開始できません。

---

## 2. 置き換え前に必ず満たすこと

本番既定を切り替える前に、`src_next` は次の項目を **一致させる** か、**意図的な置き換えとして文書化** するか、**current engine fallback として明示** する必要があります。

- [ ] 現在サイクル集計
- [ ] 次回収入日までの残り
- [ ] 食費 / Daily の残額
- [ ] plan と actual の差分
- [ ] 未完了の予定支払い
- [ ] check / warning / unavailable section
- [ ] 封筒・家計方針の診断
- [ ] 日々の workflow で使う machine-readable export 相当
- [ ] 現在の本番レポート全 section（`docs/SRC_NEXT_REPORT_SECTION_PARITY.md` を参照）
- [ ] Snapshot 検証画面の方針（`docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` を参照）

「意図的な置き換え」とは、現在の値や section をやめる理由があり、新しい意味づけを comparison note や migration note に書いてある状態です。
説明のない差分や、なんとなく違う値は、意図的な置き換えではありません。

---

## 3. うっかり変えてはいけないもの

次のものは、明示的な設計・文書・テストなしに変更してはいけません。

- [ ] source TSV format
- [ ] 正データの意味
- [ ] 既存の本番コマンドの動作
- [ ] `daily` / `flex` / `reserve` などの家計方針ラベルを engine に直書きすること
- [ ] 日々の workflow でまだ必要な production exporter
- [ ] ASCII art を計算層に混ぜること

---

## 4. 置き換えまでの段階

`src_next` への移行は、次の段階で進めます。
段階を飛ばしてはいけません。
また、運用者が内容を理解できない状態で進めてはいけません。

### Stage 1: 横で動かすだけ

目的: `src_next` が production data で落ちないことを確認する。

- [x] `bqn src_next/main.bqn data` が production data で fatal error なしに動く。確認日: 2026-06-24
- [x] 本番は `bqn main.bqn` のまま。
- [x] 既存の `tools/check.sh` はすべて通る。確認日: 2026-06-24
- [x] 本番コマンド、wrapper、user-facing path は変えない。

### Stage 2: current engine と比較する

目的: 比較可能な値について、現在の本番 engine と `src_next` の差を分類する。

- [x] `checks/check-src-next-vs-current.sh` が production data で clean に走る。
- [x] 比較可能な field は一致済み。
- [x] 差分は §5 の分類に入れる。
- [x] 未分類の差分を残したまま次へ進まない。
- [x] comparison summary を `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` に記録する。

### Stage 3: 任意実行コマンドを用意する

目的: 本番を変えずに、明示的に `src_next` を試せるようにする。

- [x] entrypoint 方針を文書化済み。
  - `tools/report-next` を推奨。
  - 契約文書: `docs/SRC_NEXT_STAGE3_ENTRYPOINT_CONTRACT.md`
- [x] `tools/report-next` 実装済み。確認日: 2026-06-24
- [x] 本番 default は変えない。
- [x] `tools/report-next` を選ばない限り、本番 output は変わらない。

### Stage 4a: 普段使い検証の準備

目的: 「使いながら検証」できるレポート面をそろえる。

ここが重要です。

compact summary だけを横で見ることは、Stage 4a の準備作業です。
それは **validation run 本番ではありません**。

Stage 4a では、Snapshot を優先して「毎日最初に見る検証画面」として育てます。
Snapshot の設計は `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` を正本とします。

Stage 4b に進む前に、次を満たす必要があります。

- [ ] 現在の本番レポート 12 section について、各 section が次のいずれかになっている。
  - `src_next` で同等に出せる
  - 意図的に別の output へ置き換えると文書化している
  - current engine fallback として残すと文書化している
- [ ] household metadata readiness diagnostics が追加されている。
  - 2026-06-24: `src_next/household_metadata.bqn` を追加。expense account の budget=/budget_group=/spend_class= 欠損 count、observed value list、missing account key list を Readiness Check 近辺に表示する。envelope computation / food remaining / daily remaining は未実装のまま。
  - 2026-06-25: `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` を追加。envelope computation implementation 前に、stable metadata key と policy label、`allocated` / `actual_spent` / `remaining`、`safe_remaining` later work、`daily_amount` later work、unavailable / fallback 境界を固定した。production behavior は変えていない。Stage 4b validation run ではない。
  - 2026-06-25: fixture-scoped envelope computation implementation を追加。`src_next/envelope_computation.bqn` と `fixtures/src-next-envelope-computation` で `allocated` / `actual_spent` / `remaining = allocated - actual_spent` を検証する。production route は変えていない。validation run は開始していない。daily amount / safe_remaining は未実装。policy source は fixture-only で、production polished remaining はまだ出さない。
  - 2026-06-25: `checks/check-src-next-envelope-production-guard.sh` を追加。production data の `tools/report-next-summary data` では `src_next_envelope_status: unavailable/src_next` に留まり、polished remaining / safe_remaining / daily_amount / per-day allowance / food・daily advice を出さないことを check で固定した。
- [ ] plan/journal overlap diagnostics が追加されている。
  - 2026-06-24: `src_next/plan_journal_overlap.bqn` を追加。conservative な exact source-field matching による strong overlap count、unmatched plan count、ambiguous overlap count（optional）を compact `SrcNext Plan Journal Overlap` section に表示する。これは read-only diagnostics であり、plan.tsv / journal.tsv を変更しない。plan row mutation、journal row generation、envelope balances は未実装のまま。Stage 4a 検証面の準備作業であり、Stage 4b validation run は開始していない。
- [ ] Snapshot が、数値 + 状態ラベル + 検証コメント + 必要なら ASCII art の検証画面として読める。
  - 2026-06-24: 最小 Snapshot surface は実装済み。ただし fallback が残り、ASCII art は未表示なので Stage 4a 完了扱いにはしない。
- [ ] ASCII art は表示専用で、計算層に混ざっていない。
- [ ] `tools/report-next` または別の opt-in コマンドで、運用者が普段の判断に必要な情報を失わずに読める。
- [ ] 「足りないが後で作る」だけの section が、生活判断に必要な場所に残っていない。
- [ ] `bqn main.bqn` は rollback 用に残っている。
- [ ] 何が未実装で、何が partial で、何が置き換え済みかを日本語で読める。

### Stage 4b: 1サイクル以上の validation run

目的: `src_next` 側のレポートを、実際の日々の判断に使って確認する。

この段階で初めて、「1サイクル以上検証」と呼びます。

条件:

- [ ] Stage 4a の準備が終わっている。
- [ ] 運用者が普段の家計判断で `src_next` 側のレポートを読める。
- [ ] Snapshot が日々の入口として読める。
- [ ] ただし、`bqn main.bqn` は信頼できる rollback として残す。
- [ ] 別の明示的な Stage 4b start decision が作成されている。
- [ ] validation run log path が `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` で定義され、private-only / public-safe summary rule が確認されている。
- [ ] 少なくとも 1 full cycle、実生活で使って確認する。
- [ ] 家計判断に影響する divergence は、Stage 5 前に修正するか、意図的な差分として文書化する。

### Stage 5: 本番 default switch

目的: `main.bqn` の既定ルートを `src_next` に切り替える。

これはまだ開始しません。

- [ ] Stage 1〜4b の gate がすべて green。
- [ ] `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` が完了している。
  - すべての本番 section が matched / intentionally replaced / fallback のどれかになっている。
- [ ] `bqn main.bqn` が `src_next` path になる。
- [ ] 古い本番 path を rollback 用に残す。
- [ ] rollback path をテストし、文書化する。

---

## 5. 差分の分類

比較や validation run で差分を見つけたら、必ず次のどれかに分類します。

| 分類 | 使う場面 | 次の行動 |
|---|---|---|
| 意図的な置き換え | current engine の値や section をやめ、新しい意味へ置き換えると決めた場合 | 判断理由を記録する。追加修正は不要。 |
| `src_next` 未実装 feature | current engine が出す値を `src_next` がまだ出せない場合 | 現 stage の blocking gap として扱う。 |
| current engine 互換要件 | 両者の意味が意図的に違うが、互換上扱いを決める必要がある場合 | 契約を文書化する。 |
| regression candidate | 重要な値が説明なく違う場合 | どちらの engine も安易に変えず、調査する。 |
| unknown / 要調査 | 証拠が足りず判断できない場合 | 小さい fixture や exporter で調査する。 |

---

## 6. いまはやらないこと

この readiness phase では、次を始めてはいけません。

- `main.bqn` の default switch を今すぐ行わない。
- TSV format を変えない。
- 残りの report section を1つの PR / 1回の作業で全部作ろうとしない。
- food / daily / safe / allocated remaining を軽く実装しない。
- production exporter をまだ消さない。
- `daily` / `flex` / `reserve` を engine concept として hard-code しない。
- ASCII art を計算結果や check result に混ぜない。

---

## 7. AI 作業者への指示

AI がこの repo で作業するときは、次を守ること。

- 作業前に、この文書と `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` を読む。
- Snapshot を触る作業では、`docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` も読む。
- 英語だけの gate 追加で終わらせない。運用者が読む計画文書は日本語で書く。
- `src_next` を本番化したような表現をしない。
- compact summary を production parity と言わない。
- Stage 4a と Stage 4b を混同しない。
- 「1サイクル以上検証」は、Stage 4b の条件を満たしてから始まる。
- 生活判断に必要な情報が欠けるなら、validation run を開始済みと書かない。
- Snapshot の ASCII art は表示専用として扱い、計算層に混ぜない。
- 最小 Snapshot 実装では、status label は `unknown` / `reset` / `stable` / `caution` の保守的な範囲だけを使う。Daily/Food/envelope の残額がない段階で安全・厳しいと断定しない。
- `tools/check.sh` が通ったことと、運用者が理解できることは別問題として扱う。

---

## 8. 関連文書

- `docs/CURRENT_STATE_REFERENCE.md` — current engine baseline, fixtures, golden output, comparison commands
- `docs/SRC_NEXT_GOLDEN_CHECK.md` — `src_next` compact golden check surface と fixture coverage
- `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` — current engine との比較 notes
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` — configurable household report policy contract
- `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` — envelope computation / remaining / daily amount 境界 contract
- `docs/SRC_NEXT_INCOME_ANCHOR_CYCLE_CONTRACT.md` — incomeAnchor cycle mode contract
- `docs/SRC_NEXT_EXPENSE_ACCOUNT_MAPPING.md` — expense account classification と household category mapping
- `docs/SRC_NEXT_STAGE3_ENTRYPOINT_CONTRACT.md` — `tools/report-next` の entrypoint contract
- `docs/SRC_NEXT_STAGE4B_READINESS_GATE.md` — Stage 4b validation run readiness gate 定義
- `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` — Stage 4b validation run private log path と public-safe summary rule
- `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` — Stage 4a / 4b の検証ログ template
- `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` — 本番 12 section の parity matrix
- `docs/SRC_NEXT_SNAPSHOT_OBSERVATION_SCREEN.md` — Snapshot を検証画面へ育てる設計メモ
- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md) — 手動比較手順の正本（Gate B 充足の手順書）
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md) — production-equivalent Snapshot criteria 定義
- [SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md](SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md) — Stage 4a 検証面棚卸し
