# Completed: Report Policy Externalization (Phase 1)

Status: verification-complete
Date: 2026-06-27

This document records the completion and verification of **Phase 1: Budget Group Contract Verification** under the [Report Policy Externalization Plan](../active-plans/REPORT_POLICY_EXTERNALIZATION_PLAN.md).

---

## Objective

Verify that BQN calculation engines (`src_next/`) do not bake in assumptions about specific budget group names (e.g., hardcoded `daily`, `flex`, or `reserve`), but resolve them dynamically from `config.tsv` and `accounts.tsv` metadata.

---

## Verification Results

### 1. Rename Fixture Created and Validated
*   **Fixture Path**: `fixtures/src-next-budget-group-rename/`
*   Created by copying and modifying the golden fixture configuration and account structures to rename the standard groups:
    *   Renamed `daily` and `flex` to `living_life` and `leisure`.
    *   Renamed `reserve` to `buffer`.
    *   Updated config variables (`HOUSEHOLD_GROUP_LIFE`, `HOUSEHOLD_GROUP_RESERVE`, and `HOUSEHOLD_GROUP_ORDER`) and account metadata accordingly.
*   Verified that BQN correctly aggregates these renamed groups dynamically.

### 2. Connected to CI Check Suite
*   Wired `checks/check-src-next-golden.sh fixtures/src-next-budget-group-rename` into `tools/check.sh`.
*   The check runs automatically to prevent regression of hardcoded assumptions in the engine.

### 3. Output key compatibility slots clarified
*   Clarified that current `daily/flex/reserve` machine field names in output formats are compatibility slots (fixed output keys), while actual policy labels are determined dynamically from `HOUSEHOLD_GROUP_*` and `accounts.tsv`.

---

## Verification Summary

*   `rtk bash tools/check.sh` passes successfully.
*   No hardcoded group names are present in BQN engine logic.
