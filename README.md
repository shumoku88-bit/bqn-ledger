# BQN Ledger

> A plain-text household event ledger and report engine.

BQN Ledger は、人間が直接読める TSV を正データとして保ち、BQN でレポート、検査、派生ビュー、エクスポートを作る household accounting workbench です。

このリポジトリを共有している理由は [`Why Share?`](docs/WHY_SHARE.md) に記しています。

## Start here

目的に近い入口から進めます。

- **Adopt with your own AI / 自分のAIと導入する**: [`docs/AI_ASSISTED_ADOPTION_GUIDE.md`](docs/AI_ASSISTED_ADOPTION_GUIDE.md)
- **まず試す**: [Quick start](#quick-start)
- **自分のデータを置く**: [`docs/DATA_DIR_SETUP.md`](docs/DATA_DIR_SETUP.md)
- **日常入力を使う**: [Daily input](#daily-input) / [`docs/BQN_EDITOR_USAGE.md`](docs/BQN_EDITOR_USAGE.md)
- **ChatGPTでレシート候補を確認して記帳する**: [`docs/MCP_RECEIPT_ENTRY.md`](docs/MCP_RECEIPT_ENTRY.md)
- **データと集計の考え方を知る**: [Core concepts](#core-concepts) / [Architecture](#architecture)
- **詳しい文書を探す**: [Documentation](#documentation)
- **開発や保守に参加する**: [`AGENTS.md`](AGENTS.md) / [`docs/README.md`](docs/README.md)

## Requirements

Quick Start で追加導入が必要な外部依存は [CBQN](https://github.com/dzaima/CBQN) だけです（推奨: commit `12a4fb9f` 以降。FFI + Singeli ビルド）。

`fzf` と `gum` は任意の対話 UI 用です。Quick Start のレポートには必要ありません。

## Quick start

`fixtures/demo/` には、架空の一般的な家計を 2026 年 1 月と 2 月の 2 サイクル分収録しています。実データは含みません。

CBQN を用意し、リポジトリのルートで次を実行します。

### 1. Start with a short snapshot

最初は、短い現在地だけを表示します。

```bash
tools/report fixtures/demo --section snapshot
```

### 2. See the available sections

```bash
tools/report fixtures/demo --list-sections
```

### 3. Compare cycles and read YTD

1 月と 2 月の支出傾向の違いと、年初来の集計を確認できます。

```bash
tools/report fixtures/demo --section actual-comparison
tools/report fixtures/demo --section ytd
```

### 4. Inspect the outlook at a fixed date

`outlook` は通常、実行時の現在日付を観測日として使います。過去の静的デモでは、固定観測日を指定します。

```bash
tools/report fixtures/demo --section outlook --outlook-as-of 2026-02-21
```

### 5. Print every section only when needed

全セクションは情報量が多いため、最初の確認には必要ありません。

```bash
tools/report fixtures/demo
```

実運用データはリポジトリ外へ置き、`LEDGER_DATA_DIR` で指定します。

```bash
LEDGER_DATA_DIR=/path/to/ledger-data/data tools/report
```

通常の日常操作は `tools/bl`、非対話のレポート確認は `tools/report` を使います。低レベルの診断が必要な場合だけ、`tools/report-next` や `bqn src_next/main.bqn <base-dir>` を直接使います。

### Optional conveniences

`fzf` と `gum` は、`tools/bl` や `tools/add-ui.sh` の対話的な選択と表示を補助します。TSV と BQN の中核や、上の Quick Start コマンドからは独立しています。

```bash
# 日常操作ハブ
tools/bl

# 環境とデータ場所を確認
tools/doctor

# 全チェック
tools/check.sh
```

## Core concepts

中心にある考え方は単純です。

```text
human-readable TSV
  -> BQN-derived accounting model
  -> report / check / export / UI
```

BQN Ledger は、次のための個人用 accounting workbench です。

- base directory 配下の TSV を唯一の正本として保つ
- journal / plan / budget / cycle から家計の現在地を読む
- BQN で派生ビュー、会計レポート、生活レポートを作る
- BQN 製 editor と shell UI で日常入力を安全に補助する
- fixture / golden check / lint で、もっともらしい誤りを防ぐ

一般向けの完成された家計簿アプリ、銀行同期サービス、多ユーザー SaaS、データベース中心の会計ソフトではありません。生活の数字を検査できる形で残しつつ、確認や入力のすべてを手作業にはしないための道具です。

### Design principles

- **TSV is the source of truth.** 正データは base directory 配下の TSV です。
- **BQN derives views.** BQN は正データを書き換えず、読み取りと派生計算を担当します。
- **Daily writes go through safety paths.** 日常入力は `tools/add-ui.sh`, `tools/edit`, または `tools/edit-bqn` から行います。
- **Large corrections stay visible.** 削除や大きな修正は、人間が TSV を直接確認して行います。
- **AI must not touch source data by default.** AI は、明示指示がない限り source TSV を直接編集しません。
- **Money is integer yen.** 現行の通常経路では金額を整数円で扱います。
- **The first five TSV columns are contract.** 拡張情報は6列目以降の `key=value` メタデータで表します。

## Source data

各ツールは base directory 配下の TSV を読みます。既定は `LEDGER_DATA_DIR`、未設定なら `config/system_defaults.tsv` の `DEFAULT_BASE_DIR` です。公開リポジトリでは `data/` sandbox が使われます。

| ファイル | 役割 |
|---|---|
| `<base>/accounts.tsv` | 勘定科目とメタデータ |
| `<base>/journal.tsv` | 実績取引。Actual layer の正本 |
| `<base>/plan.tsv` | 将来予定。Plan layer の正本 |
| `<base>/budget_alloc.tsv` | 封筒予算の配賦 |
| `<base>/cycle.tsv` | 生活サイクル境界 |
| `<base>/config.tsv` | ledger と UI の設定 |
| `<base>/issues.tsv` | 懸案事項・意思決定ログ |

詳細は [`docs/DATA_DIR_SETUP.md`](docs/DATA_DIR_SETUP.md) と [`docs/JOURNAL_META.md`](docs/JOURNAL_META.md) を参照してください。

## Daily input

### Interactive UI

```bash
# source TSV を書き換えない事前確認
tools/add-ui.sh --check

# 対話入力
tools/add-ui.sh
```

`tools/add-ui.sh` は勘定候補の選択を補助し、実際の追記を BQN 製 editor の安全経路へ委譲します。

### BQN editor

```bash
# 実績支出
tools/edit journal add \
  --date 2026-06-21 \
  --memo "スーパー" \
  --from assets:cash \
  --to expenses:食費 \
  --amount 1240

# 未完了予定の一覧
tools/edit plan list

# 予定を実績化するプレビュー
tools/edit plan finish --index 4 --actual-date 2026-06-21
```

入力経路、プレビュー、`--apply`、バックアップ、stale check の詳細は [`docs/BQN_EDITOR_USAGE.md`](docs/BQN_EDITOR_USAGE.md) を参照してください。

ChatGPTが画像を構造化し、MCPが候補をpreviewして人間承認後に一件だけ追記する実験的経路は [`docs/MCP_RECEIPT_ENTRY.md`](docs/MCP_RECEIPT_ENTRY.md) を参照してください。MCP自身は画像/OCRを扱いません。

## Architecture

集計の中心は Canonical Daily Cube です。

```text
Day × Account × Layer
```

主な layer は `actual`, `plan`, `budget`, `forecast` です。

```text
TSV source data
  -> loader / projection
  -> Posting IR
  -> Canonical Daily Cube
  -> TBDS / report view model
  -> terminal report / exporter
```

詳しくは [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) と [`docs/CANONICAL_DAILY_CUBE.md`](docs/CANONICAL_DAILY_CUBE.md) を参照してください。

## Export and checks

```bash
# 機械向けコンパクトサマリー
tools/report-next-summary

# fixture を指定
tools/report-next-summary fixtures/src-next-golden

# 全チェック
tools/check.sh
```

fixture / golden output を更新する場合は、仕様変更なのか不具合なのかを確認してから更新します。

## Documentation

README は入口、`docs/` は現行仕様と詳しい説明、`docs/archive/` は設計経緯と履歴です。

### Use the ledger

- [`docs/AI_ASSISTED_ADOPTION_GUIDE.md`](docs/AI_ASSISTED_ADOPTION_GUIDE.md): clone後に自分のAIで安全に導入するための英語ガイド
- [`docs/DATA_DIR_SETUP.md`](docs/DATA_DIR_SETUP.md): 実運用データの置き場所
- [`docs/BQN_EDITOR_USAGE.md`](docs/BQN_EDITOR_USAGE.md): editor の使い方
- [`docs/JOURNAL_META.md`](docs/JOURNAL_META.md): journal-like TSV のメタデータ契約
- [`SECURITY.md`](SECURITY.md): 脆弱性報告と秘密情報・実データの扱い

### Understand the design

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): 全体構造とモジュール境界
- [`docs/CANONICAL_DAILY_CUBE.md`](docs/CANONICAL_DAILY_CUBE.md): `Day × Account × Layer` の中心契約
- [`docs/SAFETY_PROFILE.md`](docs/SAFETY_PROFILE.md): 予測可能性、fail closed、正データ保護
- [`docs/QUALITY_BAR.md`](docs/QUALITY_BAR.md): 日常で使う道具としての品質基準
- [`docs/THIRD_PARTY_DEPENDENCIES.md`](docs/THIRD_PARTY_DEPENDENCIES.md): 外部依存と再現性

### Work on the repository

- [`AGENTS.md`](AGENTS.md): 作業入口と禁止事項
- [`docs/README.md`](docs/README.md): docs 全体の目次
- [`docs/AI_CODEMAP.md`](docs/AI_CODEMAP.md): 現行コード地図
- [`docs/DOCS_LIFECYCLE_CONTRACT.md`](docs/DOCS_LIFECYCLE_CONTRACT.md): 文書の追加・退役ルール
- [`TODO.md`](TODO.md): 現在の作業メモ

古い履歴や完了済みの議論は `docs/archive/` にあります。通常の利用では、必要になった時だけ参照します。

## Project boundary

このリポジトリは、正データを守りながら家計の現在地を読むための道具です。

完成された会計ソフトではなく、生活の観察、予定、実績、封筒、サイクル、派生ビューをつなぐための作業場です。TSV は人間の目で読める地面、BQN はその上を走る配列の水路、BQN editor は安全に水門を開ける小さな道具です。
