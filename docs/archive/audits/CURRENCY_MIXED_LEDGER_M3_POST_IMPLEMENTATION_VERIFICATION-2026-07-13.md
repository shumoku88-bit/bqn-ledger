# Currency Mixed-Ledger M3 Post-Implementation Verification — 2026-07-13

Status: audit snapshot
Owner: currency
Canonical: no; current runtime paths are `src_next/report.bqn`, `src_next/balances.bqn`, and their focused checks
Exit: retained as the evidence record that closes the selected M3 finite slice

## Scope

This docs-only review verifies the merged Currency Mixed-Ledger M3 human `balances` surface against the selected claims in `TODO.md` and the mixed-ledger daily-use plan. It does not authorize or implement strict-source enforcement, M4, another report section, JSON widening, FX, conversion, valuation, or a Currency axis.

Evidence labels used below:

- **Code**: inspected merged implementation or final diff; proves structure, not execution.
- **Execution**: command executed on merged `main` using committed synthetic fixtures or temporary copies; proves the exercised path only.
- **CI**: GitHub Actions result for the exact implementation head.

Classifications are `verified`, `partially verified`, `rejected`, or `not evidenced`.

## Merged implementation identity

- Implementation PR: [#204](https://github.com/shumoku88-bit/bqn-ledger/pull/204)
- Commits:
  - `366e432f51e2a45741c2438967b7b2c473799f44` — `feat: add M3 currency-selected balances`
  - `8fa9947b56e4f190569be7550c270f69d35d98d5` — `fix: enforce ILS balance display precision`
- Final PR head: `8fa9947b56e4f190569be7550c270f69d35d98d5`
- Merge commit: `ba4a02f28d4479bb5f92bf65a136dd7e16ada839`
- Merged at: 2026-07-13

## Changed paths summary

PR #204 changed 14 paths (436 insertions, 10 deletions):

- Runtime/CLI: `src_next/balances.bqn`, `src_next/report.bqn`, `tools/report`
- Focused evidence: `tests/test_src_next_balances.bqn`, `checks/check-currency-m3-balances.sh`, `tools/check.sh`
- Synthetic data: `fixtures/currency-m3-balances/`
- Contracts/routing: `docs/AI_CODEMAP.md`, `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`, and the mixed-ledger plan

No production source TSV path was in the implementation diff.

## Claim-to-evidence

| Claim | Result | Code evidence | Execution / CI evidence |
|---|---|---|---|
| Public `--currency JPY\|ILS` | verified | `report.bqn` parses `--currency`; `currency_setup.ResolveSelection` and `currency_selection.IsSupportedCurrency` close the domain. | Focused check executed explicit JPY and ILS CLI paths successfully. |
| No override uses `DEFAULT_CURRENCY` | verified | `balances.BuildSelected` calls `ResolveDefault` then `ResolveSelection`; fixture config declares JPY. | Focused check passed `Currency view: JPY (ledger default)`. |
| Explicit/default provenance is distinct | verified | `ResolveSelection` returns `explicit_selection` or `ledger_default`; `ProvenanceLabel` maps both locally. | BQN unit and CLI focused checks passed both paths. |
| `Currency view:` is visible | verified | `FormatSelectedHuman` constructs the line from the explicit carrier. | Explicit ILS and default JPY CLI output checks passed. |
| Existing checked selected-currency projection is reused | verified | `BuildSelected` loads one snapshot and calls `currency_selection.Build`; that seam builds row evidence once, filters it, then calls checked prepared projection. | `test_src_next_currency_selection.bqn` and full suite passed. |
| JPY/ILS accounts, postings, and totals are separated | verified | Selection filters row evidence before Posting IR/TBDS; AccountKey remains `(Account, Currency)`; balances use only selected posting rows. | Focused checks reject opposite-currency account leakage and assert separate asset/liability totals; currency-selection unit checks selected posting rows. |
| No cross-currency aggregation | verified | One selected projection feeds one period view; no coordinator combines domains. | JPY totals are 1200/-1200 and ILS totals are 12.55/-12.55 in focused synthetic evidence. |
| JPY integer display is preserved | verified | JPY presentation scale remains the checked calculation scale; legacy `FormatHuman` remains available. | Unit assertion renders coefficient 1200 as `1200`; focused JPY CLI totals remain integer-compatible. |
| ILS always displays two decimals | verified | `PresentationPolicy` fixes ILS presentation scale at 2 and keeps it distinct from calculation scale. | Unit and CLI integer, one-digit, and two-digit cases passed. |
| ILS source `12` renders `₪12.00` | verified | `FormatCoefficient` appends exact scale delta zeroes. | Temporary synthetic CLI fixture exited 0 and displayed `₪12.00`. |
| ILS source `12.5` renders `₪12.50` | verified | Calculation scale 1 is exactly raised to presentation scale 2. | Temporary synthetic CLI fixture exited 0 and displayed `₪12.50`. |
| ILS source `0.05` renders `₪0.05` | verified | Calculation and presentation scales are both 2. | Committed mixed fixture CLI and unit checks displayed `₪0.05`. |
| Negative ILS renders `-₪12.50` | verified | Formatter places sign before symbol. | Unit assertion and committed fixture liability output passed. |
| ILS precision above 2 fails without rounding | verified | `PresentationPolicy` returns error before `BuildPeriodView`/balances when calculation scale exceeds 2. | Source `1.234` exited 1 with the precision diagnostic; focused check asserted no balances header and no rounded `₪1.23`. |
| Unsupported selector is rejected | verified | Closed selector domain returns `unsupported_selected_currency`. | `--currency USD` failed nonzero with the expected diagnostic. |
| Invalid default is rejected | verified | `ResolveDefault` rejects missing, duplicate, empty, and unsupported values. | Focused CLI invalid-USD default failed; setup unit covers missing/duplicate/unsupported resolution. |
| Row/account currency mismatch is rejected | verified | `currency_selection.CheckAccountCurrency` checks both From and To before filtering/projection. | Focused temporary mismatch fixture failed nonzero. |
| Duplicate account currency metadata is rejected | verified | `BuildSelected` runs `currency_setup.AuditFile` before account resolution. | Focused temporary duplicate-account fixture failed nonzero. |
| `--currency` is rejected for full report, other section, list, cache, and JSON | verified | `report.bqn` has one pre-context guard limiting it to human `--section balances`. | All five focused negative CLI routes failed nonzero. |
| Existing balances JSON schema is preserved | verified | Selected dispatch excludes `--format json`; existing `balances.FormatJson` shape was not widened. | Focused check parsed JSON and asserted exact top-level keys `accounts` and `totals`; full report checks passed. |
| Production source was neither read nor changed | verified | PR #204 changed runtime, checks, docs, and synthetic fixtures only; no production TSV appears in its final diff. | This verification invoked only committed fixtures/temporary copies plus repository checks; it did not resolve or invoke the actual `LEDGER_DATA_DIR`. |
| Strict-source enforcement remains disabled | verified | PR #204 did not change missing-source compatibility in `context.bqn` or `account_key.bqn`; default selection is not source authority. | Existing legacy compatibility/unit/full checks passed. |
| Other sections, FX, conversion, valuation, and Currency axis remain out of scope | verified | Final diff adds selected dispatch only for human balances and contains no FX/conversion/valuation/Currency-axis implementation. | Guards reject other sections; full suite passed existing section contracts. |

All material M3 claims are verified. There are no partially verified, rejected, or not-evidenced material claims.

## Exact formatting evidence

Commands used temporary copies of `fixtures/currency-m3-balances`; values below are synthetic.

```text
integer source=12 exit=0
assets:ils-main/ILS               |         ₪12.00
liabilities:ils-main/ILS          |        -₪12.00

one_decimal source=12.5 exit=0
assets:ils-main/ILS               |         ₪12.50
liabilities:ils-main/ILS          |        -₪12.50

three_decimal source=1.234 exit=1
ERROR: ILS source precision exceeds 2 fractional digits: calculation scale 3
```

Committed mixed-fixture selected output also showed:

```text
Currency view: ILS (explicit selection)
assets:ils-main/ILS               |         ₪12.50
assets:ils-small/ILS              |          ₪0.05
liabilities:ils-main/ILS          |        -₪12.50
assets_total                      |         ₪12.55
liabilities_total                 |        -₪12.55
```

## Fail-closed evidence

`bash checks/check-currency-m3-balances.sh` passed all focused paths, including:

- ILS three-decimal source: exit 1, explicit precision diagnostic, no rounded balance output;
- unsupported selector;
- invalid ledger default;
- row/account mismatch;
- duplicate account currency metadata;
- full report, other section, list, cache, and selected JSON guards.

No failure was hidden by rerunning: every required command passed on its first verification invocation.

## Regression and execution evidence

Executed on the merged implementation before docs edits:

```text
bqn tests/test_src_next_balances.bqn          PASS
bqn tests/test_src_next_currency_selection.bqn PASS
bqn tests/test_src_next_currency_setup.bqn     PASS
bash checks/check-currency-m3-balances.sh       PASS
rtk bash ./tools/check.sh                       PASS (all 5 phases)
rtk tools/coverage                              PASS / exit 0
```

Coverage inventory reported 47 `src_next` modules and 58 matching `test_src_next_*.bqn` files. Existing src_edit inventory remained 9/16 covered; that unrelated inventory is not an M3 completeness metric.

## CI evidence

GitHub Actions workflow `check`, run number **743**:

- database run ID: `29227868446`
- head SHA: `8fa9947b56e4f190569be7550c270f69d35d98d5`
- status: completed
- conclusion: success
- URL: <https://github.com/shumoku88-bit/bqn-ledger/actions/runs/29227868446>

This CI result is tied to the final implementation head, including the ILS precision fix.

## Privacy and production-source boundary

The review used only repository synthetic fixtures and temporary copies. It did not read, print, migrate, or modify the actual production ledger or actual `LEDGER_DATA_DIR`; no private path, row, or amount is recorded here. Repository `data/` references reached by the standard full suite are the documented public sandbox, not production source.

## Plan/runtime alignment

The selected M3 claims match the merged runtime. The active plan still contained explicitly pre-implementation “current facts” and “future surface” prose after implementation; this verification marks that prose as historical design context and changes the plan to an active backlog. No runtime mismatch remains for the selected M3 contract.

M3 completion does not select strict-source enforcement or M4. Both remain independent candidates.

## Final conclusion

**Verified.** PR #204 satisfies every material selected M3 claim, including the follow-up fixed-two-decimal ILS precision contract. M3 may close in `TODO.md`. No next finite slice is selected.
