# TODO History (2026-06-27)

This document archives completed TODO sections from the main `TODO.md` file up to 2026-06-27, keeping the active checklist clean.

---

## Completed: old engine removal

全フェーズ完了。`bqn-ledger` は `src_next` だけの独立プロジェクトに移行済み。
詳細は `docs/OLD_ENGINE_REMOVAL_PLAN.md` を参照。

## Completed: 動的勘定科目空間 (2026-06-26)

`src_next/` は既に完全動的。コード変更不要。docs更新のみ。
詳細は `docs/ENGINEERING_ROADMAP.md` 項目1。

## Completed: Failure Fixtures (2026-06-26)

2 fixture 追加、6 fixture 既存確認。全 `check-src-next-golden.sh` 接続済み。
詳細は `docs/ENGINEERING_ROADMAP.md` 項目6。

- `src-next-missing-budget-mapping/` — budget mapping 欠け
- `src-next-broken-empty-columns/` — 空列保持破損

## Completed: 取消・修正UI (2026-06-26)

`journal reverse` サブコマンド追加。`add-ui.sh` に reverse モード追加。
Go テスト 8件追加。全チェック PASS。
詳細は `docs/ENGINEERING_ROADMAP.md` 項目2。

## Completed: report screen review loop

全11画面 adopted、2画面 rejected。mock review フェーズ完了。
実装は `docs/ENGINEERING_ROADMAP.md` の流れで進める。

- [x] 11 screens adopted: Account Balances, Current Cycle Summary, Actual Comparison, Planned Payments, YTD Summary, Outlook/Daily Amount, Daily Trend, Trial Balance, Recent Journal, Readiness Check, Envelope & Budget
- [x] 2 screens rejected: Balance Summary, Expense Breakdown
- [x] mock review phase complete（docs-only、実装は未着手）

## Completed: src_next accounting-grade engine (Phase A–E + Household Policy Phase 0–4)

全フェーズ完了。`tools/report` が本番 default として稼働中。

- Phase A: TBDS opening/movement/closing gate ✓
- Phase B: ledger-wide context split (BuildAllRows + BuildPeriodView) ✓
- Phase C: Trial Balance / Balance Sheet / Income Statement ✓
- Phase D: accounting reports complete ✓
- Phase E: current engine vs src_next field comparison (38/38 match) ✓
- Household Policy Phase 0–3: boundary doc, assumption audit, policy schema, two-style fixture proof ✓
- Household Policy Phase 4: view toggling & anchor control ✓

## Completed: ledger engine adoption track

全項目完了。`src_next` は本番 default として稼働中。
