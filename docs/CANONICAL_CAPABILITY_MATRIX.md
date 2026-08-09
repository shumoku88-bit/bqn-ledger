# Canonical daily-use capability matrix

Status: current recovery inventory

Scope: historical implemented surfaces, current owners, and the canonical eight-file Command Hub
Baseline reviewed: `main` at `399088cb480031ce085ec3b1223d2733119852e0`

## Authority and classification

The only Household runtime authority in this matrix is:

`accounts.journal`, `actual.journal`, `plan.journal`, `budget.journal`, `budget.toml`, `household.toml`, `report.toml`, and `issues.tsv`.

Repository `config/currencies.tsv` is application configuration, not a ninth Household source. Historical TSV and travel-event files are evidence only and are not Command Hub fallback inputs.

Classification numbers mean:

1. currently usable;
2. recovered, but hard to reach from the UI;
3. internal capability remained but disappeared from Command Hub;
4. removed during migration;
5. legacy-TSV-only and needs a canonical form;
6. intentionally retired;
7. replaced by a better current capability.

“Private verified” records only safe PASS evidence already established during canonical recovery. It never records private values. “Hub” describes `tools/bl` after this recovery.

## Daily recording and source lifecycle

| Capability | Historical evidence | Historical owner | Current owner | Current status | Hub | 8-file only | Private verified | Class | Recovery required | Recovery action |
|---|---|---|---|---|---:|---:|---:|---:|---:|---|
| Ordinary expense | `tools/add-ui.sh`; editor checks; PR #571 | add UI + monolithic editor | `tools/add-ui.sh` → `tools/edit journal add` → canonical Actual writer | usable | yes, Record | yes | yes, disposable copy | 2 | yes | expose named Record route |
| Income | same implemented two-Posting path and historical mode list | add UI + editor | same canonical Journal owner | usable | yes, Record | yes | yes, disposable copy | 2 | yes | expose named route |
| Asset transfer / move | historical `move` mode and checks | add UI + editor | same canonical Journal owner | usable | yes, Record | yes | yes, disposable copy | 2 | yes | expose named route |
| Multi-Posting Actual | `check-edit-bqn-journal-block-add.sh`; `check-edit-bqn-journal-add.sh`; PR #571 | native Journal editor | `tools/add-ui.sh multi` → `tools/edit journal multi-add` | usable | yes, Record | yes | yes, disposable copy | 2 | yes | expose named route; preserve Posting order and exact zero sum |
| Reverse / correction | `check-edit-bqn-journal-reverse.sh`; no destructive editor history | native reverse owner | `src_edit/journal_native_reverse_cmd.bqn` through editor writer | usable | yes, Record | yes | yes, disposable copy | 3 | yes | selection route; keep compensating transaction boundary |
| Journal history | `check-edit-bqn-journal-list.sh` | editor read export | `src_edit/journal_list_cmd.bqn` | usable but hidden | yes, Record and `journal list` | yes | yes, read trial | 3 | yes | expose text route directly |
| Journal metadata | `JOURNAL_META.md`; journal-block checks | editor candidate renderer | `src_edit/journal_block_add_cmd.bqn` | usable through Record forms / low-level CLI | yes through writer UI | yes | yes for retained daily workflows | 1 | no | retain owner; Hub does not interpret metadata |
| Durable transaction identity | identity inventory and reconstructible-cleanup checks | Journal editor identity owners | canonical Actual admission and writer owners | usable | indirectly | yes | yes | 1 | no | preserve; no Hub identity generation |
| Identity inventory / canonical cleanup | dedicated `journal identity-inventory`, cleanup, canonical-surface checks | editor operations | dedicated `src_edit` commands | supported maintenance CLI, not daily UI | no | yes | not required | 1 | no | keep advanced CLI; do not crowd daily Hub |
| Destructive Journal edit/delete | historical write-scope plans classify it candidate/forbidden; no implemented daily owner | none | none | intentionally absent | no | n/a | n/a | 6 | no | correction remains reverse/compensating entry |
| Account list and filters | `check-edit-bqn-account-list.sh` | editor Account export | `src_edit/account_list_cmd.bqn` | usable but hidden | yes, Accounts | yes | yes, read trial | 3 | yes | expose list; retain role/currency options for direct CLI |
| Account add | Account writer checks; PR #564/#571 | editor Account append | canonical Account writer through `tools/add-ui.sh` | usable | yes, Accounts | yes | yes, disposable copy | 2 | yes | expose selection UI; no debt-specific semantics |
| Budget movement | Budget writer series #569/#570 and focused checks | Budget editor | `tools/budget-write` + BQN candidate owner | usable | yes, Budget | yes | yes, disposable copy | 2 | yes | expose named route |
| Plan → Budget sync | `check-edit-bqn-plan-budget-sync.sh`; Plan Finish integration | editor sync command | `tools/budget-write` / `src_edit/plan_budget_sync_cmd.bqn` | usable during completion and direct CLI | yes through Plan Finish | yes | yes, disposable copy | 1 | no | keep integrated flow; do not duplicate policy in Hub |
| Issue list | issue tracker plan and `check-edit-bqn-issue-close.sh` | issue editor | `src_edit/issue_list_cmd.bqn` | usable but hidden | yes, Issues | yes | yes, read trial | 3 | yes | expose separately from report |
| Issue add / close | issue editor checks | issue editor safe append/replace | `tools/lib/edit-bqn-issue.sh` via add UI | usable | yes, Issues | yes | yes, disposable copy | 2 | yes | expose lifecycle routes and selection |

## Plans

| Capability | Historical evidence | Historical owner | Current owner | Current status | Hub | 8-file only | Private verified | Class | Recovery required | Recovery action |
|---|---|---|---|---|---:|---:|---:|---:|---:|---|
| Open / all Plan list | `UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md`; plan-list checks | editor Plan rows | `src/application/editor_plan_rows.bqn` + `src_edit/plan_list_cmd.bqn` | usable but hidden | yes | yes | yes, read trial | 3 | yes | expose Open and All views |
| Overdue / upcoming | plan temporal-status tests and editor checks | BQN temporal owner | `src/accounting/plan_temporal_status.bqn` via plan list | usable but hidden | yes | yes | yes, read trial | 3 | yes | pass explicit local-day coordinate; no shell date classification |
| Related Plans | `check-edit-bqn-plan-related.sh`; relation contract in editor guide | editor relation owner | `src_edit/plan_related_cmd.bqn` | usable but required opaque selector | yes, selection-based | yes | yes through recurrence workflow | 3 | yes | select an open Plan, then call BQN relation owner |
| Plan add | PR #566/#571 and focused checks | Plan editor | dedicated canonical `tools/plan-add` writer | usable | yes | yes | yes, disposable copy | 2 | yes | expose named route |
| Plan date/amount edit | PR #567/#571 and checks | Plan editor | dedicated canonical `tools/plan-edit` writer | usable | yes, selection-based | yes | yes, disposable copy | 2 | yes | retain narrow editable fields |
| Finish / completion | PR #568/#571 and checks | completion editor | `tools/plan-finish` plus replenish UI | usable | yes, selection-based | yes | yes, disposable copy | 2 | yes | expose Finish route |
| Recurrence replenishment (`recur`, `series`, `anchor`, `offset`) | relation/replenishment checks; PR #571 | editor relation and replenish UI | BQN relation owner + `plan-finish-replenish-ui.sh` | usable | yes through Finish | yes | yes, disposable copy | 1 | no | keep integrated, no shell reimplementation |
| skip/cancel/stop-after/pause/resume/arbitrary account change | archived design inventories only; no qualified daily implementation | none | none | not an implemented historical daily surface | no | n/a | n/a | 6 | no | do not invent under recovery label |

## Retained reports

All rows are owned by the static catalog and current composition described in `REPORT_PORTFOLIO_CONTRACT.md`. Command Hub obtains labels and order from `tools/report-section-metadata`; it does not copy a report manifest.

| Capability | Historical evidence | Historical owner | Current owner | Current status | Hub | 8-file only | Private verified | Class | Recovery required | Recovery action |
|---|---|---|---|---|---:|---:|---:|---:|---:|---|
| `envelopes` | old Envelope ViewModel; retirement map | `src_next` envelope owner | `src/sections/envelope_backing.bqn` | retained replacement | yes | yes | yes, report trial | 7 | yes | route retained report |
| `balances` | old balances report | `src_next` balances owner | `src/sections/account_balances.bqn` | retained replacement | yes | yes | yes | 7 | yes | route retained report |
| `balance-sheet` | financial-statements contract | destination implementation | `src/sections/balance_sheet.bqn` | current | yes | yes | yes | 1 | yes | route retained report |
| `profit-and-loss` | financial-statements contract | destination implementation | `src/sections/profit_and_loss.bqn` | current | yes | yes | yes | 1 | yes | route retained report |
| `recent` | old recent report; retirement map | `src_next` recent owner | `src/sections/recent_journal.bqn` | retained replacement, multi-Posting aware | yes | yes | yes | 7 | yes | route retained report |
| `planned` | planned-payments contract | old/destination planned owner | `src/sections/planned_payments.bqn` | retained | yes | yes | yes | 1 | yes | route retained report |
| `cycle-accounts` | old Cycle + Trial Balance | two old report owners | `src/sections/cycle_accounts.bqn` | better bounded replacement | yes | yes | yes | 7 | yes | route retained report |
| `cycle-comparison` | old Actual Comparison | old comparison owner | `src/sections/cycle_comparison.bqn` | explicit-window replacement | yes | yes | yes | 7 | yes | route retained report |
| `monthly-accounts` | old YTD + Daily Trend portions | old report owners | `src/sections/monthly_accounts.bqn` | explicit month-range replacement | yes | yes | yes | 7 | yes | route retained report |
| `daily-flow` | implemented date/Account report; final P1 contract retains it despite an earlier provisional retirement note | old and destination flow owners | `src/sections/daily_flow.bqn` | retained current report | yes | yes | yes | 1 | yes | trust current 12-key contract, not provisional nine-key text |
| `daily-target` | Outlook/capacity replacement contract | old Outlook owner | `src/sections/daily_target.bqn` | conservative retained replacement | yes | yes | yes | 7 | yes | route retained report |
| `issues` report | old Issues report and strict destination contract | old report owner | `src/sections/issues.bqn` | retained read report | yes | yes | yes | 7 | yes | keep report and editor lifecycle as distinct routes |
| Snapshot, YTD, Cycle Summary, Trial Balance route, Check report, Outlook, Daily Trend, Actual Comparison, Debug report | `REPORT_SURFACE_RETIREMENT_MAP.md` | retired `src_next` sections | retained reports or operational tools above | intentionally removed/replaced | no aliases | yes | covered by replacements | 7 / 6 | no | never restore old keys or cache bodies |

## Browse and operations

| Capability | Historical evidence | Historical owner | Current owner | Current status | Hub | 8-file only | Private verified | Class | Recovery required | Recovery action |
|---|---|---|---|---|---:|---:|---:|---:|---:|---|
| Household readiness | retirement map: Check report → operation; operational checks | old report `check`, then operation | `tools/ledger-check` + `src/application/ledger_check_cli.bqn` | current but Hub called developer suite | yes, `check` | yes | yes, private root PASS | 3 | yes | replace `tools/check.sh` route with strict source admission |
| Ledger inspection | Debug report retirement map | old Debug report | `tools/ledger-inspect` | current but hidden | yes | yes | yes, bounded structural trial | 3 | yes | expose operation, not report |
| Doctor | canonical doctor checks | shell doctor | `tools/doctor` | current but hidden | yes | yes | yes | 3 | yes | pass selected base through `LEDGER_DATA_DIR` |
| hledger export | converter history and PR #571 | compatibility converter | canonical-only `tools/to-hledger` | current but hidden | yes | yes | yes, disposable output | 3 | yes | expose one-way export |
| Direct canonical source edit | historical Hub editor menu | Hub editor launcher | `$EDITOR` over fixed canonical file menu | usable | yes | yes | user-directed only | 1 | no | retain eight-file allowlist |
| Report summary / exact query | report reset checks | summary/query tools | `tools/report-summary`, `tools/query` | current advanced CLI | yes, Operations direct routes | yes | not separately required | 2 | yes | expose without parsing output |
| Report cache | cache checks and architecture | cache tool | `tools/report-cache` / Command Hub cache refresh | used automatically by report UI | indirect | yes | yes through reports | 1 | no | keep automatic; no second cache owner |
| Repository development suite | repository check history | `tools/check.sh` | `tools/check.sh` | current developer-only command | advanced `dev-check` only | repository, not Household | CI PASS | 1 | no | keep distinct from `bl check` |

## Separate and intentionally unresolved historical surfaces

| Capability | Historical evidence | Historical owner | Current owner | Current status | Hub | 8-file only | Private verified | Class | Recovery required | Recovery action |
|---|---|---|---|---|---:|---:|---:|---:|---:|---|
| Ordinary ILS Journal expense, `trip-id`, `payment` | Israel editor guide and vertical-slice checks | ordinary Journal editor | canonical Journal writer/metadata admission | valid generic canonical capability | via ordinary Record path | yes | not part of this trial | 1 | no | retain as ordinary multi-Commodity Journal semantics |
| JPY↔ILS exchange event | travel exchange checks | dedicated travel TSV editor | `src_edit/travel_exchange_add_cmd.bqn` | implemented experiment outside Household authority | no | **no** | no | 5 | unresolved | do not add a ninth source or silently retire; future explicit decision required |
| Friend-paid ILS pending event | friend travel checks | dedicated travel TSV editor | `src_edit/travel_friend_add_cmd.bqn` | implemented experiment outside Household authority | no | **no** | no | 5 | unresolved | same boundary; not part of canonical recovery |

## Recovery conclusion

The implemented daily capabilities were not missing accounting kernels; they were fragmented behind editor and operational command names. `tools/bl` now routes the complete retained daily surface while all semantic decisions remain in existing BQN/application/writer owners. No legacy source basename, dual read/write, destructive Journal operation, debt classification, or travel source was added.
