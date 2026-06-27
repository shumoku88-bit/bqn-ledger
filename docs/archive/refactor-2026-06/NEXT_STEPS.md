# 次にやること（検討メモ）

このドキュメントは「検討メモ（履歴）」です。

- 長期の方針: `docs/ROADMAP.md`
- 直近のタスク管理: `TODO.md`
- ドキュメントの入口: `docs/README.md`

実装前に、仕様（定義）を文章で決めてから進める。

## 1. レポートが縦長すぎる問題

### 現状
`bqn main.bqn` が以下をすべてフル表示しており、情報量が多い。

追記（現在）:
- `main.bqn --toc` / `--section` / `--list-sections` により、必要なセクションだけ表示できるようになった

- 全体サマリ（Snapshot）
- 年初来サマリ（固定費/変動費＋明細）
- 勘定科目一覧（Balances）
- 今サイクル集計（明細）
- 封筒残高
- 未来の支払い予定

### 目標
- デフォルトは「意思決定に必要な最小」だけを表示
- 詳細は必要なときだけ出せる

### 方針案（どれを採用するか明日決める）

A) 設定TSVで表示ON/OFF
- 例: `report.tsv`（または `config.tsv`）
  - `show_balances=0/1`
  - `show_planned=0/1`
  - `show_ytd_detail=0/1`
  - `topN=10`

B) 引数で表示モード切替
- 例: `bqn main.bqn compact` / `bqn main.bqn full`

C) 入口は1コマンド維持しつつ、薄いラッパーも用意
- 例: `bqn main.bqn`（compact） + `bqn tools/report-full.bqn`（full）

※ `docs/REPORT_DESIGN.md` の方針（入口は main.bqn を維持、内部はモジュール化）に沿う。

---

## 2. 「財布の残り」(kakeigo) / 「1日に使える予算」(ledger-pure) の取り込み検討

### 2.1 財布の残り（残高の定義）
候補：

- `type=liquid` の合計（SMBC + PayPay）
- `assets:paypay` のみ（財布=決済口座）

設定化の案：

- `cycle.tsv` と同様に TSV で指定
- もしくは `accounts.tsv` のメタで「wallet=1」を付けた資産口座を合計

### 2.2 1日に使える予算（計算の定義）
まず「何を割り算するか」を決める必要がある。

- 分子（原資）候補
  - 変動費に使える残り（= 流動資産 - 固定費の残り見込み - ここから確保したい額）
  - 封筒の残り合計（予算運用を主とするならこちら）

- 分母（残り日数）候補
  - 今サイクルの残り日数（`cycle.tsv` の end_exclusive まで）
  - 月末まで（calendarMonth の場合）
  - 次の収入日まで（incomeAnchor の場合）

**明日決めること**
- まずは最小の定義で1本作る（例: "流動資産から固定費予定を引いた残り" / "次の収入日までの残り日数"）
- その後、定義を増やせるように設定化する

---

## 3. 対話入力（tools/add.bqn）の拡張方針（急がないが、拡張可能な作りにする）

### 現状
- `tools/add.bqn` は journal.tsv に追記するだけ
- account mapping は簡易（`assets:`/`expenses:` などのprefix補完）

### 目標
- 「入力を楽にする」拡張を、破壊的変更なしで追加できる構造にする

### 拡張アイデア（候補）

1) alias（短縮名）の導入
- `accounts.tsv` に `alias=smbc` のようなメタを追加し、補完に使う

2) 入力プリセット
- よくある支出（例: コンビニ, タバコ）をテンプレ化して選択式にする

3) バリデーション強化
- 追記前に「存在しない勘定科目」「金額が数値でない」を弾く
- 追記内容のプレビューとconfirm

4) journal.tsv 以外への追加
- `plan.tsv` への追加（将来予定の入力）を同じUIで扱う

### 構造案（明日以降の実装方針）
- `tools/add.bqn` の中のロジックを `tools/add_lib.bqn` に分離
  - `LoadAccounts`
  - `ResolveAccount`（alias/prefix）
  - `ValidateTx`
  - `WriteTx`（journal/plan どちらにも書ける）
- `tools/add.bqn` は UI/引数処理だけにする

---

## 明日のゴール（決めるだけ）

- レポートのデフォルト表示（compact）を何にするか
- "財布" と "1日予算" の計算定義を1つ決める
- addツールの拡張は「alias を accounts.tsv に入れるか」を決める
