# BQN Ledger

> A plain-text, BQN-powered household ledger and report engine.

BQN Ledger は、個人の生活会計を預けるための accounting-grade な ledger / report engine です。

正データは人間が直接読める TSV に置き、BQN はそこから派生ビュー、レポート、検査、エクスポートを作ります。日々の追記は小さな editor / UI から安全経路で行い、正データそのものは人間が読める地面として残します。

> A Technique for Opening from One Person to the World.
> See: [`docs/archive/completed-plans/OPENING_TECHNIQUE.md`](docs/archive/completed-plans/OPENING_TECHNIQUE.md)

## 必要なもの

- [CBQN](https://github.com/dzaima/CBQN)（推奨: commit `12a4fb9f` 以降。FFI + Singeli ビルド）
- [Go](https://go.dev/dl/) 1.22+
- fzf, gum（任意・対話 UI 用）

## What this is

BQN Ledger は、次のための個人用 accounting workbench です。

- base directory 配下の TSV を唯一の正本として保つ（公開 repo の `data/` は sandbox、実運用は `LEDGER_DATA_DIR` で外出し）
- journal / plan / budget / cycle から家計の現在地を読む
- BQN で派生ビュー、会計レポート、生活レポートを作る
- Go 製 editor と shell UI で日常入力を安全に補助する
- fixture / golden check / lint で「きれいな間違い」を出さないように守る

中心にある考え方は単純です。

```text
human-readable TSV
  -> BQN-derived accounting model
  -> report / check / export / UI
```

生活の数字は、アプリの中に隠すのではなく、検査できる形で置く。けれど、毎日の確認や入力は手作業だけにしない。その中間に置くための道具です。

## What this is not

BQN Ledger は、一般向けの完成された家計簿アプリではありません。

- 銀行同期サービスではありません
- 多ユーザー SaaS ではありません
- データベース中心の会計ソフトではありません
- すべての人に同じ予算ルールを勧めるアプリではありません
- 正データを見えない場所へ閉じ込めるツールではありません

これは、自分の生活会計を自分の目で読める正データとして保ち、そこから必要なレポートを派生させるための plain-text household ledger engine です。

## Design principles

- **TSV is the source of truth.** 正データは base directory 配下の TSV です。公開 repo の `data/` は匿名 sandbox、実運用データは `LEDGER_DATA_DIR`（例: `/path/to/ledger-data/data`）で指定します。
- **BQN derives views.** BQN は正データを書き換えず、読み取りと派生計算を担当します。
- **Daily writes go through safety paths.** 日常入力は `tools/add-ui.sh` または Go 製の `tools/edit` から行います。
- **Large corrections stay visible.** 削除や大きな修正は、人間が TSV を直接確認して行います。
- **AI must not touch source data by default.** AI は、明示指示がない限り base directory 配下の source TSV を直接編集しません。
- **Money is integer yen.** 金額は整数円で扱います。
- **The first five TSV columns are contract.** TSV の先頭5列を基本契約とし、拡張情報は6列目以降の `key=value` メタデータで表します。

## Source data

各ツールは base directory 配下の TSV を読みます。既定は `LEDGER_DATA_DIR`、未設定なら `config/system_defaults.tsv` の `DEFAULT_BASE_DIR`（公開 repo では `data/` sandbox）です。実運用データは repo 外の任意の場所に置き、`export LEDGER_DATA_DIR=/path/to/ledger-data/data` で指定します。場所は移動可能なので、移動後は `tools/doctor` で確認します。詳細は `docs/DATA_DIR_SETUP.md` を参照してください。

| ファイル | 役割 |
|---|---|
| `<base>/accounts.tsv` | 勘定科目とメタデータ。存在しない勘定を使うと検査で検出されます。 |
| `<base>/journal.tsv` | 実績取引。Actual layer の正本です。 |
| `<base>/plan.tsv` | 将来予定。Plan layer の正本です。 |
| `<base>/budget_alloc.tsv` | 封筒予算の配賦。Budget allocation の正本です。 |
| `<base>/cycle.tsv` | 生活サイクル境界。年金支給日などに基づく期間設定です。 |
| `<base>/config.tsv` | サイクル基準日、特殊な budget account 名などの設定です。 |

`budget:unassigned` のような一部の表示値は、レポート上で動的に計算されます。すべての表示値がそのまま TSV に保存されているわけではありません。

## Quick start

現在の本番入口は `tools/report` です。既定で `LEDGER_DATA_DIR`（未設定時は `data/` sandbox）を読み、`src_next/report.bqn` から人間向けレポートを出します。

```bash
# 全体レポート（LEDGER_DATA_DIR or data/ sandbox）
tools/report

# 実運用データを明示する例
LEDGER_DATA_DIR=/path/to/ledger-data/data tools/report

# fixture や別データセットを見る
tools/report fixtures/src-next-golden

# 日常レポート入口
tools/main-ui.sh

# セクション選択 UI
tools/main-ui.sh select

# 機械向けコンパクトサマリー
tools/report-next-summary

# 環境・正データ場所の診断
tools/doctor

# 全チェック
tools/check.sh
```

低レベルの診断や履歴的な確認が必要な場合だけ、`tools/report-next` や `bqn src_next/main.bqn <base-dir>` を直接使います。通常の日常確認では `tools/report` を使います。

## Daily input

### Interactive UI

```bash
# read-only preflight
tools/add-ui.sh --check

# interactive input
tools/add-ui.sh
```

`tools/add-ui.sh` は `<base>/accounts.tsv` を読み、支出、収入、資産移動、予算配賦の入力を補助します。fzf があれば fzf、なければ gum、さらにどちらもなければ番号入力にフォールバックします。`--check` は source TSV を書き換えず、data dir と候補一覧・Go editor 経路を事前確認します。

実際の追記は通常 Go 製の `tools/edit` に委譲されます。これにより、プレビュー、バックアップ、stale check、lint などの安全経路を通ります。

### Go editor

```bash
# 実績支出
tools/edit journal add \
  --date 2026-06-21 \
  --memo "スーパー" \
  --from assets:cash \
  --to expenses:食費 \
  --amount 1240

# 予算配賦
tools/edit budget add \
  --date 2026-06-21 \
  --memo "食費配賦" \
  --from budget:unassigned \
  --to budget:daily \
  --amount 10000
```

`tools/edit` も既定で `LEDGER_DATA_DIR`（未設定時は `data/` sandbox）を読み書きします。別データセットを扱う場合は `--base <dir>` を使います。

## Finishing planned entries

`<base>/plan.tsv` の予定には `plan_id=...` を付けられます。同じ `plan_id` を持つ実績が `<base>/journal.tsv` に入ると、その予定は完了済みとして扱われます。

```bash
# 未完了予定の一覧
tools/edit plan list

# 予定を実績化するプレビュー
tools/edit plan finish --index 4 --actual-date 2026-06-21

# 実際に追記する
tools/edit plan finish --index 4 --actual-date 2026-06-21 --apply
```

予定を消すのではなく、実績側に `plan_id` を残して閉じる設計です。未来の予定表と実績ログの両方を保ちます。

## Architecture

中心にあるのは Canonical Daily Cube です。

```text
Day × Account × Layer
```

主な layer は次の通りです。

| Layer | 内容 |
|---|---|
| actual | `<base>/journal.tsv` 由来の実績 |
| plan | `<base>/plan.tsv` 由来の予定 |
| budget | `<base>/budget_alloc.tsv` と実績から見た封筒状態 |
| forecast | 将来拡張用 |

買い物先、memo、カテゴリなどは Cube の軸にしません。必要に応じて別の派生ビューや検査で扱います。これは、正データを細かく保ちながら、集計の中心を安定させるためです。

大まかな流れは次の通りです。

```text
TSV source data
  -> loader / projection
  -> Posting IR
  -> Canonical Daily Cube
  -> TBDS / report view model
  -> terminal report / exporter
```

詳しくは [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) と [`docs/CANONICAL_DAILY_CUBE.md`](docs/CANONICAL_DAILY_CUBE.md) を参照します。

## Export

機械向けのコンパクト出力は `tools/report-next-summary` から使います。

```bash
# LEDGER_DATA_DIR or data/ sandbox を読む
tools/report-next-summary

# fixture や別データセットを見る
tools/report-next-summary fixtures/src-next-golden
tools/report-next-summary --base fixtures/src-next-golden
```

会計ソフトや別システム向けの出力は、正データを直接変形するのではなく、派生エクスポートとして作ります。新しい export 入口を追加する場合も、base directory 配下の source TSV を正本として保ち、`src_next/` と `tools/` の境界を壊さないようにします。

## Checks

```bash
tools/check.sh
```

主な確認内容は、BQN unit test、Go editor test、src_next golden fixture、セクション別 check、repo index、disabled feature guard です。

fixture を更新する場合は、対象が本当に仕様変更なのか、それともバグなのかを確認してから golden を更新します。

## Documentation map

最初に読む場所は `AGENTS.md` と `docs/README.md` です。AI 作業者も人間も、まずそこから現在の入口を確認します。

| ドキュメント | 役割 |
|---|---|
| `AGENTS.md` | 作業入口。AI が最初に読むべき導線と禁止事項。 |
| `docs/README.md` | docs 全体の目次。現行仕様・進行中計画・履歴メモを分ける入口。 |
| `docs/AI_CODEMAP.md` | `src_next/`, `editor/`, `tools/`, `checks/` の現行コード地図。 |
| `docs/QUALITY_BAR.md` | 一般向けプロダクトにはしないが、自分の生活会計を預ける production-grade personal tool として扱う品質基準。 |
| `docs/ARCHITECTURE.md` | 全体構造、正データ、Cube、モジュール境界。 |
| `docs/CANONICAL_DAILY_CUBE.md` | `Day × Account × Layer` の中心契約。 |
| `docs/SAFETY_PROFILE.md` | 予測可能性、fail closed、正データ保護、不変条件をまとめた小さな安全規格。 |
| `docs/archive/completed-plans/MAIN_SECTIONS.md` | historical: 旧エンジン `main.bqn` のセクション履歴。現行セクションは `src_next/report.bqn` を参照。 |
| `docs/archive/completed-plans/REPORT_FIELD_MAP.md` | historical: 旧エンジン `report_engine.Build` のフィールド履歴。 |
| `docs/JOURNAL_META.md` | journal-like TSV のメタデータ契約。 |
| `docs/GO_EDITOR_USAGE.md` | Go editor の使い方。 |
| `docs/archive/completed-plans/GENERALIZATION_TODO.md` | 設定駆動化・一般化の段階計画。 |
| `docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md` | 複数ポスティング方針。 |
| `docs/archive/completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md` | AI 作業効率化・開発体験改善の提案。 |
| `TODO.md` | 現在の作業メモ。 |

古い履歴や完了済みの議論は `docs/archive/` に退避します。通常作業では、必要になった時だけ参照します。

## AI working rules

AI がこのリポジトリを扱う場合は、必ず次を守ります。

- base directory 配下の `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv` は、明示指示なしに編集しません。
- TSV の先頭5列を壊しません。
- 空列を含む TSV を読む時は、列ずれを避けるため `SplitKeepEmpty` を使います。
- 設定値や生活ルールを BQN コードへ直書きせず、可能なものは `<base>/config.tsv`, `<base>/accounts.tsv`, `<base>/cycle.tsv`, `config/meta_schema.tsv` へ寄せます。
- Cube の shape と Layer 契約は利用者設定にしません。
- 変更後は可能なら `tools/check.sh` を実行します。

## Project boundary

このリポジトリは、正データを守りながら家計の現在地を読むための道具です。

完成された会計ソフトではなく、生活の観察、予定、実績、封筒、サイクル、派生ビューをつなぐための作業場です。TSV は人間の目で読める地面、BQN はその上を走る配列の水路、Go editor は安全に水門を開ける小さな道具です。
