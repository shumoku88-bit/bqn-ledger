# bqn-ledger capability recovery matrix — 2026-08-09

Status: active recovery audit

Repository baseline: `main@399088cb480031ce085ec3b1223d2733119852e0`

Historical comparison baseline: `e35203c856ef27fed52dfe955825472104823198`, the migration-start baseline recorded by PR #550, supplemented by archived editor/report design inventories and current checks.

Canonical Household authority is exactly:

`accounts.journal`, `actual.journal`, `plan.journal`, `budget.journal`, `budget.toml`, `household.toml`, `report.toml`, `issues.tsv`.

Classification: 1 = usable now; 2 = restored but weakly discoverable; 3 = retained internal capability missing from Hub; 4 = removed and needs restoration; 5 = depends on noncanonical source and needs canonical replacement; 6 = intentionally retired; 7 = superseded by a stronger retained capability; N = proposal/candidate only, not evidence of a previously usable feature; D = separate open work.

## Actual / Journal

| Capability | Past evidence | Current owner | Hub on audited main | Canonical-only | Real-data / executable evidence | Class | Recovery |
|---|---|---|---|---|---|---:|---|
| Expense | historical Add UI | `add-ui.sh` → canonical Actual writer | yes | yes | PR #571 + CI | 1 | keep |
| Income | historical Add UI | `add-ui.sh` → canonical Actual writer | yes under Add | yes | ordinary Actual qualification + CI | 1 | keep |
| Transfer / move | historical Add UI | `add-ui.sh` → canonical Actual writer | yes under Add | yes | ordinary Actual qualification + CI | 1 | keep |
| 2-Posting transaction | historical editor | `journal add` / shared block writer | yes | yes | PR #571 + CI | 1 | keep |
| 3+ Posting transaction | historical multi mode | `journal multi-add` | yes | yes | PR #571 three-Posting smoke + CI | 1 | keep |
| Reverse / cancellation | historical Add UI | `journal reverse` | yes under Add | yes | editor reverse checks | 1 | keep compensating model |
| Destructive Actual edit/delete | archived write-scope inventory marks candidate/forbidden | none | no | n/a | n/a | N | do not invent as recovery |
| Transaction list / inspection | retained editor read owner | `journal list` | no direct browse | yes | `check-edit-bqn-journal-list.sh` | 3 | expose through Hub browse |
| Recent transactions | retained report | `recent` report | yes | yes | PR #571 + CI | 1 | keep |
| Free-form search/filter | no implemented dedicated daily surface found | none | no | n/a | n/a | N | separate future design, not recovery |
| Account-specific history | no implemented dedicated daily surface found | none | no | n/a | n/a | N | balances/reporting remain available |
| Generic metadata input | historical/current writer | `journal add`, `journal-block add`, UI presets | yes for ordinary entry | yes | parser/writer checks | 1 | keep |
| receipt / note / party / tax / biz / invoice evidence | Journal metadata inventory | canonical transaction metadata | via generic metadata path | yes | parser/writer checks | 1 | preserve |
| Durable/imported identity write | historical/current explicit identity path | `journal-block add --identity durable` | no | yes | editor qualification | 3 | retain low-level, do not force IDs on ordinary Actuals |
| Ordinary identity-free Actual | stronger current replacement | shared canonical writer | yes | yes | PR #571 | 7 | preferred normal path |
| Identity inventory / cleanup maintenance | retained maintenance commands | `journal identity-inventory`, cleanup plan/apply | no | yes | repository checks | 3 | maintenance-only, not everyday Hub default |
| Ordinary travel purchase metadata | historical travel workflow | canonical Actual metadata | via normal Add/CLI | yes | checks | 1 | keep |
| Friend-paid travel pending event | specialized historical writer | `friend_travel_events.tsv` | no | **no** | public checks only | 5 | requires separate canonical lifecycle design |
| JPY↔ILS dedicated exchange event | specialized historical writer | `travel_exchange_events.tsv` | no | **no** | public checks only | 5 | same; do not bless extra Household authority |

## Plan

| Capability | Past evidence | Current owner | Hub | Canonical-only | Evidence | Class | Recovery |
|---|---|---|---|---|---|---:|---|
| List | implemented editor surface | `plan list` | no direct browse | yes | plan-list check | 3 | expose through Hub browse |
| Add | historical UI | canonical Plan writer | yes | yes | PR #571 + CI | 1 | keep |
| Edit date/amount | historical implemented scope | canonical Plan edit writer | yes | yes | PR #571 + CI | 1 | keep |
| Finish → Actual | historical lifecycle operation | canonical Plan finish workflow | yes | yes | PR #571 + CI | 1 | keep |
| Separate Complete / Advance commands | no separate stable commands required at baseline | finish + optional replenishment | yes as one workflow | yes | PR #571 | 7 | current combined workflow is stronger |
| `plan-id` provenance | historical/current relation | Plan/Actual admission | automatic | yes | PR #571 | 1 | keep |
| Recurrence metadata | historical Plan metadata | `plan.journal` metadata | automatic/edit path | yes | PR #571 + checks | 1 | keep |
| Next occurrence replenishment | lifecycle expectation, now implemented | Plan finish UI/workflow | yes | yes | PR #571 + live source progression | 1 | keep |
| Overdue handling | existing temporal selection | `plan list --temporal`, Add UI | yes | yes | plan-list checks | 1 | keep |
| Upcoming/all filtering | existing temporal selection | `plan list`, Add UI | yes | yes | checks | 1 | keep |
| Related Plans | retained helper | `plan related` | no | yes | plan-related check | 3 | retain workflow helper; optional future browse UX |
| Series | canonical metadata/relation | Plan admission | automatic | yes | PR #571 + checks | 1 | keep |
| anchor / offset | canonical recurrence evidence | Plan admission/replenishment | automatic | yes | PR #571 | 1 | keep |
| Daily Target relation | retained report/policy | canonical Plan/report composition | yes through report | yes | PR #571 + CI | 1 | keep |
| Plan → Budget sync | current qualified workflow | canonical Budget writer | automatic on finish / direct CLI | yes | PR #571 + CI | 1 | keep |
| Plan cancel/remove/skip/pause/resume | archived scope lists candidates, not implemented daily features | none | no | n/a | n/a | N | not a lost capability |

## Budget / Envelope

| Capability | Past evidence | Current owner | Hub | Canonical-only | Evidence | Class | Recovery |
|---|---|---|---|---|---|---:|---|
| Budget movement | historical UI | canonical Budget writer | yes | yes | PR #571 + CI | 1 | keep |
| Allocation / movement semantics | retained budget domain | `budget.journal` + policy | yes through Add/reports | yes | CI | 1 | keep |
| Spent transition / Actual integration | retained projection | report/accounting projection | reports | yes | CI | 1 | keep |
| Plan integration | retained workflow | Plan → Budget sync | automatic | yes | PR #571 | 1 | keep |
| Envelope balances | retained report | `envelopes` | yes | yes | PR #571 | 1 | keep |
| Backing, including multi-Commodity pool projection | retained domain | Budget/report projection | reports | yes | PR #571 | 1 | keep |
| Current allocation state | retained report | envelope report | yes | yes | CI | 1 | keep |
| Daily/flex/reserve policy display | retained Household/Budget policy | canonical TOML + reports | yes | yes | PR #571 + CI | 1 | keep |
| Cycle interaction | retained report composition | Household/report owners | yes | yes | CI | 1 | keep |
| Budget list command | archived candidate rather than stable feature | none separate | no | n/a | n/a | N | envelope report is current view |
| Budget edit/delete | candidate/needs-design only | none | no | n/a | n/a | N | do not invent as recovery |

## Accounts

| Capability | Past evidence | Current owner | Hub | Canonical-only | Evidence | Class | Recovery |
|---|---|---|---|---|---|---:|---|
| List | implemented editor read owner | `account list` | no direct browse | yes | account-list check | 3 | expose through Hub browse |
| Add | historical/current UI | canonical Account writer | yes | yes | PR #571 + CI | 1 | keep |
| Role | retained Account semantics | Account registry | selection/writer | yes | CI | 1 | keep |
| Commodity | canonical Account declarations | Account registry | selection/writer | yes | PR #571 + CI | 1 | keep |
| Hierarchical account names | historical colon namespaces | Account key | selectors | yes | CI | 1 | keep one authority |
| Balance | retained report | `balances` | yes | yes | PR #571 | 1 | keep |
| Selection/filter by role/currency/preference | current editor/UI | `account list` + Add UI | yes in workflows | yes | account-list check | 1 | keep |
| Legacy type/subtype Household classification | old Account TSV metadata | `household.toml` policy where applicable | policy/report | yes | Account writer rejects legacy classification | 7 | do not reattach policy to Account declarations |
| Account edit/delete | candidate/forbidden, not stable implemented feature | none | no | n/a | n/a | N | not recovery |
| Debt classification | separate open PR #546 | separate work | unchanged | n/a | Draft PR | D | do not overlap |

## Retained report portfolio

The migration-start catalog and current catalog both contain twelve production sections. PR #571's named smoke list was therefore not the full retained portfolio.

| Report | Current owner | Hub | Canonical-only | Evidence | Class |
|---|---|---|---|---|---:|
| Envelopes | report portfolio | yes | yes | PR #571 + CI | 1 |
| Balances | report portfolio | yes | yes | PR #571 + CI | 1 |
| Balance Sheet | report portfolio | yes | yes | full-report qualification + CI | 1 |
| Profit and Loss | report portfolio | yes | yes | full-report qualification + CI | 1 |
| Recent Transactions | report portfolio | yes | yes | PR #571 + CI | 1 |
| Planned Payments | report portfolio | yes | yes | PR #571 + CI | 1 |
| Current-cycle Accounts | report portfolio | yes | yes | full-report qualification + CI | 1 |
| Cycle Comparison | report portfolio | yes | yes | full-report qualification + CI | 1 |
| Monthly Accounts | report portfolio | yes | yes | full-report qualification + CI | 1 |
| Daily Flow | report portfolio | yes | yes | PR #571 + CI | 1 |
| Daily Target | report portfolio | yes | yes | PR #571 + CI | 1 |
| Issues & Decisions | report portfolio | yes | yes | full-report qualification + CI | 1 |

Historical report names should not be resurrected literally where a stronger retained surface replaced them: `snapshot` → Balances + Envelopes + Daily Target; `ytd` → Monthly Accounts; broad `cycle` → Current-cycle Accounts + Daily Target + Planned + Envelopes; production `trial-balance` → Current-cycle Accounts plus developer inspection; report `check` → `tools/ledger-check`; `outlook` → Daily Target + Envelopes; `daily-trend` → Monthly/Current-cycle/Daily Target; `actual-comparison` → Cycle Comparison; `debug` → `tools/ledger-inspect`; old destination aliases → exact `ledger_*` queries; old Household report manifests → static report catalog + canonical `report.toml`. `Daily Flow` remains retained despite an older archived retirement proposal.

## Issues / Decisions

| Capability | Past evidence | Current owner | Hub | Canonical-only | Evidence | Class | Recovery |
|---|---|---|---|---|---|---:|---|
| Issues report | retained report | `issues` report | yes | yes | CI | 1 | keep |
| Add | historical UI | issue editor | yes under Add | yes | CI | 1 | keep |
| Close | historical UI | issue editor | yes under Add | yes | CI | 1 | keep |
| List | implemented read owner | `issue list` | no direct browse | yes | editor checks | 3 | expose through Hub browse |

## Operational tools and Command Hub

| Capability | Past/current evidence | Current owner | Hub on audited main | Canonical-only | Evidence | Class | Recovery |
|---|---|---|---|---|---|---:|---|
| Canonical Household validation | retained operational replacement | `tools/ledger-check` | **no**; `bl check` ran repo suite | yes | PR #571 + CI | 3 | make `bl check` validate selected Household root |
| Repository development suite | historical Hub check route | `tools/check.sh` | yes but mislabeled | repo-level | CI | 2 | preserve as explicit `dev-check` |
| Doctor | retained tool | `tools/doctor` | no | yes | CI | 3 | expose through Hub |
| Actual/provenance inspection | retained debug replacement | `tools/ledger-inspect` | no | yes | CI | 3 | expose through Hub |
| Exact query | retained `ledger_*` contract | `tools/query` | no | yes | CI | 3 | add base-injecting direct Hub route |
| hledger export | canonical export | `tools/to-hledger` | no | yes | PR #571 + CI | 3 | expose through Hub |
| Direct source edit | historical Hub capability | `bl edit` | yes | yes | topology inspection | 2 | keep exactly eight files; remove stale TSV wording |
| Backup | writer boundary | safe-write path | automatic | yes | CI | 1 | keep automatic |
| Guarded rollback | writer boundary | safe-write path | automatic | yes | CI | 1 | keep automatic; no manual rollback UI invented |
| Stale fence / snapshot token | writer boundary | canonical writers | automatic | yes | PR #571 + CI | 1 | preserve |
| Complete-candidate admission | writer boundary | BQN admission + publication | automatic | yes | PR #571 + CI | 1 | preserve |
| Full report top-level menu entry | route already existed | `main-ui.sh report` | omitted interactively | yes | current routing | 2 | add explicit menu entry |
| Browse transactions/plans/accounts/issues | read owners already exist | editor read commands | absent | yes | focused checks | 3 | add one Hub browse submenu |
| Income/move/reverse/issues write modes | historical/current Add UI | Add UI + qualified writers | reachable under Add | yes | CI | 1 | no domain change |
| fzf/gum/plain fallback | historical/current Hub | shell UI | yes | n/a | current code | 1 | keep |

## Private canonical source state at audit time

The private Household repository was rechecked only for commit metadata and file topology. Its latest commit at audit time was `1a57d63bcb28e0a958e65d483dc8845fa39270a8`; all eight canonical files were present. Legacy TSV/report-manifest files were also still present as migration history. They are not runtime authority and are intentionally not deleted by this recovery slice. Private Household values are not reproduced here.

## First coherent recovery slice

This PR only reconnects already-qualified capabilities to the daily doorway: transaction/Plan/Account/Issue browsing, canonical `ledger-check`, doctor, Actual inspection, exact query, hledger export, full-report discoverability, canonical source-edit labels, and a focused read-only routing check. It preserves `tools/check.sh` as `dev-check`.

It does not change accounting calculations, Journal/Plan/Budget writers, exact arithmetic, identity, provenance, Posting order, Account resolution, Commodity semantics, writer authority, source snapshot ownership, stale fences, backup/rollback, complete-candidate admission, or report composition.

The clearest remaining nontrivial category-5 feature family is the specialized travel source-event path. Its two dedicated TSV files cannot be accepted as Household authority under the eight-file contract, so that work requires a separate canonical lifecycle decision rather than a routing shortcut.
