# Canonical Journal Surface 001

Status: current contract

`bqn-ledger` の native Journal 物理表記を安全に標準化（Canonical化）するための規範的設計・運用文書です。

## 概要

`Canonical Journal Surface 001` は、会計的・セマンティックな意味を一切変更することなく、native Journal の物理表記から以下の冗長性を取り除く安全な標準化機構を提供します。

1. **ポスティング行の空白統一**:
   - インデント: ASCII SPACE 4 文字 (`    `)
   - 勘定科目名と金額の間: ASCII SPACE 4 文字 (`    `)
2. **冗長トランザクションメタデータの自動除去**:
   - `; layer: actual` (デフォルトレイヤー)
   - `; currency: JPY` (デフォルト基本通貨)

Identity メタデータ (`event-id`, `plan-id`, `txn-id` 等) や非冗長メタデータ (`tax`, `biz` 等)、宣言ヘッダー (`commodity JPY`, `account ...`)、コメント、トランザクション順序・ポスティング順序は100%完全に保持されます。

---

## ３段階 CLI インターフェース

外装ツール `tools/edit` (`tools/edit-bqn`) 経由で以下の 3 つのサブコマンドを提供します。

### 1. `journal canonical-surface-plan` (Read-only Plan)

設定された Journal の現在の表面状態を分類・集計します。一切のファイル書き込みを行いません。

```bash
tools/edit journal canonical-surface-plan [--format text|tsv]
```

- `--format text` (既定): 人間向け視認レポート
- `--format tsv`: 機械可読メトリクス (集計数のみ。プライバシー保護のため記述・金額・勘定名は非露出)

### 2. `journal canonical-surface-preview` (Preview Candidate)

Canonical 変換候補 (`candidate`) を別ディレクトリ・別パスのファイルへ出力します。

```bash
tools/edit journal canonical-surface-preview --output /path/to/preview.journal
```

- 原本 Journal と同一パスへの出力は安全ゲートで拒否されます。
- 変換プロセス中に BQN 厳格セマンティック等価性検証 (ParseWithProfile, Stage 2A Posting IR) が自動実行され、1 ビットでも会計意味の不一致があればエラー終了しファイルを出力しません。

### 3. `journal canonical-surface-apply` (Safe Apply)

原本 Journal へ Canonical 候補を安全に適用します。

```bash
tools/edit journal canonical-surface-apply [--dry-run | --apply] [--yes] [--post-check LINT_MODE]
```

- `--dry-run` (既定): 変更予定件数を表示し、ファイルは書き換えません。
- `--apply --yes`: 厳格な安全プロトコル (`safe_rewrite_checked`) に従って書き換えを実行します。

---

## 安全機構と不変条件 (Invariants)

1. **BQN 厳格セマンティック等価性ゲート**:
   - `ParseWithProfile historical_external_plan` による構造検証
   - `Posting IR Stage 2A` (16 フィールド) による順序・金額・勘定科目・メタデータの1対1完全一致検証
2. **Atomic Safe Write & Guarded Rollback**:
   - 書き込み前に SHA-256 / size / mtime スナップショットを取得。書き込み中の競合他者編集を検知した場合は拒否。
   - 書き込み後、ポストチェック (`bqn src_edit/journal_validate_cmd.bqn` または `hledger check`) を実行。エラー検知時はバックアップから直ちに自動ロールバック。
3. **Idempotency (冪等性)**:
   - 既に Canonical な Journal に対して `canonical-surface-apply` を実行した場合は `CANONICAL_NOOP` となり、ファイル更新やバックアップ生成を行いません。
