# Conventions (bqn-ledger 規約)

位置づけ:
- 長期の方針: `docs/ENGINEERING_ROADMAP.md`
- メタ列の詳細: `docs/JOURNAL_META.md`

この文書は、データ、レポート、および統合処理の一貫性を保ち、人間とAIの双方にとって保守・拡張を容易にするためのプロジェクト規約を定義します。

## 勘定科目の命名規則 (Account naming)

以下のプレフィックス（名前空間）を使用します：

- `assets:*`   : 資産（銀行口座、現金など）
- `liabilities:*`: 負債（クレジットカード、借入金など）
  - システム内では貸方（クレジット）として表現されます。
  - スナップショット（残高）表示では、純資産（Net Worth）の計算のために資産とは分けて表示されます。
  - 負債口座から費用口座への取引は、予算（封筒）を即座に消費します。
- `income:*`   : 収入源
- `expenses:*` : 費用カテゴリ
- `equity:*`   : 開始残高 / 純資産勘定
- `budget:*`   : 封筒 / 予算レイヤの勘定科目（既定プレフィックス。実際値は `config.tsv` で設定）

### 推奨ルール

- 勘定科目名は空であってはなりません。
- 勘定科目名は一意でなければなりません（重複している場合、現行 `src_next` readiness/lint checks で検出対象になります）。
- 勘定科目数にハードコードされた上限はありません（`accounts.tsv` から動的に決定されます）。重複は `checks/check-src-next-lint.sh` などの検査で検出対象になります。
- プレフィックスおよびキーにはASCII文字を推奨します。プレフィックスの後ろは日本語でも問題ありません。
  - 例: `expenses:食費`

### 将来の検討事項 (負債)

- **予算の初期配賦 (Budget Seeding)**: 現在、`seedable_budget` は `可用資金 (type=liquid) - 固定予備費` として計算されます。これは負債を差し引いていません。クレジットカードの利用頻度が高い場合は、初期配賦の制限を `純資産 (Net Worth)` ベースにするべきかを検討してください。
- **サイクル相談 (Cycle Consultation)**: 将来のクレジットカード支払い（債務返済）を `plan.tsv` で追跡し、引き落とし時点での流動性を確保できるようにします。

## TSV スキーマ (TSV schemas)

### `accounts.tsv`

- 1列目: 勘定科目名
- 2列目以降: 任意のメタデータトークン（`key=value` 形式、タブ区切り）

### ジャーナル形式ファイル (`journal.tsv`, `plan.tsv`, `budget_alloc.tsv`)

- 必須列（1〜5列目）:
  1) 日付 (`YYYY-MM-DD`)
  2) 摘要（メモ）
  3) 送金元 (from)
  4) 送金先 (to)
  5) 金額 (amount)
- 任意列（6列目以降）: メタデータトークン（`key=value` 形式）、1列につき1トークン

注意点：

- `#` で始まる行はコメント行として扱われ、ローダーや lint によって無視されます。これは `plan.tsv` のセクションを視覚的にグループ化するのに使用できます。
- 会計計算では先頭の5列のみを使用します。
- バリデーションでは **「少なくとも5列存在すること」** および既知の勘定科目が使用されていることを強制します。
- 現行 `src_next` の projection/readiness/lint checks は `date` / `from` / `to` / `amount` の不正を skipped / invalid / warning / error として可視化します。
  - `date` は `YYYY-MM-DD` 形式かつカレンダー上有効な日付である必要があります。
  - `amount` は整数の文字列でなければなりません。
- `memo`（摘要）は空でも構いません。
- ジャーナル形式の TSV パース処理は空のフィールドを維持するため、摘要列が空であっても `from` / `to` / `amount` が左にずれることはありません。
- `journal.tsv` は実績（Actual）レコードのみを記録します。`system_today` より未来の日付の行は入力エラーとして拒否されます。将来の予定は `plan.tsv` に記述してください。
- 観察境界 (`as_of`) の扱いは section ごとに異なるため、変更時は `docs/TIME_AS_AXIS.md` と該当 `src_next` module / check を確認します。未来日の actual journal row を許すかどうかは、便利な補正ではなく fail-visible な診断として扱います。
- `budget:*` 口座は `budget_alloc.tsv` 内でのみ許可されます。`journal.tsv` および `plan.tsv` には予算口座の行を含めてはなりません。費用の封筒消費を投影するには、`accounts.tsv` の `budget=...` メタデータを使用します。

### 予算勘定の設定

予算レイヤのPrefixと特殊勘定名は `config.tsv` の次の必須キーで定義します。

- `BUDGET_PREFIX`
- `BUDGET_ID_OPENING`
- `BUDGET_ID_UNASSIGNED`
- `BUDGET_ID_SPENT`

コードではこれらの名前を直接書かず、`src_next/config.bqn` のアクセサが返す設定値を使います。本文中の `budget:*` は既定設定を使った概念表記です。

## メタデータ規約 (Metadata conventions)

### フォーマット

- 1列 = 1トークン
- トークンのフォーマット: `key=value`
- キー表記の揺れ（`Tax` や `TAX` など）を防ぐため、`key` は**小文字**にします。

### 共通キー（現在定義されているもの）

これらは規約です（すべてがすでにエンジンによって解釈されるわけではありません）：

- `type=liquid|savings|invest` (`accounts.tsv`): 資産カテゴリ
- `budget=<name>` (`accounts.tsv`): 費用 → 封筒マッピング (`budget:<name>`)
  - `budget:<name>` は `accounts.tsv` に存在する必要があります。対象の封筒が存在しない場合、現行 lint/readiness checks で検出対象になります。
  - `budget=<name>` メタデータを使用する場合、予算消費のシンク（吸い込み先）として `budget:spent` も存在する必要があります。
  - 上記の `budget:` や `budget:spent` は既定値です。実際の名前は `config.tsv` の予算設定に従います。
- `fixed=1` (`accounts.tsv`): 固定費フラグ（YTD内訳の集計で使用）
- `spend_class=fixed|variable` (`accounts.tsv`): 日次トレンド / 支出分析クラス
  - 詳細: `docs/archive/completed-plans/SPEND_CLASS.md`
  - `expenses:予備` はこの家計簿では `variable`（変動費）として扱われます。
- `tax=private|business`（ジャーナル形式）: 個人用 vs 事業用（ドラフト）
- `biz=0|1`（ジャーナル形式）: 事業按分フラグ（ドラフト）
- `recur=once|monthly|cycle` (`plan.tsv`): 予定行の繰り返しマーカー。省略時は単発または未指定として扱われます。
- `months=all|even|odd` (`plan.tsv`): 毎月の予定行に対する対象月フィルター。省略時は `all`（全月）として扱われます。
- `anchor=<account>` (`plan.tsv`): サイクルベースの予定行に対するアンカー勘定科目。例: `anchor=income:年金`
- `offset=<days>` (`plan.tsv`): サイクルベースの予定行に対するアンカーイベントからのオフセット日数。例: `offset=0` / `offset=1`
- `series=<id>` (`plan.tsv`): 同一の繰り返し支払い/収入シリーズに対する不変の ID または名前。
- `cashflow=fixed_obligation` (`plan.tsv`): 生活資金から留保すべき、費用ではない固定キャッシュアウト。例: 借入金元本の返済（`assets:* -> liabilities:*`）。

### 実験的な複数時間キー

Phase 6の `fixtures/multi-time-card` で検証中のキー。まだ本番のクレジットカード規則として組み込まれてはいません。

- `due_day=<1..31>` (負債口座): デフォルトの支払日
- `due_month_offset=<months>` (負債口座): 購入日からの月オフセット
- `payment_account=<assets:...>` (負債口座): キャッシュアウトが発生する予定の決済口座
- `due_on=YYYY-MM-DD` (ジャーナルイベント): 口座定義から導出される支払予定日をオーバーライドする明示的な例外

通常の購入行は先頭5列のままとし、`due_on` は自動導出で表現できない例外的な行にのみ使用します。

## BQN 実装上のはまりどころ (BQN pitfalls)

`src_next` で頻出する BQN の罠。pit が新規コードを書くときの参考に。

### 1. 大文字始まりの名前は関数役割に推論される

BQN は識別子の先頭文字で役割 (role) を推論する：

- `Uppercase` / `_underscore` → 関数役割
- `lowercase` → サブジェクト役割

```bqn
# ❌ エラー: NoPolicy は関数役割と推論され、文字列を代入できない
NoPolicy ⇐ "unavailable/no_policy"

# ✅ 一度ローカル変数（小文字）で受けてから渡す
noPolicy ← "unavailable/no_policy"
{ NoPolicy ⇐ noPolicy }
```

`⇐` で文字列や数値を直接エクスポートする場合は、必ず小文字名を経由する。

### 2. `? ... ;` の false 節で外側変数が見えない

```bqn
# ❌ エラー: status が undefined
FmtAmount ← {𝕊 status‿amount:
  (cond) ? (•Fmt amount) ; status
}

# ✅ ⊑ (pick) を使う
FmtAmount ← {𝕊 status‿amount:
  (cond) ⊑ (•Fmt amount)‿status
}
```

`? ... ;` の false 節はスコープが分離されることがある。値の選択には `⊑` を使う方が安全。

### 3. `⍟` (repeat) は関数を期待する

```bqn
# ❌ エラー: 文字列を ⍟ に渡せない
out ↩ "unavailable/no_cycle" ⍟(cond) @

# ✅ ブロックで包む
{𝕊: out ↩ "unavailable/no_cycle"}⍟(cond) @

# ✅ または ⊑ で条件選択
out ↩ (cond) ⊑ out‿"unavailable/no_cycle"
```

### 4. module field を `⇐` に直接渡せない

```bqn
unav ← •Import "unavailable.bqn"

# ❌ エラー: unav.NoPolicy を ⇐ の右辺にできない
{ field ⇐ unav.NoPolicy }

# ✅ ローカル変数に取り出してから渡す
noPolicy ← unav.noPolicy
{ field ⇐ noPolicy }
```

module field の値は `⇐` の右辺で直接使えない。一度 `←` で受ける必要がある。

### 5. `⍟`（条件適用）ブロック内の副作用には `𝕊` が必須

BQNの `{ ... }` ブロックは、内部に `𝕊`（または `𝕩`, `𝕨`）を含まない場合、出現した時点で即座に実行（即時評価）されます。

```bqn
# ❌ 意図しない挙動: ⍟0（適用回数0）だが、内部の変数代入が即座に実行されてしまう
a ← 5
{ a ↩ 10 }⍟0 @  # a は 10 になってしまう

# ✅ 𝕊 ⋄ を含めることで「関数」として遅延評価させる
a ← 5
{ 𝕊 ⋄ a ↩ 10 }⍟0 @  # a は 5 のまま
```

### 6. 右結合による関数適用の「飲み込み」

BQNの関数適用は右結合的で、右側にあるすべての式を引数としてバインドしようとします。文字列連結 `∾` などと組み合わせる際に括弧がないと、右側の連結式全体が関数の引数として消費されてしまいます。

```bqn
# ❌ 意図しない挙動: sys.DefaultJournalFile に右側全体が引数として渡される
•Out "OK" ∾ tab ∾ sys.DefaultJournalFile @ ∾ tab ∾ metadata

# ✅ 関数呼び出しを括弧で包んで独立して評価させる
•Out "OK" ∾ tab ∾ (sys.DefaultJournalFile @) ∾ tab ∾ metadata
```

### 7. 小文字の変数名による関数の構文エラー（Double Subjects）

BQNではスペリングルールにより、小文字で始まる名前（例: `f`）は常に「主語（値）」として構文解析されます。そのため、小文字名に代入した関数を呼び出そうとすると構文エラーになります。

```bqn
# ❌ エラー: f は主語とみなされるため f 1 は「主語が2つ連続している（Double Subjects）」と判定される
f ← { 𝕩 ⋄ "res" }
•Out f 1

# ✅ 大文字で始まる名前で定義すると、構文上「関数」として正しく認識される
F ← { 𝕩 ⋄ "res" }
•Out F 1
```

## 出力互換性 (Output compatibility)

### `src_next/summary.bqn` / `tools/report-next-summary`

- 現行の機械向け入口は `tools/report-next-summary`（内部で `src_next/summary.bqn`）です。
- 出力は section-specific な key/value text で、`tools/query` がそのフィルタ入口です。
- 下流のスクリプトや pit 作業がキー名に依存する場合があります。

ポリシー:
- 既存のキー名を変更するよりも、新しいキーを追加することを優先します。
- 名前の変更が必要な場合は、移行期間中も古いキーを維持するか、docs/check を同じ差分で更新してください。
