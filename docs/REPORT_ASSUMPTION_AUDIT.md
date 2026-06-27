# Report Policy Assumption Audit (Phase 0)

BQN-Ledgerのレポート・表示ロジック内の棚卸し結果です。
「計算の芯（数学モデル）」と「生活上の名前（ハードコードされた具体的なカテゴリ）」、「表示だけの都合」を見分けて、安全に外部化するための台帳です。

---

## 1. 監査台帳 (Assumption Audit Ledger)

| literal | location | kind | keep-in-code? | externalize-to | reason | next action |
|---|---|---|---|---|---|---|
| `"daily"` | `account_space.bqn` policy helper経由<br>`export-report-numbers.bqn` は互換helper経由 | 生活上の名前 ＋ 表示だけの都合 | **NO** | `accounts.tsv` の `budget_group` 値 + `data/config.tsv` の `HOUSEHOLD_GROUP_LIFE` / `HOUSEHOLD_GROUP_ORDER` | `"daily"` 封筒は生活費として使うという生活ルールであり、production code内の恒久概念ではない。現在はconfig上の生活ポリシー値として維持する。 | **Done (small boundary)** `IsLifeGroup` / `GroupPri` はconfig listを読む。`IsDailyGroup` は現行出力互換helperとしてconfig由来の先頭life labelを見る。 |
| `"flex"` | `account_space.bqn` policy helper経由<br>`export-report-numbers.bqn` は互換helper経由 | 生活上の名前 | **NO** | `accounts.tsv` の `budget_group` 値 + `data/config.tsv` の `HOUSEHOLD_GROUP_LIFE` / `HOUSEHOLD_GROUP_ORDER` | `"flex"` も生活ルール上の封筒カテゴリであり、生活費封筒としての合算判定をコード内の固定文字列にしない。現在はconfig上の生活ポリシー値として維持する。 | **Done (small boundary)** `IsLifeGroup` / `GroupPri` はconfig listを読む。`IsFlexGroup` は現行出力互換helperとしてconfig由来の2番目life labelを見る。 |
| `"reserve"` | `account_space.bqn` policy helper経由<br>`envelope_view.bqn` / `sec_envelopes.bqn` は `IsReserveGroup` 経由 | 生活上の名前 ＋ 表示だけの都合 | **NO** | `accounts.tsv` の `budget_group` 値 + `data/config.tsv` の `HOUSEHOLD_GROUP_RESERVE` / `HOUSEHOLD_GROUP_ORDER` | `"reserve"` は貯金・投資などの「仮確保封筒」の役割であり、ペース健康診断で `SAFE` ではなく `HELD/DONE/DRAWN` を出すための生活ポリシー値。現在はconfig上の値として維持する。 | **Done (small boundary)** `IsReserveGroup` / `GroupPri` はconfig listを読む。 |
| `"variable"` | `liquid_view.bqn` (L36)<br>`account_space.bqn` (L100)<br>`lint_journal.bqn` (L226)<br>`readiness_view.bqn` (L11) | 計算の芯 ＋ データ契約 | **YES** | N/A (一部 config / meta_schema へ) | 財務計算モデルにおいて「日々の流動的な変動費」と「固定費」を分けること自体は計算モデルの芯（Layer）に直結するため。 | 現状維持。ただし `variable` 費目に封筒を義務付ける制約は、必要なら `config/meta_schema.tsv` と連動させる。 |
| `"fixed"` | `liquid_view.bqn` (L15, L37, L130)<br>`account_space.bqn` (L84, L97, L100)<br>`cycle.bqn` (L62) | 計算の芯 ＋ データ契約 | **YES** | N/A | 「固定費」という予定の控除モデル（数学的な差分）は計算モデルの芯（Layer）そのものであるため。 | 現状維持。 |
| `"savings"`<br>`"invest"` | `account_space.bqn` (L83)<br>`liquid_view.bqn` (L38, L140) | データ契約 (口座種別) | **YES** | N/A | 貯金・投資口座としての純増減を計算するための、普遍的な勘定科目の分類定義（type）であるため。 | 現状維持。 |
| `sec_keys`<br>`sec_labels` | `report_sections.bqn` (L26, L30) | 表示だけの都合 | **YES** (当面) | `report_sections.tsv` (将来のPhase 2候補) | 完全に外部化すると、dispatcherで重複・未定義チェックが必要になりコードが複雑化するため、当面は配列としてコードに保持することが推奨される。 | **(Phase 2)** 外部TSV化するか、コード保持＋docs同期で留めるかを判断する。 |

---

## 2. 調査分析：名前の石（具体的な口座名） vs 意味の札（抽象化された役割）

今回最も重要な論点は、`daily` / `flex` / `reserve` という名前がコード内でどのように登場しているかです。

### 結論
*   **「名前の石」としてのコード出現はすでに回避されている**:
    *   コード内では `budget:食費` のような具体的な口座名（石）は直接比較されていません。
    *   `envelope_view.bqn` や `sec_envelopes.bqn` は、アカウント名ではなく、あらかじめ `accounts.tsv` のメタデータからパースされた `env_groups` （＝ `budget_group` メタデータの値）を参照して動作しています。
*   **「意味の札」としての文字列は小さなconfig境界へ移した**:
    *   BQN view code（`envelope_view.bqn` 等）は `IsReserveGroup` / `IsLifeGroup` / `GroupPri` を呼び、具体的な `budget_group` label の意味は `account_space.bqn` の policy helper に寄せています。
    *   現行の `"daily"` / `"flex"` / `"reserve"` は `data/config.tsv` の `HOUSEHOLD_GROUP_*` 値であり、production view codeが恒久概念として直接比較しない方針です。

### 改善後の方向性（意味の札の抽象化）
Phase 1 の小さな実装として、次の境界に寄せています。
```text
[改善前]
viewコード --- 直接文字列比較 (group ≡ "reserve") ---> 特定の生活ルール(HELD/DONE/DRAWN)の適用

[改善後]
viewコード --- 抽象関数の呼び出し (IsReserveGroup)
                        |
                        +---> account_space.bqn (budget_group labelをpolicy helperで評価)
                                            |
                                            +---> data/config.tsv の HOUSEHOLD_GROUP_* 設定値
```

これにより、view側のコードから `"reserve"` などの特定の生活名称を隠蔽し、生活上の意味決定のコントロールをメタデータと設定ファイル側に集約します。現行の `daily` / `flex` / `reserve` は、恒久的なコード概念ではなく、現在の `data/config.tsv` に書かれた生活ポリシー値です。
