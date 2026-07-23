# アーキテクチャ (bqn-ledger)

Status: current architecture
Owner: architecture
Canonical: yes
Exit: revise when source or accounting boundaries change

## この文書の位置づけ

関連する文書:

- 長期ロードマップ: `docs/ENGINEERING_ROADMAP.md`
- 時間モデル: `docs/TIME_AS_AXIS.md`
- 記法・運用規約: `docs/CONVENTIONS.md`
- 保守手順: `docs/MAINTENANCE.md`

この文書は、**データがシステム内をどう流れるか**、各モジュールが何を担当するかを説明します。

## 目的 / やらないこと

### 目的

- **正データは人間可読source** に置く。Actualは明示設定されたnative JournalまたはTSV compatibility source、plan/budget/accountsはTSVとする。
- **読み込み時に厳しく検査** する。typo や壊れた行は早めに失敗させる。
- **会計計算は配列中心** にする。BQN の強みであるベクトル・行列演算を使う。
- 日常操作の入口は **`tools/bl`（Command Hub）** とし、非対話のレポート入口は **`tools/report`** として保つ。
- 記録 → 検査 → 集計 → 表示の流れを毎日使えるようにする。

### やらないこと

- core の中に「本格的な会計ソフト」や税制度判断を実装しない。
- Native Journal transactionをTSVの一対一行へ再flattenしない。

## モノリス化の防止（旧 bqn-kakeibo の教訓）

旧エンジンにおいて、`BuildAt` が 100 フィールドを超える巨大な Record を構築し、各表示セクションがそれに深く依存した結果、変更困難なモノリス状態となりました。この再発を防ぐため、以下の設計原則を維持します。

1. **グローバルRecordへの安易なフィールド追加の禁止**
   - `BuildContext -> ViewModel -> Format` の流れを徹底し、各セクション内で独立した `ViewModel` を作る。
2. **「出力結果の同一性」のために内部構造を汚さない**
   - その場しのぎのパッチではなく、疎結合を最優先に設計する。
3. **言語境界の厳守**
   - BQN editor / Bash / UI 側に会計・生活ロジックを実装しない。旧 Go editor 関連コード・文書は historical として扱う。

## 二大目的

### A. 生活を守る

- 次の収入日まで使い切らない（cycle）
- 封筒の残りを見る（budget/envelopes）
- 予定支出を見る（plan）
- 日々の安心を出す（毎日見られるサマリ）

### B. 確定申告の材料を残す

- 事業用/私用を分ける（`tax=business|private|mixed`）
- 必要経費候補を後で拾える粒度で残す
- 証憑と対応できる（`receipt=...`, `party=...`, `txn_id=...`）
- 年間集計を出せる

BQNは記録の背骨、専門ツールは申告の手先。背骨がまっすぐなら、手先はあとから選べます。

## システム共通の既定値

ファイルパスやデフォルトのベースディレクトリ名は `config/system_defaults.tsv` を正本として一元管理します。実運用データを公開 repo から外出しする場合は、`LEDGER_DATA_DIR` が `DEFAULT_BASE_DIR` より優先されます。

- BQN側: 呼び出し元 wrapper が base directory を渡す
- Bash側: `tools/lib/system-defaults.sh` 経由でロードし、`LEDGER_DATA_DIR` で上書き
- BQN editor側: wrapper (`tools/edit` / `tools/edit-bqn`) が解決した base directory を `src_edit/` に渡す
- Go側: historical code 用。現行 daily path の必須依存ではない

## 正データファイル

各ツールは base directory 配下のnative Journalとsource TSVを正データとして読む。公開 repo の `data/` は匿名 sandbox、実運用データは `LEDGER_DATA_DIR`（例: `/path/to/ledger-data/data`）で外出しする。実データの場所は移動可能であり、運用時は `tools/doctor` と `docs/DATA_DIR_SETUP.md` を入口に確認する。

- `<base>/accounts.tsv` — 勘定科目マスタ。1列目が科目名、2列目以降は `key=value` メタ。
- `<base>/<ACTUAL_JOURNAL_FILE>` — Actual layerの唯一の正本。native multi-postingを保持する。
- `<base>/plan.tsv` — 将来予定。Plan layer の正本。
- `<base>/budget_alloc.tsv` — 封筒予算配賦。Budget allocation の正本。
- `<base>/cycle.tsv` — サイクル期間設定。

### journal-like TSV の共通形式

先頭5列: `date memo from to amount`。6列目以降は `key=value` メタ。

## 中核概念

### 時間は軸である

```text
時間はラベルではなく、座標軸である。
```

- **座標時間**: Event を配置する時間座標（`date`）
- **観察時点**: レポートをどの時点から見るか（`as_of`）
- **外部時計**: OS から取得（`dt.Today`）。既定 `as_of` の供給元
- **期間ビュー**: cycle、月、週など、時間座標上の区間 view

`cycle` は Cube の基本軸ではなく、`[start, end_exclusive)` の区間 view。

### 動的勘定科目空間

勘定科目数は `accounts.tsv` から動的に決定される。`src_next/account_key.bqn` の `Resolve` が `count ← ≠accounts` を返し、cube や TBDS はこの値を使って配列を確保する。

旧エンジン時代の 256 スロット固定設計から移行済み。コード内にハードコードされた勘定科目上限は存在しない。

### Canonical Daily Cube

**`Day × Account × Layer`**

- `0: actual` — configで明示選択された単一Actual sourceから（Journal/TSVのmerge・fallbackなし）
- `1: plan` — `<base>/plan.tsv` から
- `2: budget` — `<base>/budget_alloc.tsv` と封筒消費から
- `3: forecast` — 予約レイヤ（現在ゼロ）

Cube は密な日付軸を使い、Ordinal 番号で $O(1)$ 参照可能。

### TBDS (Trial Balance Data Set)

`period × account × layer × opening/movement/closing`

Accounting-grade の試算表データセット。opening は期間開始前残高、movement は期間内変動、closing は opening + movement。

## Dataflow

```
<base>/accounts.tsv / selected actual source / <base>/plan.tsv / <base>/budget_alloc.tsv / <base>/cycle.tsv
   │
   └─ src_next/loader.bqn / actual_source.bqn (明示source読み込み)
        │
        └─ src_next/context.bqn (BuildContext)
             │
             ├─ src_next/cube.bqn ──── Canonical Daily Cube (Day × Account × Layer)
             ├─ src_next/tbds.bqn ──── Trial Balance Data Set (opening/movement/closing)
             │
             ├─ 各セクション Build(ctx) → ViewModel → Format / FormatHuman
             │
             └─ src_next/report.bqn ────── 人間向けレポート入口
                  src_next/summary.bqn ──── 機械向けコンパクト出力
```

## Presentation boundary

BQN は terminal styling を出力しない。BQN の責務は、source TSV の検査、意味解釈、計算、plain text report、machine-readable export、semantic status word までである。

BQN が出してよいもの:

- plain text report
- section key
- machine-readable summary
- `ok`, `warn`, `due`, `overdue`, `future`, `completed` などの意味語

BQN が出してはいけないもの:

- ANSI escape sequence
- terminal color code
- cursor control
- TTY 依存の表示制御
- fzf / gum など特定 UI ツール向けの装飾 markup

色、太字、枠、カード、preview、対話的な見せ方は presentation layer の責務である。現在の置き場は `tools/bl`、`tools/lib/color-filter`、`tools/main-ui.sh`、`tools/add-ui.sh` の表示補助とする。将来 viewer を追加する場合も、この境界を越えない。

Shell は UI・選択・wrapper・safe-write orchestration だけを担当する。actual Journal / `accounts.tsv` / `plan.tsv` / `budget_alloc.tsv` の会計意味や生活ルールは shell に持たせず、source route・候補・検査結果は BQN export / BQN editor protocol / config 由来のものを使う。

```text
BQN: meaning, calculation, plain output
UI: color, layout, interaction
```

この境界の詳細は `docs/archive/active-plans/DECISION_TERMINAL_COLOR_CONFIG.md` に置く。

### Layer model

```text
Source TSV
  → Posting IR
  → Ledger-wide validated postings
  → TBDS(period, as_of)
  → Accounting reports (Trial Balance, Balance Sheet, Income Statement)
  → Household policy layer
  → Household views
```

Accounting core は生活ルールを知らない。年金・月給・封筒派などの生活スタイルは policy layer で扱う。
