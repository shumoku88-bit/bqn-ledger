# Dead Code / Low-Frequency Tools Inventory (2026-06)

This report lists scripts, tools, and functions that appear to be unused, obsolete, or strictly for legacy maintenance, based on a codebase audit. **No files have been deleted**; this is purely an inventory for future cleanup decisions.

## 1. Obsolete / Legacy Scripts

These scripts appear to be one-off tools for data migration or historical comparisons.

- **`tools/import_data.py`**
  - **Purpose:** Parses old `hledger` `.journal` and `plan.txt` formats to generate the initial `journal.tsv` and `plan.tsv`.
  - **Status:** **Obsolete**. The system now natively runs on TSV. This was likely a one-time migration script.
  - **Recommendation:** Delete (or move to a `legacy/` or `archive/` folder if historical reference is needed).

- **`tools/compare-journals.py`**
  - **Purpose:** Compares the BQN TSV output against `kakeigo` (hledger) and `scm-ledger` (Scheme) for parity.
  - **Status:** **Legacy Maintenance**. Referenced in `README.md` and `MAINTENANCE.md`, but only relevant during the migration/verification phase between different Ledger implementations.
  - **Recommendation:** Keep if still cross-checking against old systems, otherwise safe to archive.

## 2. Low-Frequency / Specialized Tools

These BQN tools are functional but serve very specific, rare use cases.

- **`tools/txn.bqn`**
  - **Purpose:** A legacy CLI interface to view specific transaction bundles or IDs.
  - **Status:** Active, but highly specialized. Referenced heavily in `AI_CODEMAP.md` and `JOURNAL_META.md`.
  - **Recommendation:** Keep, but consider if its functionality (viewing bundles) could just be a flag in `main.bqn`.

- **`tools/plan-view.bqn`**
  - **Purpose:** Views the `plan.tsv` schedule.
  - **Status:** Partially redundant. `main.bqn`'s Section 6 (Planned Payments) and Section 11 (Cycle Consultation) now cover most of this domain.
  - **Recommendation:** Review for potential deprecation if `main.bqn` covers all use cases.

- **`tools/check-trend-liquid.bqn`** & **`tools/check-tx-updates.bqn`**
  - **Purpose:** Internal sanity checks verifying the 3D array engine logic during the refactoring phase.
  - **Status:** **Development scaffolding**. Currently executed in `tools/check.sh`.
  - **Recommendation:** Keep as regression tests, but they are technically internal tooling.

## 3. Potential Dead Code (Functions)

During the refactoring, some functions in `report_sections.bqn` or `core.bqn` may have lost their primary callers.
- In `core.bqn`: `InitAccounts`, `GetTxUpd`, etc., are heavily used, so core is healthy.
- With the split of `report_cycle_consult.bqn`, `report_sections.bqn` is much leaner.
- The `envelope_flow` logic inside `tools/export-envelope-flow.bqn` shares base filtering and data extraction logic with the new `report_envelope_trend.bqn`.
  - **Analysis:** While they share the foundation of reading the Budget layer from the 3D array engine, their goals differ. `report_envelope_trend.bqn` focuses on **prediction and averages** (e.g., 3-day window, exhaustion days), whereas `export-envelope-flow.bqn` focuses on **transaction decomposition** (splitting daily changes into `journal` spending vs `plan/alloc` transfers).
  - **Recommendation:** They are not 100% duplicate code yet. However, the transaction decomposition logic in `export-envelope-flow.bqn` is highly valuable. The future goal should be to merge this decomposition logic into `report_envelope_trend.bqn` to improve the accuracy of exhaustion predictions (e.g., filtering out transfers from "average spend"), and then make `export-envelope-flow.bqn` simply a formatting wrapper around the unified engine module.

## Summary
The codebase is generally lean. The primary candidates for immediate deletion are the Python migration scripts (`import_data.py`), assuming the BQN implementation is now the single source of truth.
