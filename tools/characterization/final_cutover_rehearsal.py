#!/usr/bin/env python3
"""Dry-run the tracked atomic src_next deletion set without changing the worktree."""
from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INVENTORY_PATH = ROOT / "tools/characterization/final_cutover_inventory.py"

spec = importlib.util.spec_from_file_location("cutover_inventory", INVENTORY_PATH)
assert spec and spec.loader
inventory = importlib.util.module_from_spec(spec)
spec.loader.exec_module(inventory)

REPLACEMENT_PROOFS = {
    "tools/report": (
        "tools/report-destination",
        "tools/report-destination-all",
        "tools/report-destination-cache",
    ),
    "tools/report-section-metadata": ("tools/report-destination-metadata",),
    "tools/query": ("tools/query-destination",),
}

ALLOWED_ACTIONS = {"delete", "migrate", "replace"}


def removed(path: str, delete_paths: set[str]) -> bool:
    return path in delete_paths or any(path.startswith(parent + "/") for parent in delete_paths)


def main() -> int:
    tracked = set(inventory.tracked())
    plan = inventory.rows()
    errors: list[str] = []

    for category, action, path in plan:
        if action not in ALLOWED_ACTIONS:
            errors.append(f"non-exact action: {category}\t{action}\t{path}")
        if path not in tracked and not any(item.startswith(path + "/") for item in tracked):
            errors.append(f"planned path is not tracked: {path}")

    delete_paths = {path for _, action, path in plan if action == "delete"}
    migrate_paths = {path for _, action, path in plan if action == "migrate"}
    replace_paths = {path for _, action, path in plan if action == "replace"}
    remaining = {path for path in tracked if not removed(path, delete_paths)}

    forbidden_path_prefixes = (
        "src_next/",
        "tests/test_src_next_",
        "checks/check-src-next-",
        "fixtures/src-next-",
    )
    for path in sorted(remaining):
        if path.startswith(forbidden_path_prefixes):
            errors.append(f"old path survives simulated deletion: {path}")
        if path.endswith(".bqn") and inventory.contains(path, inventory.IMPORT_TOKEN):
            errors.append(f"old BQN import survives simulated deletion: {path}")

    for target, proofs in REPLACEMENT_PROOFS.items():
        if target not in replace_paths:
            errors.append(f"replacement target is not classified: {target}")
        for proof in proofs:
            if proof not in remaining:
                errors.append(f"replacement proof is unavailable: {proof}")

    required_survivors = {
        "fixtures/editor-golden/accounts.tsv",
        "fixtures/ledger-facts-phase1-proof/accounts.tsv",
        "tests/test_ledger_facts.bqn",
        "checks/check-report-destination-composition.sh",
        "checks/check-report-destination-cache.sh",
        "checks/check-report-destination-metadata.sh",
        "checks/check-report-destination-summary-query.sh",
        "tools/ledger-check",
        "tools/ledger-inspect",
        "tools/report-summary",
    }
    for path in sorted(required_survivors):
        if path not in remaining:
            errors.append(f"required destination evidence would be deleted: {path}")

    if errors:
        for error in errors:
            print(f"ERROR\t{error}")
        print("rehearsal_state\tblocked")
        return 1

    print(f"tracked_paths\t{len(tracked)}")
    print(f"simulated_deleted_paths\t{len(tracked) - len(remaining)}")
    print(f"explicit_migrations\t{len(migrate_paths)}")
    print(f"explicit_replacements\t{len(replace_paths)}")
    print("unclassified_actions\t0")
    print("surviving_old_bqn_imports\t0")
    print("surviving_old_named_paths\t0")
    print("rehearsal_state\tready_for_atomic_diff")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
