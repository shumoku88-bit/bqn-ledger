# AI_TERMINAL_HANDOFF.md

ターミナル上の作業支援AIに読ませるための引き継ぎメモです。

2026-06-08 の監査結果から出た対応について、判断済みの仕様と作業順をまとめます。

> **履歴資料**: この文書の「次にやる順番」は2026-06-08時点のもので、対応済み項目を含みます。現在の作業方向は先に `TODO.md` と `docs/GENERALIZATION_TODO.md` を確認してください。判断済み仕様の背景資料として参照します。

## 守ること

- `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv` などの実データは勝手に変更しない。
- 変更は小さく、1目的ずつ行う。
- journal-like TSV を読む処理では、空フィールドを落とさない。原則 `lib.SplitKeepEmpty` を使う。
- 仕様や公開フィールドを変えたら、対応する docs も更新する。
- 変更後は可能なら `./tools/check.sh` を実行する。

## 判断済み仕様

### 予算配賦

`budget_alloc.tsv` を予算配賦の正データとする。

`plan.tsv` は未来予定のファイルであり、`budget:*` 行や `budget:* -> budget:*` の予算移動の本体にはしない。

`journal.tsv` も実績取引のファイルであり、`budget:*` 行は書かない。封筒消費は `accounts.tsv` の `budget=...` メタから派生させる。

### サイクル境界

内部計算ではサイクルを半開区間で扱う。

```text
start <= date < next_start
```

表示は次の形にする。

```text
start 〜 next_start の前日
```

例:

```text
内部: 2026-04-15 <= date < 2026-06-15
表示: 2026-04-15〜2026-06-14
```

この場合、2026-06-15 に入る収入は前サイクルには入らない。

土日祝などによる収入日のずれは自動推測せず、設定や予定データで明示する。

### 複数収入

生活運用サイクルは、当面は主サイクル1本を基準にする。

収入が複数になっても、すべての収入日を自動でサイクル開始日にしない。

追加収入や返金は、原則としてサイクル内の収入イベントとして扱う。

暦月、週、任意期間は、生活運用サイクルではなく観察用レポートとして後から追加する。

### 封筒予測

封筒の枯渇予測や健康診断は、安全側を保証するものではない。

これは相談用の警報であり、最終判断は封筒残高、次収入日、予定支出、実際の生活感覚を合わせて行う。

### ledger export

`tools/export-ledger.sh` は実績 `journal.tsv` の最小検算出口である。

予算レイヤ、予定レイヤ、全メタデータの完全保存を目的にしない。

## 判断不要で進めてよい作業

1. `docs/REPORT_FIELD_MAP.md` を現状の公開フィールドに合わせる。
2. `docs/AI_CODEMAP.md` の `cycle-consult` と `report_balances.bqn` の説明を現状に合わせる。
3. `README.md` の古い `BuildMatrix` 記述を削除または修正する。
4. `docs/ROADMAP.md` の `export-ledger.bqn` 表記を `export-ledger.sh` に直す。
5. `TODO.md` の stale 項目を整理する。

## 次にやる順番

1. docs 同期を先に行う。
2. 判断済み仕様を正式な docs に反映する。
3. cycle end exclusive の境界テストを追加する。
4. `main.bqn --section envelopes` を `tools/check.sh` に追加する。
5. 必要な実装修正は、テストで失敗した箇所から行う。

## ターミナルでの依頼文

```text
AGENTS.md と docs/AI_TERMINAL_HANDOFF.md を読んでください。
実データ TSV は変更しないでください。
まずは文書同期か境界テスト追加のどちらか1つだけを行ってください。
作業前に、変更予定ファイルを短く説明してください。
変更後は可能なら ./tools/check.sh を実行してください。
```

## 後回しでよいもの

- 複数サイクル設定ファイルの本格導入
- 複数収入すべてを自動サイクル開始にする機能
- empty journal bootstrap の完全対応
- ledger 互換 export の完全化
