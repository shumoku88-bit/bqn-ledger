# Canonical Household source recovery Phase 0 — evidence

Status: local verification complete; PR remains Draft pending maintainer Ready decision

Roadmap: PR #550
Implementation: PR #551

## Verified revisions

Local verification was performed from detached temporary worktrees with no edits to existing worktrees.

- `origin/main`: `e35203c856ef27fed52dfe955825472104823198`
- initial Phase 0 head: `ac3b051562aadeaf57e2d99f955bbb302b5bd4f3`
- first updated-head rerun: `ee801d4c640775368de6f0d353982101d572af4c`
- second updated-head rerun: `5419f95a69b84408234f32dd467825a5f51f271b`
- final green updated-head rerun: `bf6707ceefc16bce6ad4a1de7070320838ce496f`

## Baseline result

The current remote `main` baseline is healthy:

- `tools/check.sh`: PASS
- `checks/check-current-report-profile.sh`: PASS

Therefore canonical source recovery does not require a pre-migration baseline-repair PR.

The canonical source topology shell check and `git diff --check` remained green throughout Phase 0 verification.

## BQN role corrections found by executable verification

The initial Phase 0 branch failed in the new `tests/test_application_canonical_household_sources.bqn` assertion. The failure was a BQN train parse error in redundant count assertions after the exact ordered-list equality contract. Those redundant assertions were removed rather than replaced with more syntax.

The first updated-head rerun at `ee801d4c640775368de6f0d353982101d572af4c` then exposed a source-owner error: canonical basenames are Subject values, but the implementation assigned string Subjects directly to uppercase identifiers such as `Accounts`, which BQN assigns a Function role.

That implementation was changed to lowercase Subject locals. The second updated-head rerun at `5419f95a69b84408234f32dd467825a5f51f271b` correctly showed that the remaining uppercase export fields such as `Accounts⇐accounts` still violate the same role rule. An uppercase namespace field is itself Function-role; it cannot directly hold a Subject value.

Repository examples confirm the correct distinction: Function exports use uppercase Function-role names such as `Parse`, while Subject-valued namespace fields use lowercase names such as `state`, `coefficient`, or `value`.

The canonical source owner now follows that native BQN shape end to end:

- lowercase Subject locals;
- lowercase Subject namespace fields: `accounts`, `actual`, `plan`, `budget`, `budgetPolicy`, `householdPolicy`, `reportPolicy`, `issues`, `basenames`;
- no compatibility wrapper or Function-valued getter is introduced merely to preserve an unused uppercase field shape.

Only the new Phase 0 test referenced the earlier uppercase field names, so changing the new namespace surface introduces no production caller migration.

## Final updated-head verification

The final rerun at `bf6707ceefc16bce6ad4a1de7070320838ce496f` passed all required checks:

- `bqn tests/test_application_canonical_household_sources.bqn`: PASS, exit 0;
- `bash checks/check-canonical-household-source-topology.sh`: PASS, exit 0;
- `NO_COLOR=1 tools/check.sh`: PASS, exit 0;
- `git diff --check`: PASS, exit 0;
- final temporary worktree status: clean.

No failure diagnostic remained.

## Legacy source families

Repository-wide local search found 1,492 matching lines across the nine legacy basename patterns. The migration meaning clusters into these source families:

| Legacy source | Confirmed production ownership | Retirement target |
| --- | --- | --- |
| `accounts.tsv` | Account admission, editor account read/write, Actual editor verification, hledger conversion | after canonical Account and all downstream consumers no longer require it |
| `plan.tsv` | Plan snapshot/admission, Plan editor lifecycle, planned-report and Plan-dependent application paths | Phase 3+ |
| legacy Budget allocation TSV | retired; canonical read/write and Plan sync use `budget.journal` | complete |
| `cycle.tsv` | Cycle admission and cycle-resolution application paths | Phase 5+ |
| `daily_target_scope.tsv` | Daily Target scope admission | Phase 5+ |
| `config.tsv` | legacy ledger/application configuration and local system-default discovery | after canonical root/policy/application discovery replaces it |
| `report_manifests.tsv` | report manifest configuration, source routing, Command Hub/report application configuration | Phase 6+ |
| `report_all_human.tsv` | human report suite request manifest | Phase 6+ |
| `report_all_compact.tsv` | compact report suite request manifest | Phase 6+ |

Tests, fixtures, current documentation/defaults, and archived historical documentation contain additional references. These are not alternate canonical owners. They must be updated or retired in the same phase as the corresponding production path, while genuinely archived historical records may retain historical names when clearly marked as such.

## Confirmed representative owners

The local inventory confirmed these production-relevant paths among the legacy references:

### Accounts

- `src/ledger/account_admission.bqn`
- `src_edit/account_add_cmd.bqn`
- `src_edit/account_list_cmd.bqn`
- `src/application/editor_actual.bqn`
- `tools/to-hledger`

### Plan

- `src/ledger/plan_snapshot.bqn`
- `src_edit/plan_add_cmd.bqn`
- `src_edit/plan_edit_cmd.bqn`
- `src_edit/plan_finish_cmd.bqn`
- `src/sections/planned_payments.bqn`
- `tools/plan-finish-replenish-ui.sh`

### Budget

- `src/accounting/envelope_backing.bqn`
- `src_edit/plan_budget_sync_cmd.bqn`

### Cycle

- `src/ledger/cycle_admission.bqn`
- `src/accounting/cycle_income_anchor_resolution.bqn`

### Daily Target

- `src/application/daily_scope_admission.bqn`

### Config

- `src/ledger/config_admission.bqn`
- `tools/lib/system-defaults.sh`

### Report manifests

- `src/application/report_manifest_config.bqn`
- `src/application/report_source_adapter.bqn`
- `tools/main-ui.sh`

This list identifies migration owners, not every test/fixture/document occurrence. Repository-wide retirement checks must still search the full tree for the corresponding basename before each deletion gate is declared complete.

## Executable tool surface

Local inventory found 26 executable files under top-level `tools/`.

The retained user/application surface includes the unified CLI/TUI, editing, ledger checking/inspection, report/query commands, and Plan completion workflow. Operational/development tools and internal helpers remain supported where they are required by those surfaces.

`tools/to-hledger` is the only tool currently classified as `candidate for retirement / unclear`: it converts legacy Account/Plan TSV inputs to hledger Journal form, so its purpose must be re-evaluated once canonical Journal sources are native. Do not delete it before that explicit decision.

## Private canonical root

The filename-only private-root check was skipped because `HKERNEL_LEDGER_DATA_DIR` was not set in the verification environment. No private Household content was read or printed.

This does not block Phase 0 topology work. Private canonical smoke remains a gate for later reader cutovers before any legacy private file is deleted.

## Writer authority and production selection

The Phase 0 implementation changes neither writer authority nor production source selection. Its scope remains limited to:

- canonical basename ownership;
- synthetic canonical fixture files;
- topology verification;
- tests and verification instructions;
- recorded migration evidence.

No `src_edit` owner, production ledger reader, or report source adapter has been changed by this slice.

## Phase 0 conclusion

Phase 0 now has a healthy remote-main baseline, a canonical eight-file topology owner, a synthetic canonical root, an enforced topology guard, a recorded legacy-source/tool inventory, and a green full local suite at the final verified head.

This completes the executable evidence required for Phase 0 implementation. PR #551 remains Draft until the maintainer explicitly chooses Ready/merge.