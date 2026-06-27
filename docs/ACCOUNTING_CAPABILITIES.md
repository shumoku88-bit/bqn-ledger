# Accounting Capabilities Roadmap

Status: future design memo / aspiration
Branch: `docs/accounting-capabilities-roadmap`
Scope: `src_next` の将来設計として、複式簿記的な機能を視野に入れることを明文化する。

## 1. 背景と目的

`src_next/` は現時点では **read-only experimental core** である。
現在の方向性は、人間が読める source event row（`journal.tsv`, `plan.tsv`, `budget_alloc.tsv`）を、
**ledger-like projection rows** に変換することにある。

この文書は、現在の production engine を置き換える話ではなく、
`src_next` の将来設計として、以下の複式簿記的な機能を視野に入れていることを明文化するための設計メモである。

## 2. 現在の到達点（src_next に実装済み）

`src_next/projection.bqn` はすでに以下の ledger-like 構造を持つ：

- 1 つの source event row が **debit 行** と **credit 行** に展開される
- 各行は `side`（`"debit"` / `"credit"`）を明示
- delta は debits が正、credits が負
- `source_id` で束ねられた行の delta 合計が 0 になることの balance validation
- `kind` 推論：`income` / `expense` / `transfer` / `budget`

## 3. 将来視野に入れている会計機能

以下は **いずれも production feature として実装済みではない**。
`src_next` の将来拡張として視野に入れる概念であり、実装時期や実装有無は未確定である。

### 3.1 アカウント分類（Account Taxonomy）

projection layer において、各 account に以下の分類を持たせうる余地を残す：

| 分類 | 意味 | normal side |
|------|------|-------------|
| Asset（資産） | 所有する経済的価値 | debit |
| Liability（負債） | 将来支払うべき義務 | credit |
| Equity（純資産） | 資産 − 負債 | credit |
| Income（収益） | 流入する経済的利益 | credit |
| Expense（費用） | 消費される経済的価値 | debit |

現在の `accounts.tsv` は `role=` メタデータ（`asset` / `liability`）を持つが、
上記の5分類への拡張や normal side の概念は未導入である。

### 3.2 Normal Side

各 account に「通常の残高が立つ側（normal side）」を定義し、
異常残高（資産が credit 残高など）の検出に使えるようにする設計余地を残す。

### 3.3 試算表（Trial Balance）

全 account の debit 合計と credit 合計が一致することを検証する **trial balance** の概念を視野に入れる。

現在の `src_next/projection.bqn` は `source_id` 単位の balance check まで実装済みだが、
全 projection rows を横断した `total debits = total credits` の検証は未実装である。

### 3.4 複数ポスティング（Multi-Posting Transactions）

1 つの現実イベント（レシート、銀行明細）が 3 つ以上の勘定に影響するケース
（例：給与 = 銀行入金 + 源泉所得税 + 社会保険料）を扱う設計余地を残す。

本体ではすでに A-1（`txn_id` メタデータによる複数行束ね）の方針が `DECISION_MULTI_POSTING_INVESTIGATION.md` で決定済みであり、
projection layer でもこの方針との整合を視野に入れる。

### 3.5 生成エントリ（Generated Entries）

以下のような、source TSV から直接来るのではなく projection/validation layer で生成されるエントリを視野に入れる：

- **opening entry**（期首振替）：前期末残高を当期に繰り越す
- **closing entry**（期末振替）：収益・費用を純資産に振り替える
- **carry-forward**（次期繰越）：資産・負債残高を次期に引き継ぐ
- **income summary**（損益集約）：期間収益と期間費用を集約する中間勘定

## 4. 設計方針

### 4.1 レイヤー分離

```
source TSV (人間可読・軽量)
  └── projection layer (会計的厳密性)
        └── validation layer (trial balance, normal side check, etc.)
```

- **source TSV**（`journal.tsv`, `plan.tsv`, `budget_alloc.tsv`）は、
  人間が読み書きできる軽い形式として保つ。
  `date / memo / from / to / amount` の先頭5列契約を維持する。
- **会計的な厳密性**（debit/credit, account taxonomy, trial balance, generated entries）は、
  projection layer および validation layer に集める。
  これにより、日々の記帳の気軽さと、会計的な正しさの検証を両立させる。

### 4.2 既存 production engine との関係

この文書に記載された会計機能は、**現在の production engine（`src/` 以下の BQN エンジン）を置き換える計画ではない**。
`src_next/` が将来 production engine として十分に安定した場合に、検討対象となりうる拡張である。

### 4.3 用語の注意

この文書では「視野に入れる」という表現を意図的に使っている。
「できます」「実装します」ではない。
あくまで設計上の方向性を示し、将来 AI 作業員が変な方向に暴走するのを防ぐための道標である。

## 5. 参照

- `docs/CURRENT_STATE_REFERENCE.md` — `src_next` の現行 baseline
- `docs/DECISION_MULTI_POSTING_INVESTIGATION.md` — 複数ポスティング方針（A-1 採用）
- `src_next/projection.bqn` — 現在の ledger-like projection 実装
- `src_next/cube.bqn` — cube materialize + sanity + numeric verification
