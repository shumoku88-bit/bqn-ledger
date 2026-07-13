# Currency Mixed-Ledger M2 Post-Implementation Verification

Date: 2026-07-13

Implementation PR: #198

Merged commit: `ea02a9deca8f4ed61c3556faf03cf2a1907f5e62`

Final executable evidence: GitHub Actions run #730

## Verdict

M2 is **verified**. The merged implementation satisfies the selected editor-input slice without widening into production migration, reports, FX, valuation, a Currency axis, or mixed-currency aggregation.

## Claim-to-evidence review

| Claim | Status | Evidence |
|---|---|---|
| `account add` accepts a supported currency and writes explicit metadata | verified | Default JPY and explicit ILS account-add checks assert exact `currency=` output. |
| `account list` composes role and currency filters | verified | Focused shell checks prove JPY and ILS candidates do not leak across the selected currency domain. |
| `journal add` accepts default or explicit currency selection | verified | Default JPY and explicit ILS journal checks pass through the public editor wrapper. |
| Every new account and journal row carries explicit currency metadata | verified | Exact appended and preview rows include `currency=JPY` or `currency=ILS`, including default-selected JPY. |
| Ledger default is only the initial selection | verified | Explicit ILS safely overrides `DEFAULT_CURRENCY=JPY`; source metadata is still written explicitly. |
| From and To account currencies must match the selected currency | verified | Mixed JPY/ILS account input fails before source write or backup creation. |
| Exact decimal source text is preserved | verified | JPY `12.34`, ILS `12.50`, and ILS `0.05` remain byte-visible in the generated row. |
| ILS accepts at most two fractional digits without rounding | verified | `1.234` and lexical `1.000` are rejected; no source or backup mutation occurs. |
| Manual `currency=` metadata cannot create a second authority | verified | `--meta currency=ILS` is rejected when currency is supplied through the selection boundary. |
| Existing non-journal editor paths remain integer-only and unchanged | verified | Existing budget, plan, issue, reverse, and account/journal regression checks remain green. |
| Existing MCP receipt entry remains operational | verified | MCP core and transport tests pass 10/10; MCP remains explicitly JPY-only rather than becoming a mixed-currency client. |
| Production source data was not migrated | verified | PR #198 contains editor, fixture, test, check, demo config, and MCP compatibility changes only. No actual `LEDGER_DATA_DIR` source was supplied or rewritten. |
| Repository checks remain green | verified | Final normal-workflow run #730 passed `tools/check.sh` and `tools/coverage`. |

## Final diff boundary

The final base-to-head diff contained 17 paths. Temporary one-shot patch helpers and diagnostic workflow changes were absent.

The implementation changed only:

- BQN editor validation, rendering, and account/journal command adapters;
- the public shell dispatcher arguments for the selected M2 commands;
- focused unit, fixture, and shell checks;
- demo/default configuration needed by the checked editor path;
- MCP call sites and expectations required to retain the existing explicit-JPY receipt contract.

## Defects found and closed by CI

CI exposed three integration defects before merge:

1. fractional-digit counting was affected by BQN right-binding and initially misclassified a one-digit fraction;
2. MCP called the widened BQN commands with the old arity and needed an explicit JPY client boundary;
3. a strict-shell test helper referenced a local variable inside the same declaration under `set -u`.

All three were fixed before final run #730.

## Safety review

Still intentionally absent:

- mutation of the user's existing ledger source;
- automatic application of the M1.5 migration preview;
- strict rejection of all historical missing currency metadata;
- plan, budget, or issue multi-currency editor work;
- currency-selected reports or human `₪` formatting;
- FX, conversion, valuation, a Currency axis, or cross-currency totals.

## Routing decision

M2 is closed.

The next finite checkpoint is **M2.5: Production JPY Source Migration and Strict-Source Checkpoint**. It is operational rather than a broad implementation campaign:

1. run the read-only audit against the actual `LEDGER_DATA_DIR`;
2. review the exact dry-run proposal;
3. only after explicit approval, apply `currency=JPY` to missing existing JPY source metadata through a safe-write boundary;
4. run post-migration checks and confirm new editor writes remain explicit;
5. decide strict missing-currency behavior separately.

M2.5 does not authorize M3 balances/report work, and this verification PR does not touch production data.
