# Go Editor Write Scope Inventory

> **Note (2026-06-26):** 旧エンジン (, , ) は削除されました。この文書内の旧エンジンへの参照は履歴として残ります。現行エンジンは  です。
本ドキュメントは、現行のGo製ソースエディタ（`tools/edit`）を中心に、将来的な source TSV editor safety engine が正本TSVファイル（`data/*.tsv` など）に対して行い得るすべてのファイル書き込み操作を網羅的に棚卸しし、分類・リスク・安全要件・承認境界を整理した「判断台帳」です。

> [!IMPORTANT]
> **本ドキュメントの位置づけ**
> 本ドキュメントは、書き込み操作の実装を承認するものではありません。どの方針を採用し、どの順番で実装を進めるべきかを人間（moko）と相談・判断するための意思決定用の台帳です。

---

## 1. ファイル別・操作別の棚卸しマトリクス

| 対象ファイル | 操作（コマンド案） | 分類 (Category) | 現在のステータス (Current Status) | リスク (Risk) | 明示的承認 (Explicit Approval) | 必要なテスト・安全要件 (Required Tests & Safety) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`journal.tsv`** | `journal list` | `read-only` | `candidate` | Low | 不要 | TSV read / line-number display / no mutation |
| | `journal add` | `append` | `implemented` | Medium | 不要（CLI確認あり） | dry-run, stale check, backup, validation, post-write BQN lint |
| | `journal edit --line <N>` | `existing-row edit` | `candidate` | High | **必要 (Yes)** | 変更前後差分（diff）の提示、特定行以外の非破壊保持、複数編集時の stale check |
| | `journal delete --line <N>`| `delete` | `forbidden` | Extreme | **必要 (Yes) / 原則禁止** | 削除対象行のプレビュー、影響を受ける口座/期間の警告。削除は手動直接編集の境界を尊重する。 |
| **`plan.tsv`** | `plan list` | `read-only` | `implemented` | Low | 不要 | - |
| | `plan add` | `append` | `implemented` | Low | 不要 | `plan_id` の自動採番ルール（重複時の `-02` 追記など）の検証、dry-run、stale check、backup、validation、post-write BQN lint |
| | `plan edit --line <N>` | `existing-row edit` | `implemented for open-plan date/amount only` | Medium | **moko approved 2026-06-23 for date/amount only** | `plan_id` の不変保証、変更前後差分の提示、stale check、backup、atomic write、post-check lint |
| | `plan delete --line <N>` | `delete` | `forbidden` | High | **必要 (Yes) / 原則禁止** | 予定は削除せず実績側の `plan_id` 重複で closed とするライフサイクル（案B）を維持するため原則禁止。 |
| **`budget_alloc.tsv`**| `budget list` | `read-only` | `candidate` | Low | 不要 | TSV read / line-number display / no mutation |
| | `budget add` | `append` | `implemented` | Medium | 不要（CLI確認あり）| dry-run, stale check, backup, validation, post-write BQN lint |
| | `budget edit --line <N>` | `existing-row edit` | `candidate` | High | **必要 (Yes)** | 変更前後差分の提示、予算割り当て整合性（ゼロサム）の preview / 警告 |
| | `budget delete --line <N>`| `delete` | `needs design` | High | **必要 (Yes)** | 封筒の残高推移が崩れることへの警告、手動直接編集の境界の検討 |
| **`accounts.tsv`** | `accounts list` | `read-only` | `candidate` | Low | 不要 | - |
| | `accounts add` | `append` | `candidate` | Medium | **必要 (Yes)** | 口座名プレフィックス検証（`assets:`, `expenses:` 等）、重複チェック、256口座上限警告 |
| | `accounts edit --account <A>`| `existing-row edit` | `candidate` | High | **必要 (Yes)** | `role=` メタデータ等のスキーマ検証（`meta_schema.tsv` との突合）、既存仕訳データとの不整合警告 |
| | `accounts delete --account <A>`| `delete` | `forbidden` | Extreme | **必要 (Yes) / 原則禁止** | 当該口座を使用した仕訳が `journal.tsv` 等に存在する場合のブロック、手動直接編集の境界を尊重 |
| **`cycle.tsv`** | `cycle show` | `read-only` | `candidate` | Low | 不要 | - |
| | `cycle set <key>=<value>` | `existing-row edit` | `candidate` | High | **必要 (Yes)** | サイクル基準日や給料日変更に伴う期間集計境界の影響プレビュー、メタデータと実データとの静的突合 |
| **`config.tsv`** | `config show` | `read-only` | `candidate` | Low | 不要 | - |
| | `config set <key>=<value>` | `existing-row edit` | `candidate` | High | **必要 (Yes)** | 設定変更によるデータ読み込みパスや動作モードへの影響プレビュー、未知キーの追加制限 |
| **`meta_schema.tsv`** | `meta show` | `read-only` | `candidate` | Low | 不要 | - |
| | `meta set <key> <rule>` | `existing-row edit` | `needs design` | High | **必要 (Yes)** | 新しいメタデータキーの追加に伴う `docs/JOURNAL_META.md` との同期検証、既存TSV列バリデーション |

---

## 2. 生活操作別バックログ（delete / dangerous rename 以外）

この節は、単なる「TSV行編集」ではなく、日常で起きる変更を source TSV editor safety engine の意味操作として扱うための候補一覧です。

方針:

- `delete` や危険な `rename` は原則として実装しない。
- ただし、削除に見える生活操作は `cancel`, `stop-after`, `skip`, `deactivate`, `correction` などの非破壊操作へ変換する。
- 可能な限り既存行の破壊的変更ではなく、追記・状態メタデータ・調整行として履歴を残す。
- 実装前に `--dry-run` / diff preview / stale check / backup / post-check BQN lint の必要範囲を決める。
- エディタは集計値を独自計算しない。影響プレビューが必要な場合は、BQN report/export を読む。

### 2.1 日々の実績操作

| 操作候補 | 意味 | 想定分類 | 備考 |
| :--- | :--- | :--- | :--- |
| `journal add` | 実績を追記する | `append` | 実装済み |
| `journal correction` | 間違いを修正行または逆仕訳的な追記で直す | `append` / `lifecycle` | 既存行削除より安全。修正理由メタを検討する |
| `journal attach-plan` | 実績に `plan_id` を後付けする | `existing-row edit` | 高リスク。対象行diffとplan重複チェック必須 |
| `journal detach-plan` | 誤った `plan_id` 紐付けを外す | `existing-row edit` | 高リスク。履歴として correction で表せるか要検討 |

### 2.2 支払い予定・定期予定操作

| 操作候補 | 意味 | 想定分類 | 備考 |
| :--- | :--- | :--- | :--- |
| `plan add` | 新しい予定を追加する | `append` | `tools/edit plan add` として実装済み。`series` 優先の `plan_id` 自動生成、重複時 `-02` 枝番 |
| `plan finish` | 予定を実績化する | `append` / `lifecycle` | `journal.tsv` に `plan_id` 付き実績を追記し、予定を closed 扱いにする |
| `plan reschedule` | 日付だけ違うことが分かった予定を移動する | `existing-row edit` / `lifecycle` | `tools/edit plan edit --date` として、open plan限定・diff preview付きで実装済み |
| `plan change-amount` | 金額だけ変更する | `existing-row edit` / `lifecycle` | `tools/edit plan edit --amount` として、open plan限定・diff preview付きで実装済み |
| `plan change-account` | 支払元・支払先を変更する | `existing-row edit` | account存在チェック必須 |
| `plan skip` | 今回だけスキップする | `lifecycle` | 削除ではなく `skip` メタやskip記録を検討 |
| `plan cancel` | サブスク解約など、今後発生しない予定にする | `lifecycle` | `status=cancelled` など。過去履歴は残す |
| `plan stop-after` | 指定日以降は発生しない定期予定にする | `lifecycle` | `until=YYYY-MM-DD` などを検討 |
| `plan pause` / `plan resume` | 定期予定を一時停止・再開する | `lifecycle` | サブスク一時停止など |

### 2.3 封筒・配賦操作

| 操作候補 | 意味 | 想定分類 | 備考 |
| :--- | :--- | :--- | :--- |
| `budget unallocated` | まだ封筒に配賦されていない予算を見る | `read-only` | BQN export を読む。Go側で独自計算しない |
| `budget allocate` | 未配賦予算を `daily` / `flex` / `reserve` などへ割り当てる | `append` | `budget_alloc.tsv` への追記候補 |
| `budget move` | 封筒間で割り当てを移動する | `append` / `lifecycle` | 既存行編集ではなく、移動調整行として表せるか検討 |
| `budget adjust` | 封筒配賦額を増減する | `append` | 理由メタ `reason=` を検討 |
| `budget release` | reserve から daily/flex へ出す | `append` / `lifecycle` | reserve運用ルールと接続 |
| `budget carryover` | 前サイクル残りを次サイクルへ持ち越す | `append` / `multi-file transaction` | cycle境界と連動するためpreview必須 |
| `budget preview` | 配賦変更後の封筒状態を見る | `read-only` | BQN export を読む |

### 2.4 科目・アカウント操作

| 操作候補 | 意味 | 想定分類 | 備考 |
| :--- | :--- | :--- | :--- |
| `accounts add` | 新しい科目・口座を追加する | `append` | 重複チェック、role/budgetメタ検証が必要 |
| `accounts set-role` | `role=` を設定・変更する | `existing-row edit` | 既存journalとの整合性警告が必要 |
| `accounts set-budget` | 封筒所属 `budget=` を設定・変更する | `existing-row edit` | 封筒レポートへの影響previewが必要 |
| `accounts set-display-name` | 表示名を設定・変更する | `existing-row edit` | レポート表示だけの変更なら比較的低リスク |
| `accounts deactivate` | 使わない科目を候補から外す | `existing-row edit` / `lifecycle` | 削除の代替。過去journalは壊さない |
| `accounts reactivate` | 非表示・停止した科目を再度使えるようにする | `existing-row edit` / `lifecycle` | `active=false` 等のメタ契約が必要 |
| `accounts show-usage` | どのTSVで使われているか確認する | `read-only` | delete禁止の補助情報として有用 |

### 2.5 サイクル操作

| 操作候補 | 意味 | 想定分類 | 備考 |
| :--- | :--- | :--- | :--- |
| `cycle show` | 現在のサイクル設定を見る | `read-only` | 候補 |
| `cycle preview-next` | 次サイクル境界をプレビューする | `read-only` | BQN側の期間集計と接続する |
| `cycle open-next` | 次サイクルを開く | `existing-row edit` / `lifecycle` | cycle.tsv の境界変更。影響preview必須 |
| `cycle close-current` | 現在サイクルを閉じる | `existing-row edit` / `lifecycle` | 次サイクル開始とセットで考える |
| `cycle change-next-start` | 次サイクル開始日だけ変更する | `existing-row edit` | 支給日変更・入力ミス修正など |
| `cycle preview-impact` | サイクル変更がレポート範囲に与える影響を見る | `read-only` | BQN report/export を読む |

### 2.6 設定操作

| 操作候補 | 意味 | 想定分類 | 備考 |
| :--- | :--- | :--- | :--- |
| `config show` | 設定を見る | `read-only` | 候補 |
| `config set-safe-key` | 許可済みの安全なキーだけ変更する | `existing-row edit` | unknown key は拒否する |
| `meta show` | meta schema を見る | `read-only` | 候補 |
| `meta add-key` | 新しいメタキーを追加する | `existing-row edit` / `needs design` | docs/JOURNAL_META.md 同期が必要。日常操作ではなく設計操作 |

---

## 3. 操作分類別の安全基準と基本ポリシー

### A. `read-only` (閲覧)
*   **ポリシー**: source TSV editor safety engine は計算エンジンではないため、集計値（口座残高や封筒残高）の再計算を行ってはならない。表示はTSVの生の値、またはBQNエンジンのエクスポートした一時ファイル（`out/*.tsv` など）を元にする。
*   **安全要件**: 読み込み時にTSVフォーマットを破壊せずにメモリ展開できること。

### B. `append` (安全追記)
*   **ポリシー**: ファイルの末尾に新しい仕訳や予定を追加する。最も制御しやすく、バグを局所化できる。
*   **安全要件**:
    1.  **Stale check (同時編集競合検知)**: 読み込み時と書き込み直前でファイルハッシュおよびタイムスタンプを比較し、変更があれば書き込み拒否。
    2.  **Validation**: 日付フォーマット、金額の整数チェック、口座名のプレフィックス妥当性。
    3.  **Atomic Write**: 同一ディレクトリ内のテンポラリファイルに書き出し、`fsync` を行った後に `rename` で置換。
    4.  **Backup**: 置換直前に `.backup/YYYYMMDD-HHMMSS/` へ元ファイルをコピー退避。
    5.  **Post-write lint**: 書き込み直後に自動で BQN のアカウント整合性チェック（`checks/lint_accounts.bqn`）を実行。

### C. `existing-row edit` (既存行の書き換え)
*   **ポリシー**: 過去の履歴を書き換えるため、残高や集計の履歴に直接影響を与える。
*   **安全要件**:
    *   編集箇所の「前後差分（Unified Diff形式など）」をCLI/UI上に明示し、人間への確認を必須とする。
    *   行番号のズレによる「異なる行の誤書き換え」を防ぐため、編集対象行の元の値（ハッシュまたは生テキスト）が一致しているかを書き込み時に再検証する。
    *   メタデータを書き換える場合は、`meta_schema.tsv` に定義されたスキーマに従っているかを事前にバリデーションする。

### D. `delete` (行・設定の削除)
*   **ポリシー**: 原則として **`forbidden` (禁止)** とする。データ欠損のリスクが極めて高いため、やむ得ない削除操作は人間がテキストエディタで直接 TSV を開いて編集する境界（手動修正）を尊重する。
*   **安全要件**:
    *   もし例外的に実装する場合は、対象行が他のファイル（`accounts.tsv` など）から参照されていないこと（例: 使用中アカウントの削除防止）を静的チェッカーで検証し、多重の確認（`y/N` ではなく、具体的な口座名や金額の再入力など）を要求する。

### E. `multi-file transaction` (複数ファイル同時更新)
*   **ポリシー**: 予定を実績化する際の「`plan.tsv` の更新 ＋ `journal.tsv` への追記」や「新規アカウント追加 ＋ 仕訳追記」など、複数のファイルにまたがるアトミック操作。
*   **安全要件**:
    1.  **Operation Log (操作記録)**: `.ops/<timestamp>-<id>.json` に操作前のハッシュ、中間パス、実行ステップを記録する。
    2.  **Failure Injection Tests (障害注入テスト)**: 1ファイル目を書き終え、2ファイル目を書く直前に意図的にプロセスを落とし、ロールバックまたは安全な再試行（Idempotency）ができるかを自動テストする。
    3.  **Idempotency (べき等性)**: 失敗したトランザクションを再実行した際、`journal.tsv` への重複追記（二重払い）が発生しないように `plan_id` などのユニークキーでガードする。

---

## 4. TUI / libvaxis 等のアプリ外装との境界契約

将来的に TUI や GUI（`libvaxis` や `tview` を想定）を導入する場合、source TSV editor safety engine（現行実装: Go `tools/edit`）と UI の境界を以下のように明確に引く必要があります。

```
+-------------------------------------------------+
| TUI / UI Layer                                  |
| - Bubble Tea / libvaxis / tview / Textual 等     |
| - Nushell / gum / fzf 等の構造化CLI補助          |
| - 画面描画、メニュー選択、スクロール             |
| - 入力値のプレビュー、確認ダイアログの表示      |
+-------------------------------------------------+
                        |
            呼び出し (subprocess or API)
                        v
+-------------------------------------------------+
| Source TSV Editor Safety Engine                 |
| (current implementation: Go tools/edit)         |
| - TSVの安全読み込み (行順、空列、コメント保持) |
| - バリデーション、stale check、アトミック書き込み|
| - 自動バックアップ、BQN lint 呼び出し            |
+-------------------------------------------------+
                        |
            TSVの読み書き (原子性保証)
                        v
                  [data/*.tsv]
```

### 契約境界ルール
1.  **計算・集計の非移譲**: TUI は独自に計算ロジック（残高計算など）を実装せず、すべて BQN エンジンの出力をそのまま読み込んで描画する。
2.  **ファイルI/Oのバイパス禁止**: TUI が直接 `data/*.tsv` に書き込んではならない。ファイル書き込みは必ず approved source TSV editor safety engine（現行実装: Go `tools/edit`）を経由する。
3.  **UI状態の分離**: TUIのカーソル位置、選択行、フィルターワードなどのUI状態を、正本データである `data/*.tsv` や `config.tsv` に絶対に混ぜてはならない。UI状態はメモリ上、または専用の一時キャッシュ（例: `tmp/`）で完結させる。
4.  **警告と確認プロンプトの連動**: safety engine 側で検出された警告（stale check失敗、アカウント未定義など）を、TUI 側はユーザーへ視覚的にポップアップやモーダルとして提示し、人間がそれを明示的に承認した上で `--yes` 相当のオプション付きで safety engine のコマンドを叩く。
5.  **CLI-first の外装交換性**: `tools/edit` の生活操作コマンドを先に安定した CLI 契約として育てる。TUI / shell / Nushell / gum / fzf はその CLI を呼ぶ外装であり、後から差し替え・併用できるようにする。

### 4.1 外装候補と役割

| 候補 | 主な役割 | 採用時の境界 |
| :--- | :--- | :--- |
| `Bubble Tea` | Go製TUI外装。menu / preview / confirm / list UI を作る候補 | Go editor の安全書き込み責務を奪わず、`tools/edit` のCLIを呼ぶ外装にする |
| `Nushell` | 構造化CLI補助。TSV/JSON的な一覧表示、絞り込み、候補生成の実験候補 | 正本TSVへ直接書かず、read-only補助または `tools/edit` 呼び出しに限定する |
| `gum` / `fzf` | 現行の軽い選択UI | 既存どおり入力補助・選択補助に留める |
| `libvaxis` / Zig TUI | 将来のTUI実験候補 | source TSV safety engine を置き換えるか、外装だけにするかを採用前に決める |
| `Textual` | Python製TUI/Web的外装の実験候補 | 正本TSVへ直接書かず、外装・prototypeに留める |

現行の推奨方向:

```text
1. まず `tools/edit` の生活操作CLIを育てる。
2. `--dry-run`, diff preview, BQN export による影響previewをCLI契約として固定する。
3. Bubble Tea / Nushell / gum / fzf / Zig TUI などを、同じCLI契約を呼ぶ外装として試す。
4. どの外装を使っても、canonical report calculation は BQN、正本書き込みは approved editor command に留める。
```

---

## 5. AI作業効率化（トークン最適化・構文防護）との接続

AIエージェントが本リポジトリで作業する際の、トークン消費の削減とTSV破壊リスクの低減を目的とした、source TSV editor safety engine との接続設計です。

### 1) Structured TSV Patch Applier (構造化パッチ適用)
AIがTSVの特定行を書き換える際、テキストレベルの文字列置換を行うと、タブのずれや改行コードの破壊を招きやすく、トークンも浪費します。これを防ぐため、source TSV editor safety engine はAI用の構造化パッチ適用インターフェースを提供します。
*   **動作仕様例**:
    ```bash
    tools/edit patch --file accounts.tsv --action update --key accounts:cash --meta role=assets --meta type=liquid
    ```
*   **効果**: AIは置換ブロックを作成することなく、このコマンドを1行呼ぶだけで安全な更新に近づき、構文崩れのリスクを大きく下げられます。

### 2) TSV Alignment Linter の自動トリガー
source TSV editor safety engine が `accounts.tsv` や `journal.tsv` に書き込みを行う際、アカウントの役割整合性チェッカー（`checks/lint_accounts.bqn`）を自動的に実行します。
*   **効果**: 不整合なアカウント名や無効な `role` 定義を含む変更が加えられた場合、書き込みの直前・直後にAIへピンポイントで「どの行のどのアカウント名が不整合か」をエラーとして返し、AIが巨大なファイルを読み直すことなく自己修正（デバッグターンの削減）を行えるようにします。

### 3) Golden Diff & Dry-run によるトークン削減
AIが操作の確認を行う際、ファイル全体を読み込む必要がないよう、source TSV editor safety engine は `--dry-run` 実行時に「適用される差分（Diff）」のみを標準出力に返します。
*   **効果**: AIのコンテキスト（トークン）に読み込まれるテキストを、ファイル全体から「変更があった数行の差分」のみに刈り込む（Context Unload）ことができます。
