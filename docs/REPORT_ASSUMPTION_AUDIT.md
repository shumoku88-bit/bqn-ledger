# Report Assumption Audit (Phase 0)

Status: audited
Date: 2026-06-27

This document audits hard-coded assumptions, presentation metadata, and lifestyle-dependent rules currently residing inside the BQN codebase (`src_next/`). 

The goal is to catalog these assumptions before any externalization implementation begins, in accordance with the [Report Policy Externalization Plan](file:///Users/user/Projects/moko/bqn-ledger/docs/REPORT_POLICY_EXTERNALIZATION_PLAN.md).

---

## Audit Table

| Location | Literal / Concept | Kind | Keep in code? | Externalize to | Reason / Next Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `src_next/format.bqn` | Visual width (全角=2, 半角=1) | Math / Formatting Helper | **Yes** | N/A | Character width math is a core layout utility, not a lifestyle setting. |
| `src_next/balances.bqn:92-104` | `[Assets / Liquid]`, `[Assets / Savings]`, `[Assets / Investment]`, `[Liabilities]`, `[Budget / Envelopes]`, `[Totals]` | Presentation Section Labels | **No** | `accounts.tsv` (type tags) or optional display config | Display labels and classifications should be driven by account type/group metadata rather than hardcoded string labels. |
| `src_next/cycle_summary.bqn:149-153` | `"収入合計"`, `"支出合計（含 負債返済）"`, `"収支"`, `"予定支出(残)"` | Presentation Row Labels | **No** | UI layer or display config | Multibyte row headers for summary layout should not be baked into the calculation engine. |
| `src_next/cycle_summary.bqn:159-165` | `"  ── 収入内訳 ──"`, `"  ── 支出内訳 ──"` | Presentation Section Headers | **No** | UI layer or display config | Headers are presentation styling. BQN should output structured data segments or plain indicators. |
| `src_next/planned_payments.bqn:170-190` | `"── 未了 ──"`, `"── 完了 ──"` | Presentation Table Dividers | **No** | UI layer or display config | Presentation layout structures. |
| `src_next/planned_payments.bqn:203-207` | `"future  : これから"`, `"due     : 今日が期限"`, `"overdue : 期限超過 ⚠"` | Status Legend Labels | **No** | UI layer or display config | Explanatory legend copy. |
| `src_next/calc/envelope_calc.bqn:75-82` | `"理想消化額:   "`, `"実消化額:     "`, `"超過額:       "`, `"判定:         "` | Presentation Labels | **No** | UI layer or display config | Calculation headers for interactive tool output. |
| `src_next/config.bqn:82-84` | `BUDGET_ID_OPENING`, `BUDGET_ID_UNASSIGNED`, `BUDGET_ID_SPENT` | Core Budget Account Names | **Yes** | `config.tsv` | Already externalized. The code queries config for dynamic values, which is the correct pattern. |
| `src_next/balances.bqn:29-33`, `src_next/ytd_summary.bqn:21-23`, etc. | `"assets:"`, `"liabilities:"`, `"budget:"`, `"income:"`, `"expenses:"` | Prefix Fallback | **No** | `accounts.tsv` (`role=` explicit tags) | Existing prefix fallbacks used to infer roles. Already marked for deprecation under `docs/ACCOUNT_ROLE_CONTRACT.md`. |
| `src_next/actual_comparison.bqn:333-340` | `"current : "`, `"baseline: "`, `"(前サイクル同時点)"` | Presentation Labels | **No** | UI layer or display config | Comparison headers and notes. |

---

## Key Takeaways

1. **Decouple Presentation Text**: BQN engine files currently contain raw Japanese strings for titles, row labels, and legends. Since BQN is now purely plain text (decoupled from colors in [feat: complete presentation-layer color-filter delegation](file:///Users/user/Projects/moko/bqn-ledger/tools/main-ui.sh)), the next step should strip these presentation strings from the calculation engine, leaving only semantic data keys.
2. **Preserve Math & Cube Constraints**: The core multidimensional cube aggregation (layer mapping, zero-sum checking, epoch-to-day conversion) is clean and correctly kept in-code.
3. **Prefix Fallback Phaseout**: Prefix checking is still pervasive for fallback role identification. Keeping it as-is for now is fine, but it remains the primary target for complete deprecation once `role=` is enforced.

---

## Next Steps

1. Review these audited assumptions with the user.
2. Update [TODO.md](file:///Users/user/Projects/moko/bqn-ledger/TODO.md) to log this audit phase as complete.
3. Formulate the concrete implementation plan for Phase 1 (budget group contract clarification) and Phase 2 (decoupling BQN labels).
