# Handoff Doc: Report Policy Externalization (Phase 1)

Status: handoff draft
Date: 2026-06-27

This document guides the next agent to implement **Phase 1: Budget Group Contract Verification** under the [Report Policy Externalization Plan](REPORT_POLICY_EXTERNALIZATION_PLAN.md).

---

## Objective

Verify that BQN calculation engines (`src_next/`) do not bake in assumptions about specific budget group names (e.g., hardcoded `daily`, `flex`, or `reserve`), but resolve them dynamically from `config.tsv` and `accounts.tsv` metadata.

---

## Step-by-Step Task Guide

### 1. Create the Rename Fixture
*   **Fixture Path**: `fixtures/src-next-budget-group-rename/`
*   Create this directory by copying `fixtures/src-next-golden/`.
*   Modify `config.tsv` in this new fixture directory to rename the standard groups:
    *   Change `daily` and `flex` to `living_life` and `leisure` (or any arbitrary labels).
    *   Change `reserve` to `buffer`.
    *   Update `HOUSEHOLD_GROUP_LIFE`, `HOUSEHOLD_GROUP_RESERVE`, and `HOUSEHOLD_GROUP_ORDER` in `config.tsv` to match these new names.
*   Update `accounts.tsv` in this fixture directory to assign the renamed groups (`budget_group=living_life`, `budget_group=buffer`, etc.) to the respective accounts.

### 2. Connect the Check
*   Update `checks/check-src-next-golden.sh` (or create a dedicated small check) to execute the engine on the `src-next-budget-group-rename` fixture.
*   Verify that BQN aggregates these new group names correctly without failing or defaulting to empty placeholders.

### 3. Implement Fixes (if BQN fails or behaves unexpectedly)
*   Scan `src_next/` (especially `envelopes.bqn` and `actual_comparison.bqn`) for hardcoded checks like `daily` or `flex`.
*   Refactor these checks to resolve groups via the config module (`src_next/config.bqn` or `config.tsv` parameters).

---

## Verification Criteria

*   `rtk bash tools/check.sh` passes successfully with the rename fixture included.
*   No new hardcoded names are introduced in BQN.
