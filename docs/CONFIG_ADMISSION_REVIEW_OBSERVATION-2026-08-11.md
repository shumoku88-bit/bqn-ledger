# Legacy aggregate config admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review main: `79e572d5c91daec89cf196c8e103fefd17367129`
- owner: `src/ledger/config_admission.bqn`
- normal Phase 2 cursor after the companion-admission seam review

## Reachability first

`config_admission.bqn` is a strict aggregate admission owner for the older `config.tsv` contract. It parses a wide set of source, cycle, policy, group, currency, and report keys into one validated result.

Repository reachability no longer supports treating that aggregate owner as the live application configuration architecture.

An exact import search for `src/ledger/config_admission.bqn` reaches the focused `tests/test_ledger_config_cycle_admission.bqn` qualification. No current `src/application`, `src/report`, `src/editor`, or `src_edit` consumer imports this owner.

The focused test still reads `fixtures/ledger-facts-phase1-proof/config.tsv`, couples the old config owner to `cycle_admission.bqn`, and asserts old aggregate fields such as source basenames, cycle mode/length, Budget style, Account groups, default currency, and report currency.

## Current application configuration shape

Current application code uses narrower configuration owners instead of the aggregate ledger admission surface.

`src/application/config_rows.bqn` provides a bounded key/value row representation. Active owners import it only for the configuration fields they actually own.

Examples:

- `src/application/system_defaults.bqn` reads `config/system_defaults.tsv` and owns repository default filenames;
- `src/application/editor_currency.bqn` combines `config_rows` with the canonical currency registry, using `DEFAULT_CURRENCY` only as an editor selection/default rather than source accounting evidence;
- canonical Report policy and configurable Actual-source ownership were split into dedicated canonical owners during the canonical Household recovery work rather than remaining fields of one aggregate config result.

This is a more local responsibility structure than rebuilding the old all-purpose `config_admission` as the center of current runtime configuration.

## Historical direction

The repository history around the canonical recovery confirms continued responsibility subtraction from the old config shape:

- Report configuration moved to canonical Report policy ownership;
- Actual source selection became canonical/configurable source ownership;
- canonical Household source/configuration owners were introduced by responsibility rather than preserving one monolithic `config.tsv` semantic object.

The old aggregate owner remains useful only as qualification evidence for older fixtures/contracts while those surfaces still exist.

## Classification

Treat `src/ledger/config_admission.bqn` as a **legacy/qualification aggregate-config seam**, not as a current canonical configuration owner.

Its visible row loop and repeated key checks therefore should not be rewritten merely to make an obsolete aggregate contract more BQN-native.

In particular, do not:

- convert the entire old `config.tsv` schema into a new dense-array kernel;
- extract generic configuration/parser abstractions from this owner;
- route current narrow application owners back through the aggregate result;
- use this review to reintroduce retired source/report ownership into `config.tsv`.

## Retirement boundary

Eventual removal should be coordinated with the evidence that still depends on the old aggregate shape, especially:

- `tests/test_ledger_config_cycle_admission.bqn`;
- `fixtures/ledger-facts-phase1-proof/config.tsv`;
- any remaining old config/cycle proof documentation or checks;
- old source/report keys whose canonical owners have already moved elsewhere.

That belongs to legacy-source/repository-reachability retirement, where the surviving qualification contract can be removed coherently rather than piecemeal.

## Protected behavior until retirement

While this seam remains, its focused qualification still protects old-contract behavior including:

- strict required/duplicate/unsupported key admission;
- source basename and cycle-field validation;
- Budget style and Account-group parsing;
- currency and report-currency registry checks;
- deterministic diagnostics;
- fail-closed result publication.

No runtime or test change is selected by this review.

## Review decision

`src/ledger/config_admission.bqn` is reviewed on main `79e572d5c91daec89cf196c8e103fefd17367129` as a legacy/qualification seam.

Do not invest in a local array refactor. Delegate eventual removal with the old aggregate config fixture/qualification evidence to the legacy/reachability closeout.

The normal Phase 2 cursor may advance to `src/ledger/currency_registry.bqn`, which is a live canonical owner and should be reviewed on its own current consumer graph.
