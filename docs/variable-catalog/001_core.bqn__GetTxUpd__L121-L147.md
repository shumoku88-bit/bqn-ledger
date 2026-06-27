# 変数名目録: core.bqn / GetTxUpd / L121-L147

目的: BQNコードを読むための補助資料。コード変更や変数名変更は行わない。

対象範囲:

- ファイル: `core.bqn`
- 関数: `GetTxUpd`
- 行範囲: `L121-L147`
- 参考呼び出し: `report_balances.bqn` の `accs lib.GetTxUpd ...`

## 概要

`GetTxUpd` は、取引1件 `⟨from, to, amount⟩` を 256×2 の更新行列に変換する。

- col0: Actual / 実残高
- col1: Intent / Budget / 予算・封筒

実残高では `To` 側を増やし、`From` 側を減らす。
予算列では、`budget:` 勘定同士の移動と、支出先勘定に紐づく予算封筒の消費を反映する。

## 目録

| 変数名 | 推定される正式名 | 日本語での意味 | その変数が出てくる場所 | 確信度 | 必要なら読みやすい改名案 |
|---|---|---|---|---|---|
| `GetTxUpd` | Get Transaction Update | 取引1件を 256×2 の更新行列に変換する関数 | `core.bqn:L121`, export `core.bqn:L158` | 高 | `GetTransactionUpdate` |
| `accs` | accounts | `InitAccounts` が返す勘定科目情報レコード。`names`, `budget_map`, `spent_id` を持つ | `core.bqn:L122` | 高 | `accounts` |
| `f_name` | from name | 取引の From 側勘定科目名 | `core.bqn:L123,L125,L134` | 高 | `from_name` |
| `t_name` | to name | 取引の To 側勘定科目名 | `core.bqn:L123,L126,L135` | 高 | `to_name` |
| `amt` | amount | 金額 | `core.bqn:L123,L129,L130,L143,L144` | 高 | `amount` |
| `f_idx` | from index | From 側勘定科目の 256 スロット上のID/位置 | `core.bqn:L125,L130` | 高 | `from_idx` / `from_id` |
| `t_idx` | to index | To 側勘定科目の 256 スロット上のID/位置 | `core.bqn:L126,L129,L139` | 高 | `to_idx` / `to_id` |
| `ut` | 推測: update to | To 側スロットだけに `amt` が入った 256 要素ベクトル | `core.bqn:L129,L131,L136` | 中 | `to_update` |
| `uf` | 推測: update from | From 側スロットだけに `amt` が入った 256 要素ベクトル | `core.bqn:L130,L131,L136` | 中 | `from_update` |
| `actual_upd` | actual update | 実残高列、col0 用の更新ベクトル。`To +amt`, `From -amt` | `core.bqn:L131,L147` | 高 | `actual_update` |
| `is_budget_f` | is budget from | From 側勘定が `budget:` で始まるか | `core.bqn:L134,L136` | 高 | `is_budget_from` |
| `is_budget_t` | is budget to | To 側勘定が `budget:` で始まるか | `core.bqn:L135,L136` | 高 | `is_budget_to` |
| `intent_upd_A` | intent update A | 予算勘定同士の移動を Budget/Intent 列に反映する更新 | `core.bqn:L136,L147` | 中 | `budget_transfer_update` |
| `target_b_id` | target budget id | To 側勘定に紐づく予算封筒アカウントのID。なければ `¯1` | `core.bqn:L139,L140,L143` | 高 | `target_budget_id` |
| `has_b` | has budget | `target_b_id` が存在するか | `core.bqn:L140,L145` | 高 | `has_budget` |
| `ub_from` | 推測: update budget from | 予算封筒から金額を減らすための 256 要素ベクトル | `core.bqn:L143,L145` | 中 | `budget_from_update` |
| `ub_to` | 推測: update budget to | `budget:spent` に金額を増やすための 256 要素ベクトル | `core.bqn:L144,L145` | 中 | `budget_to_update` |
| `intent_upd_B` | intent update B | 支出先勘定の `budget=` 紐づけに応じて、封筒から `budget:spent` へ動かす更新 | `core.bqn:L145,L147` | 中 | `budget_spending_update` |
| `budget_map` | budget map | 各勘定科目IDから、対応する `budget:*` 勘定IDへの対応表 | 定義 `core.bqn:L111`, 使用 `core.bqn:L139` | 高 | `account_to_budget_id` |
| `spent_id` | spent id | `budget:spent` 勘定のID | 定義 `core.bqn:L107,L112`, 使用 `core.bqn:L144` | 高 | `budget_spent_id` |

## BQN式の短い補足

### 引数分解

```bqn
accs ← 𝕨
f_name ‿ t_name ‿ amt ← 𝕩
```

左引数 `𝕨` は accounts レコード。
右引数 `𝕩` は `⟨from, to, amount⟩` の3要素で、それを `f_name`, `t_name`, `amt` に分解している。

### 勘定科目名からIDを引く

```bqn
f_idx ← ⊑ accs.names ⊐ ⟨ f_name ⟩
t_idx ← ⊑ accs.names ⊐ ⟨ t_name ⟩
```

`accs.names` の中で、From / To の勘定科目名がどの 256 スロットにあるかを探している。

### 実残高の更新ベクトル

```bqn
ut ← (t_idx = ↕256) × amt
uf ← (f_idx = ↕256) × amt
actual_upd ← ut - uf
```

`↕256` は `0..255` のインデックス列。
`t_idx` と一致する位置だけ `amt` が入り、From 側は引かれる。
結果として `To +amt`, `From -amt` の 256 要素ベクトルになる。

### 予算勘定同士の移動

```bqn
is_budget_f ← "budget:" ≡ 7 ↑ f_name
is_budget_t ← "budget:" ≡ 7 ↑ t_name
intent_upd_A ← (is_budget_f ∧ is_budget_t) × (ut - uf)
```

From / To がどちらも `budget:` で始まる場合だけ、予算列にも同じ移動を反映する。

### 支出先に紐づく予算封筒の消費

```bqn
target_b_id ← (t_idx < 256) ⊏ ⟨ ¯1 , ⊑ t_idx ⊑ accs.budget_map ⟩
has_b ← target_b_id ≠ ¯1
ub_from ← (target_b_id = ↕256) × amt
ub_to ← (⊑ accs.spent_id = ↕256) × amt
intent_upd_B ← has_b × (ub_to - ub_from)
```

To 側勘定に `budget=` メタで封筒が紐づいている場合、対応する `budget:*` から金額を減らし、`budget:spent` を増やす。

### 返り値

```bqn
⍉ actual_upd ≍ (intent_upd_A + intent_upd_B)
```

実残高更新と予算更新を並べ、転置して 256×2 の更新行列として返す。
