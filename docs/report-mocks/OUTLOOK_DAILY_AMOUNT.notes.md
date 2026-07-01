# Outlook Dashboard Mock Notes

Status: **adopted**
Review state: `adopted`
Date: 2026-06-26
Adopted: 2026-06-26

## Question answered

今日から1日いくらまで使えるか。よく使う封筒の日割りはどうか。

## View type

```text
daily dashboard / forecast
```

毎日見るダッシュボード。「今日の許容支出はいくらか」「封筒ごとのペースはどうか」に答える。

## Relationship to other screens

- **Account Balances**: 資産残高の全景。Outlook はそのうち可用資金だけを日割り計算の根拠に使う
- **Current Cycle Summary**: サイクル収支の実績。Outlook は残日数ベースの将来ペース
- **Envelope / Budget**: 全封筒の健全性。Outlook は daily+flex 封筒だけの日割り簡易表示

## Intended source when implemented

```text
actual_snapshot → liq_total as of today
plan.tsv → future income/expense in remaining days
cycle → days_left
envelope_computation → remaining per envelope
```

## Include

- サイクル期間と残日数
- 可用資金 → 予定収入・支出差引 → 使える可用資金 → 日割り
- daily + flex 封筒（remaining > 0）の日割り

## Exclude

- 資産完全内訳（Account Balances）
- reserve 封筒（Envelope / Budget）
- 残高0の封筒
- journal lag 警告

## Review decisions (2026-06-26)

- 日割り: 1種類（使える可用資金 ÷ 残日数） ✓
- 表示封筒: budget_group ∈ {daily, flex} かつ remaining > 0 ✓
- 画面名: Outlook Dashboard ✓

## Decision log

```text
review_state: adopted
human_decision: adopted 2026-06-26
notes: 日割り1種類, 封筒=daily+flex(remaining>0), 残高0非表示
```
