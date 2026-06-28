# Seam Reduction Plan (Go/Bash/BQN 境界削減計画)


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
最終更新日: 2026-06-22  
ステータス: **Partially Implemented / Active Seam Reduction**

## 1. 目的

本リポジトリは BQN、Go、Bash の 3 言語が混在しています。言語数を減らすこと（完全な書き換え）を目的とするのではなく、**「システム内の各レイヤーが知っている『家計簿としてのドメイン知識（意味）』を整理し、接着面（境界）の摩擦を減らすこと」** を目的とします。

### 各レイヤーのあるべき責務境界

* **Bash**: 「UIと選択」に徹する薄い表示層。ドメインルール（会計的な意味）を一切知らず、BQN や設定ファイルが供給するデータに基づいて動く。
* **Go**: 「Operation IR（追記命令）を安全に TSV へアペンドする」トランザクション層。ファイルI/Oの排他制御、バックアップ、差分検知、基本的な構文（Syntax）チェックのみを担い、会計的な意味（Semantic）は知らなくてよい。
* **BQN**: 「ドメイン知識・計算・検証」を司る唯一 of 正本エンジン。

### Seam Reduction Invariants (境界削減の不変条件)

1. **言語数を減らすことを目的にしない。**
   目的は、家計簿としての意味を知っている場所を減らすこと。

2. **Bash は UI と選択だけを担当する。**
   Bash は accounts.tsv / meta_schema.tsv / journal.tsv の意味を解釈しない。
   候補一覧は BQN export または設定由来の一覧を読む。

3. **Go は Operation IR と安全な TSV append だけを担当する。**
   Go は syntax validation まではしてよい。
   Go は会計意味、封筒意味、生活ルール、レポート意味を持たない。

4. **BQN は source TSV の検査・意味解釈・計算・export の正本である。**
   新しい意味はまず BQN 側の契約か docs に置く。

5. **新しい概念を追加する時は、最初に「誰が知るべきか」を決める。**
   実装前に Bash / Go / BQN / config / docs の所有者を分類する。


---

## 2. ドメイン知識の棚卸しと再配置

システムが持つ主要なドメイン知識について、現在の状況と今後の整理方針を定義します。

| ドメイン知識 / 概念 | 現在の所有者と状況 | あるべき所有者（再配置先） | 境界削減の方針 |
| :--- | :--- | :--- | :--- |
| **ファイルパス・名称** | Go, Bash, BQN がそれぞれローダーを持ち、共通ファイル `system_defaults.tsv` をパース | **`config/system_defaults.tsv`** (正本) | すべての言語がこのファイルをロードしてパスを動的に組み立てる（完了）。 |
| **勘定科目接頭辞 (`assets:`, `budget:` 等)** | BQN (バリデーション/export), Bash (UIでの候補表示・フィルタリング) | **BQNのみが知るべき** | Bash は `accounts.tsv` を直接パースせず、BQN exporter (`export-ui-accounts.bqn`) を介して有効なアカウント一覧を取得する（実装済み）。 |
| **メタデータ定義 (`tax`, `plan_id` 等)** | BQN (型・計算)<br>Go (プラン完了判定、メタ除外のハードコード)<br>Bash (UIでの候補表示のハードコード) | **`config/meta_schema.tsv`** (定義正本) / BQN | メタデータのスキーマや許容値はすべて `meta_schema.tsv` に集約。BQNがこれをロードしてチェックし、GoやBashはキーの意味（何を指しているか）を知る必要がないようにする。 |
| **予定の完了ライフサイクル** | BQN (`plan_view.bqn` の非表示処理)<br>Go (`editor/plan.go` 内で `plan_id` ライフサイクルをハンドリング) | **Go (Operation)** & **BQN (レポート)** の共通契約 | ライフサイクル管理（`plan_id` メタが一致したら完了とするルール）は境界に跨るため、**docsに明確に仕様を置き**、GoとBQNがそれぞれこの共通ルールに沿って動作する。 |
| **勘定科目の役割 (`role=budget`, `role=income` 等)** | BQN (バリデーションや残高集計)<br>Bash (UIでの配賦モード等のフィルタリング) | **BQNのみが知るべき** | 勘定科目の「役割」はBQNだけが解釈する。UIは「ロールごとの勘定リスト」をBQNのexport結果等から取得するだけに留める。 |
| **日付の妥当性と生活ルール** | BQN (暦日チェック・年金と固定費の連動)<br>Go (追記時の日付構文チェック) | **BQN (生活ルール・暦日)** / **Go (構文)** | Goは `time.Parse("2006-01-02")` による単純な日付型チェックのみを行い、給料日・年金日連動などの生活上の会計ルールには関与しない。 |
| **会計ルール検証 (貸借一致等)** | BQN (`lint.bqn` / `invariants.bqn` で完全検証)<br>Go (`validateJournalLikeAddOptions` 等で簡易検証) | **BQNのみが知るべき** | GoはTSVの列数や基本的な型（金額が整数かなど）のみをチェック（Syntax Validation）。複雑な会計ルールはBQNに委譲し、Goは追記後にBQNポストチェックを実行する。 |

---

## 3. メタデータの3つの区分（野良メタと飼いメタの柵 🐾）

メタデータのカオス化を防ぎ、安全に拡張するために、メタデータを以下の3つの階層に区分して管理します。

1. **`unknown meta` (野良メタ)**
   - **定義**: `config/meta_schema.tsv` に登録されていない、未管理のメタデータ。
   - **挙動**: TSVへのアペンドおよびパース時にはそのままデータとして保持・保存されるが、会計計算やバリデーション（チェック）の対象外となる。
   - **例**: 一時的なメモ代わりの `shop=コンビニ` や、実験的な野良キー。

2. **`registered meta` (飼いメタ / 登録メタ)**
   - **定義**: `config/meta_schema.tsv` に登録され、データ型やルールが定義されているメタデータ。
   - **挙動**: `lint.bqn` などの静的検証の対象となり、export や report などで安全に参照・整形することが許可される。
   - **例**: `receipt`, `party`, `invoice` など。

3. **`semantic meta` (意味メタ / 家計簿メタ)**
   - **定義**: BQNの計算コアや特定のビュー（`plan_view`, `liquid_view` 等）が、ロジック上の「意味」を持って利用するメタデータ。
   - **挙動**: レポートの集計結果やライフサイクル管理（例: 予定の完了・ロールオーバー・固定キャッシュアウトの識別など）に直接関与する。
   - **例**: `plan_id`, `recur`, `due_on`, `anchor`, `offset` など。

---

## 4. 具体例：新メタデータ `store=...` (購入店舗名) の追加

「境界削減（Seam Reduction）」が実現できている場合、新メタデータ `store=...` を追加する際の責任範囲は以下のようになります。

### シナリオ①: 単に「取引追記時に店舗名を入力して保存したい」だけの場合

> [!NOTE]
> **BQN・Goともにプログラムコードの変更は不要**

* **UI (Bash) の変更**:
  - `tools/add-ui.sh` に「購入店舗を入力するプロンプト」を追加し、Goの実行コマンドに `--meta store=$store` を渡すようにする。
  - あるいは、UIが `config/meta_schema.tsv` を自動ロードして入力項目を生成する設計であれば、`meta_schema.tsv` に `store` を追記するだけでUIの変更すら不要になる。
* **Goのコード修正**: 不要（Goは任意の `--meta` 引数をそのまま末尾にアペンドする汎用設計であるため）。
* **BQNのコード修正**: 不要（BQNも6列目以降の未知のメタデータ列をパッシブに無視してパース・保持するため）。

### シナリオ②: 「`store=...` の値に基づいて、店舗別の購入レポートを出したい」場合

> [!NOTE]
> **Go・Bashのプログラムコードの変更は不要**

* **BQNのコード修正**:
  - `src/reports/report_engine.bqn` や新しい `view` で `store` メタデータを抽出・集計し、レポートセクションへ表示するロジックを追加する。
* **Goのコード修正**: 不要（Goはレポートの表示内容には関与しない）。
* **UI (Bash) の変更**: 不要（UIは単にデータを書き込むだけで、表示は `bqn main.bqn` の出力に依存するため）。

### シナリオ③: 「`store=...` の値（店舗名）が、空文字やタイポでないか検証（アサーション）したい」場合

> [!NOTE]
> **Go・Bashのプログラムコードの変更は不要**

* **BQNのコード修正**:
  - `config/meta_schema.tsv` に `store  string` などの定義を登録する。
  - `checks/lint.bqn` に、`store` が存在する場合のバリデーションルール（例: 許可された店舗リストとの一致など）を追加する。
* **Goのコード修正**: 不要（Goはアペンド後の post-check で BQN の `lint.bqn` を呼び出すため、自動的にこの検証の恩恵を受ける）。
* **UI (Bash) の変更**: 不要。

---

## 5. 今後の境界削減に向けたアクション（次のステップ）

### Done
- Bash から accounts.tsv 直接パースと prefix ハードコードを排除した。
- tools/add-ui.sh は export-ui-accounts.bqn に role を渡して候補を取得する。
- check.sh に export-ui-accounts の role 別 smoke test を追加した。
- config/meta_schema.tsv に scope 列を導入し、Go の planOnlyMeta をコメントパース依存から明示的なスキーマ契約（scope=plan）に寄せた。
- tools/add-ui.sh の choose_meta から tax/private/business などの意味的直書きを排除し、config/ui_meta_presets.tsv から動的にロードする仕組み（UI presetの分離）を実装した。
- Go の `plan list` に `--format tsv` を追加して machine-readable contract を整備し、tools/add-ui.sh の plan-finish 時の表示依存（`tail -n +2` や index パース）を排除した（ID優先指定、fallback として index 指定）。

- `plan_id` ライフサイクルを Go/BQN の境界共通契約として `docs/PLAN_ID_LIFECYCLE.md` に文書化した。

### Next
1. system_defaults.tsv を各言語が個別パースしているところを解消する。

### まだ密結合が残っている場所
次に見るべき優先順位：
1. system_defaults.tsv を各言語が個別パースしているところ
