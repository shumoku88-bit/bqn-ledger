# Phase 3: Contrasting Fixture Proof

Status: **complete**
Date: 2026-06-26

## 1. 目的

「accounting core が policy-independent で、household view だけが policy で変わること」を fixture で証明する。

## 2. 2つの Fixture

### 2.1 `fixtures/household-moko` — 年金隔月 + incomeAnchor + 封筒

```
cycle:       incomeAnchor (income_account=income:年金)
accounts:    封筒口座あり (budget_group=daily/flex, kind=envelope)
config:      POLICY_BUDGET_STYLE=envelope, POLICY_RISK_STYLE=conservative
journal:     年金収入(2ヶ月毎)、食費・日用品・家賃
budget_alloc: 封筒予算配分あり
```

Cycle: 2026-06-15 .. 2026-08-15

### 2.2 `fixtures/household-monthly-salary` — 月給 + カレンダー月 + 封筒なし

```
cycle:       fixed (2026-05-01..2026-06-01)
accounts:    封筒口座なし (budget_group なし、kind=envelope なし)
config:      POLICY_BUDGET_STYLE=none, POLICY_RISK_STYLE=simple
journal:     月給収入(毎月)、食費・家賃
budget_alloc: 空
```

Cycle: 2026-05-01 .. 2026-06-01

## 3. Accounting Core の独立性証明

### 3.1 Phase E 比較結果

| Fixture | アカウント数 | match | engine_diff |
|---|---|---|---|
| household-moko | 10 | 10 | 0 |
| household-monthly-salary | 5 | 5 | 0 |

両方の fixture で、current engine と src_next の TBDS (opening/movement/closing) が完全一致。
**会計エンジンは policy 設定に依存しない。**

### 3.2 Household View の差分

| Section | household-moko | household-monthly-salary |
|---|---|---|
| Sec 1 (Snapshot) | ✅ 表示（net_worth あり） | ✅ 表示 |
| Sec 2 (YTD Summary) | ✅ 表示 | ✅ 表示 |
| Sec 3 (Balances) | ✅ 表示 | ✅ 表示 |
| Sec 4 (Cycle Summary) | ✅ 表示 | ✅ 表示 |
| **Sec 5 (Envelopes)** | ✅ **封筒表示あり** | ❌ **表示なし** |
| Sec 6 (Planned Payments) | ✅ 表示 | ✅ 表示（空） |
| Sec 7 (Recent Journal) | ✅ 表示 | ✅ 表示 |
| Sec 8 (Readiness Check) | ✅ 表示 | ✅ 表示 |
| Sec 9 (Outlook/Daily) | ✅ 表示（conservative daily） | ✅ 表示（simple daily） |
| Sec 10 (Daily Trend) | ✅ 表示 | ✅ 表示 |
| Sec 11 (Actual Comparison) | ✅ 表示 | ✅ 表示 |
| Sec 12 (Debug) | ✅ 表示 | ✅ 表示 |

## 4. 差分の分類

| 差分 | 分類 | 理由 |
|---|---|---|
| Sec 5 の有無 | **policy** | `POLICY_BUDGET_STYLE` が `envelope` → 表示, `none` → 非表示 |
| Sec 9 の daily 計算 | **policy** | `POLICY_RISK_STYLE` が `conservative` → fixed_reserve 考慮, `simple` → 単純日割り |
| それ以外の全 section | **同一** | accounting core 由来であり policy に依存しない |

## 5. 結論

1. ✅ 同一の accounting core (TBDS, Trial Balance) が異なる policy 設定で正しく動作する
2. ✅ 封筒予算の有無は `POLICY_BUDGET_STYLE` によって制御される
3. ✅ 日割り計算の保守性は `POLICY_RISK_STYLE` によって制御される
4. ✅ 収入周期性 (`POLICY_INCOME_CADENCE`) は現時点では表示切替に使われていない（将来用）
5. ✅ accounting core の計算結果は policy 設定に影響されない

**Phase 3 完了。**
