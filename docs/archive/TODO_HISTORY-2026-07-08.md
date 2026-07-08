# TODO History - 2026-07-08

Status: Historical snapshot moved from `tasks/todo.md`.

Original date: 2026-06-15

## Plan

- [x] Repair `config.bqn` exports for special budget account settings.
- [x] Make `core.InitAccounts` accept one explicit configuration contract.
- [x] Update all production callers and remaining budget special-name handling.
- [x] Add focused tests for config loading and custom budget account names.
- [x] Update `docs/GENERALIZATION_TODO.md` to match the implemented scope.
- [x] Run focused tests and `./tools/check.sh`.
- [x] Review the final diff for unrelated or incomplete changes.
- [x] Repair the pre-existing fixed-cycle empty-anchor regression discovered by `./tools/check.sh`.
- [x] Fix the UI-triggered no-argument `export-next-cycle` path and add it to `check.sh`.

## Review

- `config.bqn` now exposes required function-role accessors for all budget settings.
- `core.InitAccounts` uses the explicit contract `⟨path, spent_name, budget_prefix⟩`.
- Production budget-prefix and special-account consumers use config-derived values.
- Added custom `env:` account tests and a fixed-cycle empty-anchor regression test.
- Verification: `bqn tests/test_config.bqn`, `bqn tests/test_core.bqn`,
  `bqn tests/test_cycle.bqn`, and `./tools/check.sh` all pass.
- Final review found no remaining production hardcodes for the configured budget
  prefix or special budget account names.
- The interactive report picker no longer fails when `ai-next-cycle` invokes
  `tools/export-next-cycle.bqn` without an explicit date.

## 2026-06-15 Generalization Plan Review

- [x] Review Phase 2 and Phase 3 against the repository's daily-use goals.
- [x] Record the recommendation without treating it as moko's final decision.
- [x] Define concrete conditions for reconsidering broader generalization.

### Review

- Recommend holding Phase 2 rather than adding duplicate `role=` metadata now.
- Recommend narrowing Phase 3 to auditing and completing the existing `--base`
  contract.
- Final direction remains pending moko's decision.

## 2026-06-15 Lifestyle Configuration Plan Revision

- [x] Record moko's requirement that future lifestyle changes should normally
  require configuration changes, not code-wide edits.
- [x] Replace the generic-engine goal with a lifestyle-configurable household
  accounting core.
- [x] Restore account-role migration as a staged, backward-compatible plan.
- [x] Add a base-aware Context phase and multiple-lifestyle fixture criteria.
- [x] Keep real-data migration as a separate, user-confirmed final phase.

### Review

- The earlier recommendation to hold Phase 2 was based on missing concrete
  demand. That premise changed after moko clarified the long-term requirement.
- The revised plan keeps the accounting core stable while moving lifestyle
  values and classifications into dataset-owned TSV configuration.
- No implementation or real-data TSV changes were made in this revision.
- Canonical Daily Cube shape and layer semantics remain fixed core contracts;
  different coordinates or meanings use separate projections/views.

## 2026-06-15 AI Handoff Routing

- [x] Add the lifestyle configuration plan to `AGENTS.md` required reading.
- [x] Add the plan and fixed Cube/projection boundary to `AI_CODEMAP.md`.
- [x] Add the active direction and next scoped task to `TODO.md`.
- [x] Mark the 2026-06-08 terminal handoff as historical.

### Review

- A new AI starting from `AGENTS.md` now reaches the current plan before old
  audit and handoff material.
- The next task, fixed core contracts, and real-data migration restriction are
  visible without reconstructing this conversation.
