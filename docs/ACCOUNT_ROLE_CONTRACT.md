# ACCOUNT_ROLE_CONTRACT

## 目的
勘定科目（Account）の名前から会計上の役割（Role）を分離し、どのような名前でも正しく集計できるようにする。

## Role一覧
すべての勘定科目は以下のいずれか1つの `role` を持つ。

| role | 説明 | 例 | Prefix fallback |
|:---|:---|:---|:---|
| `asset` | 資産（プラス残高が正） | 普通預金, 現金 | `assets:*` |
| `liability` | 負債（マイナス残高が正） | クレジットカード, 借入金 | `liabilities:*` |
| `income` | 収益（マイナス発生が正） | 給与, 利息 | `income:*` |
| `expense` | 費用（プラス発生が正） | 食費, 家賃 | `expenses:*` |
| `equity` | 純資産領域（初期残高など） | 開始残高 | `equity:*` |
| `budget` | 予算・封筒（プラス残高が正） | 食費予算, 予備費 | `budget:*` |

## メタデータ組み合わせ規則

| role | type | spend_class | budget | 備考 |
|:---|:---|:---|:---|:---|
| `asset` | `liquid` / `savings` / `invest` | - | - | |
| `liability` | - | - | - | |
| `income` | - | - | - | |
| `expense` | - | `fixed` / `variable` | 封筒名 | `budget` は `role=budget` の科目名 |
| `equity` | - | - | - | |
| `budget` | - | - | - | |

## Role解決規則（Fallback）
システムは以下の優先順位で科目の役割を決定する。

1. **明示的な `role=` メタデータ**: `accounts.tsv` のメタデータ列に `role=asset` 等がある場合、それを正とする。
2. **Prefix fallback**: メタデータがない場合、名前の先頭文字列から推測する（`assets:` -> `asset` など）。
3. **Unknown**: いずれにも該当しない場合はエラーとする。

### Prefix fallback 廃止条件

現在、システム移行期間の救済措置として Prefix fallback が動作しています。この fallback を完全に廃止し、明示的な `role=` メタデータのみを正とするための条件は以下の通りです。

1. Prefix fallback の使用回数が検出可能であること（`src_next_household_metadata_prefix_fallback_total_count` として実装済み）。
2. `src_next` の全レポートエンジンで `role=` のフォールバック検出が有効になり、テストカバレッジが確保されていること（`fixtures/src-next-missing-role-fallback` にて実装済み）。
3. `tools/edit` や TUI 等を通じた Account 登録の新規経路において、必須メタデータ（`role`）の入力を強制する安全な編集フローが完成していること。
4. すべての実データ (`data/accounts.tsv`) の全アカウントに対し、明示的な `role=` が付与されていること（移行スクリプトまたは手動での付与が完了し、`prefix_fallback_total_count == 0` が維持できていること）。
5. `tools/check.sh` の中で「Prefix fallback 使用数が 0 であること」をアサートする negative validation が追加され、それが恒久的な Fail-Closed ルールとして有効化されること。

## エラーと警告の契約（Lint）

`src_next` では、設定やメタデータの不備について「処理を続行しつつ警告を記録するもの（Warning）」と「集計から除外または異常終了するもの（Error / Fail-Closed）」を明確に区別する。

### 1. Fail-Closed 事項（エラー・除外）
- **未定義アカウントの参照**: `journal.tsv` や `plan.tsv` 等で `accounts.tsv` に存在しない勘定科目を参照した場合、該当する仕訳行はすべて集計からスキップされ（`unknown_account_count` が増加）、正本レポートとしては不適格な状態となる。
- **未知の Enum 値**: `role=magical` や `spend_class=maybe` のように仕様にないメタデータ値が指定された場合、`unknown_role_accounts_count` 等の lint エラーとして検出され、将来的にはCIの Fail-Closed 条件として扱われる。
- **重複宣言**: `accounts.tsv` に同一科目名の重複がある場合、または1行の中に同一のメタデータキー（例: `type=liquid` と `type=savings`）が複数存在する場合、lint エラーとして検出される。

### 2. Warning 事項（必須メタデータ欠損）
メタデータの欠損自体は、直ちにエラーとして計算を停止するものではない。段階的な移行と運用を考慮し、現在は警告（Diagnostics）としてのみ扱われる。
- **`role=` の欠損**: Prefix fallback によって救済される。`prefix_fallback_total_count` としてカウントされ、これが0になるまでは警告として扱われる。
- **`budget=` / `budget_group=` の欠損**: これらは家計レポート（封筒計算）用の付加情報であり、欠落していても計算は停止しない（表示先が "missing" 等に分類されるか無視される）。ただし `missing_budget_count` 等として警告集計される。
- **`spend_class=` の欠損**: 変動費/固定費の分類にのみ影響するため、計算停止はしない。警告として集計される。

## 予算封筒の分類（budget_group）
`role=budget` （予算・封筒）のアカウントは、`accounts.tsv` に設定される `budget_group` メタデータにより分類される。

現行 production report では、現在の生活ポリシー値として `daily` / `flex` / `reserve` のようなラベルを使っている。ただし、これらの具体名は生活上のポリシーラベルであり、恒久的な計算概念として扱わない。production BQN code は `account_space.bqn` の policy helper を通し、生活封筒・仮確保封筒・表示順は `data/config.tsv` の次の設定値から読む。

```tsv
HOUSEHOLD_GROUP_LIFE=daily,flex
HOUSEHOLD_GROUP_RESERVE=reserve
HOUSEHOLD_GROUP_ORDER=daily,flex,reserve
```

`IsDailyGroup` / `IsFlexGroup` は現在の出力互換用 helper であり、固定文字列比較ではなくconfig由来の現行labelを参照する。将来の `src_next` household report では、これらの具体名を恒久的な計算概念として扱わない。`src_next` の契約は `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` を参照する。

現在のラベル例:

*   **生活封筒** (現行configでは `budget_group=daily` または `budget_group=flex`):
    *   生活費として実際に「使うため」の封筒。
    *   ペース評価（SAFE, WARN, SHORT）や使いすぎ警告が行われる。
*   **仮確保封筒** (現行configでは `budget_group=reserve`):
    *   貯金・投資などの資金を一時的に確保しておくための枠（「使うため」ではない）。
    *   使い切ることが目的ではなく、サイクル末または月末まで維持できた額が貯金・投資として確定する。
    *   ステータスはペース評価ではなく `HELD`（仮確保中）、`DONE`（維持確定）、`DRAWN`（取り崩しあり）で管理される。

