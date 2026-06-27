# Household Policy Assumption Audit


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
Status: **Phase 1 complete / classification table**
Date: 2026-06-26
Source: `docs/HOUSEHOLD_POLICY_LAYER_PLAN.md` Phase 1

## 1. 分類軸

各前提を次の5軸に分類する：

| 分類 | 意味 |
|---|---|
| **core** | 会計事実として必要な概念（role, account, layer, debit/credit 等）。変更不可。 |
| **metadata** | 勘定科目ごとのメタデータキー（`budget=`, `budget_group=`, `spend_class=`, `cashflow=`）。キーの名前は core の契約だが、値は policy。 |
| **policy** | 生活スタイルに依存する選択（daily/flex/reserve の名称、グループ順序、封筒予算の有無、risk style）。policy profile で差し替え可能であるべき。 |
| **presentation** | 表示層の選択（日本語ラベル、ソート順、フォーマット）。core 計算に影響しない。 |
| **fixture** | テスト用 fixture にのみ存在し、production コードには影響しない前提。 |

## 2. 監査テーブル

### 2.1 `src/core/account_space.bqn` — メタデータ解決（core 寄り）

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 16-18 | `household_life_groups`, `household_reserve_groups`, `household_group_order` を config から読む | **policy** | ラベル文字列自体は config 由来だが、コードが `daily/flex/reserve` の存在を前提にしている（index 0,1 でアクセス） |
| 90 | `IsFixedExpAcc` — `fixed=1` メタデータ | **metadata** | `fixed` キーは会計分類として妥当 |
| 96 | `IsEnvelopeAcc` — `kind=envelope` メタデータ | **metadata** | 封筒予算を使うかどうかは policy だが、キー名自体は metadata |
| 99-106 | `SpendClass` — `variable`/`fixed`/`other` への分類 | **metadata** | spend_class 明示がなければ variable/fixed 推論。分類ロジック自体は core 寄り |
| 108 | `BudgetGroup` — `budget_group` メタデータ | **metadata** | キー名は core、値は policy |
| 114-115 | `IsDailyGroup`, `IsFlexGroup` — index 0,1 固定 | **policy** | `daily` が life_groups[0]、`flex` が life_groups[1] という前提は moko の封筒スタイル固有 |
| 116-117 | `IsLifeGroup`, `IsReserveGroup` — config のリストと照合 | **metadata** | config 駆動で特定ラベルに依存しない |

### 2.2 `src/core/config.bqn` — 設定読み込み

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 85-87 | `HOUSEHOLD_GROUP_LIFE`, `HOUSEHOLD_GROUP_RESERVE`, `HOUSEHOLD_GROUP_ORDER` | **policy** | これらのキー名は core の契約だが、値（daily,flex,reserve）は policy |

### 2.3 `src/core/cycle.bqn` — サイクル解決

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 64 | `inc_acc ← "income_account" KVGet kv` — cycle.tsv から読み取り | **metadata** | `income_account` キーは core の契約。値（`income:年金`等）は policy |

### 2.4 `src/views/envelope_view.bqn` — 封筒計算（current engine）

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 56 | `meta.IsReserveGroup` → `"SAFE"` / `"HELD"` / `"DONE"` の status ラベル | **presentation** | 表示ラベルであり計算に影響しない |
| 49,54,78,108,114,150,155,167,172 | `env_history_daily`, `target_daily` などの daily 計算 | **policy** | 封筒の日割りロジックは envelope budget style の一部 |

### 2.5 `src/views/liquid_view.bqn` — 流動資産・日割り

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 15 | `"fixed" ≡ SpendClass` で固定費行を識別 | **metadata** | spend_class キー自体は core だが、`fixed` 値は policy |
| 37,130 | `IsFixedExpAcc`, `idx_fixed` で固定費勘定を識別 | **metadata** | 同上 |
| 144-150 | `trend_fixed_reserve`, `trend_daily_fund`, `trend_daily` | **policy** | 固定費を先に確保して日割りを出すのは conservative risk style の選択 |

### 2.6 `src/views/cashflow_obligation_view.bqn` — 固定義務

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 62 | `"fixed_obligation" ≡ GetMetaVal ⟨"cashflow", ...⟩` | **metadata** | `cashflow=fixed_obligation` の値は policy だが、キー構造は metadata |
| 65-71 | `fixed_obligation_reserve` 計算 | **policy** | 現金 outflow をreserve する判断は obligation style の選択 |

### 2.7 `src/views/plan_view.bqn` — 予定・日割り outlook

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 102-179 | `liq_daily`, `liq_safe_daily`, `budget_daily` の日割り計算 | **policy** | 日割り配分・安全保守計算は risk style + budget style の選択 |
| 126-130 | 将来の固定費を conservative に reserve | **policy** | 同上 |

### 2.8 `src_next/envelope_computation.bqn` — 封筒計算（src_next）

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 32-36 | `FixtureFoodLikeTarget` — `"食費"` ラベル hardcoded | **fixture** | テスト用 fixture のみ。production では `NoPolicyTarget`。ただし fixture 内の日本語ラベルはmoko固有。 |
| 160 | `kind_envelope_mask ← "envelope"⊸≡¨` | **metadata** | `kind=envelope` は metadata 契約 |
| 358 | `GetPri ← { ⊑ ⟨"daily", "flex", "reserve"⟩ ⊐ ⟨𝕩⟩ }` | **policy** | グループの表示優先順を "daily > flex > reserve" に固定。moko の封筒スタイル固有。 |

### 2.9 `src_next/household_policy.bqn` — 家計ポリシー診断

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 25,64,65 | `"variable"`, `"fixed"` を既知の spend_class として扱う | **metadata** | これらの値は metadata 契約の一部。ただし値自体は policy 由来。 |
| 34-40 | `daily_label`, `flex_label`, `reserve_label` を config から読む | **policy** | config 駆動だが、3-way split 自体が特定の封筒スタイル前提 |
| 57-59, 62 | `group_daily`, `group_flex`, `group_reserve` の集計 | **policy** | これら3軸での集計は envelope budget style 前提 |

### 2.10 `src_next/actual_comparison.bqn` — 実績比較

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 214 | `(sc ≡ "fixed") ⊑ "variable"‿"recurring_fixed"` | **metadata** | spend_class の値に依存。値自体は policy だが分類ロジックは core 寄り |

### 2.11 `src_next/ytd_summary.bqn` / `src_next/daily_trend.bqn`

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| ytd:50 | `"fixed"` spend_class でマスク | **metadata** | 同上 |
| trend:47-48 | `"variable"`, `"fixed"` spend_class で分類 | **metadata** | 同上 |

### 2.12 `src_next/snapshot.bqn`

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| 217-220 | `daily_remaining`, `flex_remaining`, `reserve_remaining` 表示（現在 fallback） | **presentation** | 表示ラベル。ただし3-way split 表示は envelope style 前提 |
| 169-170 | `section_source_outlook_daily ⇐ fallback_current` | **presentation** | 現在は current engine に委譲 |
| 233-234 | envelope と daily amount は src_next 未実装と明記 | **presentation** | 正常な境界宣言 |

### 2.13 `config/default_config.tsv` / `data/config.tsv`

| 行 | 内容 | 分類 | 理由 |
|---|---|---|---|
| HOUSEHOLD_GROUP_LIFE | `daily,flex` | **policy** | moko の封筒グループ名 |
| HOUSEHOLD_GROUP_RESERVE | `reserve` | **policy** | 同上 |
| HOUSEHOLD_GROUP_ORDER | `daily,flex,reserve` | **policy** | 同上 |

### 2.14 コード中に出現しないもの（肯定的所見）

| 項目 | 状態 |
|---|---|
| `pension` / `年金` | ❌ コード中に出現しない。cycle.tsv の `income_account` 値としてのみ存在。 |
| `food` / `食費` | ⚠️ `envelope_computation.bqn` の fixture にのみ出現。production コードにはなし。 |
| `calendarMonth` | ❌ コード中に出現しない。cycle.tsv の `mode` 値としてのみ存在。 |
| `incomeAnchor` | ❌ コード中に出現しない。同上。 |

## 3. まとめ

### 3.1 分類別件数

| 分類 | 件数 | 主な場所 |
|---|---|---|
| **core** | 0 | —（コード変更不要の前提は見つからず） |
| **metadata** | 12 | spend_class, budget, budget_group, kind, cashflow 等のキー |
| **policy** | 8 | 封筒グループ名, グループ順序, 日割り計算, reserve 方針 |
| **presentation** | 4 | 表示ラベル, fallback 委譲 |
| **fixture** | 1 | `FixtureFoodLikeTarget` |

### 3.2 最優先で外部化すべきもの

1. **グループ優先順序** (`envelope_computation.bqn:358`)
   - `⟨"daily", "flex", "reserve"⟩` の hardcoded リスト
   - → config の `HOUSEHOLD_GROUP_ORDER` を参照するように変更可能

2. **`IsDailyGroup` / `IsFlexGroup`** の index-based 解決 (`account_space.bqn:114-115`)
   - 現状: life_groups[0] = daily, life_groups[1] = flex
   - → `IsLifeGroup` のようにリスト照合で解決可能

3. **封筒日割り計算** (`envelope_view.bqn`, `liquid_view.bqn`, `plan_view.bqn`)
   - 固定費を reserve してから日割り、等のロジック
   - → conservative risk style の policy profile として定義可能

### 3.3 すでに policy-aware なもの（肯定的）

- `household_policy.bqn` — config から全ラベルを読む ✅
- `household_metadata.bqn` — 特定ラベルに依存しない ✅
- cycle resolver — `income_account` を config から読む ✅
- `HOUSEHOLD_GROUP_*` — config 駆動 ✅
- `snapshot.bqn` — envelope 未実装を明示し current engine に委譲 ✅

## 4. 次の一手（Phase 2 向け）

1. `HOUSEHOLD_GROUP_ORDER` を `envelope_computation.bqn:358` に接続する
2. `IsDailyGroup`/`IsFlexGroup` を index ではなくリスト照合に変更する
3. Household policy profile schema の最小設計（Phase 2）
