#!/usr/bin/env python3
"""Inventory tracked src_next deletion blockers without reading household data."""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IMPORT_TOKEN = 'src_next/'

MIGRATE_REFERENCES = {
    "checks/check-edit-bqn-account-list.sh",
    "checks/check-edit-bqn-issue-close.sh",
    "checks/check-edit-bqn-journal-add.sh",
    "checks/check-edit-bqn-journal-block-add.sh",
    "checks/check-edit-bqn-journal-cleanup-plan.sh",
    "checks/check-edit-bqn-plan-add.sh",
    "checks/check-edit-bqn-plan-edit.sh",
    "checks/check-edit-bqn-plan-list.sh",
    "checks/check-edit-bqn-plan-related.sh",
    "checks/check-editor-account-ownership.sh",
    "checks/check-editor-actual-ownership.sh",
    "checks/check-editor-config-ownership.sh",
    "checks/check-editor-currency-ownership.sh",
    "checks/check-editor-runtime-boundary.sh",
    "checks/check-israel-ils-usable-vertical-slice.sh",
    "checks/check-plan-finish-replenish-ui.sh",
    "checks/check-safe-replace-line.sh",
    "checks/check-source-field-ownership.sh",
    "checks/check-source-io-ownership.sh",
    "tools/check.sh",
    "tools/coverage",
    "tools/devtools-check.sh",
    "tools/doctor",
    "tools/lib/safe-write.sh",
}

DELETE_REFERENCES = {
    "checks/check-developer-inspection-entrypoint.sh",
    "checks/check-projection-compatibility-exports.sh",
    "checks/check-projection-diagnostic-presentation.sh",
    "checks/check-report-cache-nested-module-invalidation.sh",
    "checks/check-report-context-duplication-characterization.sh",
    "checks/check-report-section-metadata.sh",
    "fixtures/editor-golden/expected/src_next_snapshot.txt",
    "tests/fixtures/report_section_metadata_expected.tsv",
    "tools/characterization/final_cutover_inventory.py",
    "tools/characterization/report-latency-benchmark.sh",
}


def tracked() -> list[str]:
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True)
    return [line for line in out.splitlines() if line]


def contains(path: str, token: str) -> bool:
    try:
        return token in (ROOT / path).read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return False


def rows() -> list[tuple[str, str, str]]:
    paths = tracked()
    result: list[tuple[str, str, str]] = []
    for path in paths:
        p = Path(path)
        if path.startswith("src_next/") and p.suffix == ".bqn":
            result.append(("src_next_module", "delete", path))
        if path.startswith("src_edit/") and p.suffix == ".bqn" and contains(path, IMPORT_TOKEN):
            result.append(("editor_import", "migrate", path))
        if path.startswith("tests/test_src_next_") and p.suffix == ".bqn":
            result.append(("src_next_test", "delete", path))
        elif path.startswith("tests/") and p.suffix == ".bqn" and contains(path, IMPORT_TOKEN):
            result.append(("other_test_import", "delete", path))
        if path.startswith("checks/check-src-next-") and p.suffix == ".sh":
            result.append(("src_next_check", "delete", path))
        outside_known = path.startswith(("src_next/", "src_edit/", "tests/", "src/"))
        if p.suffix == ".bqn" and not outside_known and contains(path, IMPORT_TOKEN):
            result.append(("other_bqn_import", "delete", path))
    fixture_dirs = sorted({"/".join(path.split("/")[:2]) for path in paths if path.startswith("fixtures/src-next-")})
    result.extend(("src_next_fixture", "delete", path) for path in fixture_dirs)
    for path, action in (
        ("tools/report", "replace"),
        ("tools/report-next", "delete"),
        ("tools/report-next-summary", "delete"),
        ("tools/envelope-calc", "delete"),
        ("tools/report-section-metadata", "replace"),
        ("tools/query", "replace"),
        ("tools/main-ui.sh", "migrate"),
        ("tools/command-hub-cache-refresh", "migrate"),
    ):
        if path in paths:
            result.append(("route_or_consumer", action, path))

    categorized = {path for _, _, path in result}
    for path in paths:
        if (path.startswith("src_next/") or path in categorized
                or any(path.startswith(directory + "/") for directory in fixture_dirs)
                or not contains(path, IMPORT_TOKEN)):
            continue
        suffix = Path(path).suffix
        if path.startswith("docs/archive/"):
            continue
        if path.startswith("docs/") or suffix == ".md":
            result.append(("documentation_reference", "review_or_delete", path))
        elif path in MIGRATE_REFERENCES:
            result.append(("runtime_reference", "migrate", path))
        elif path in DELETE_REFERENCES:
            result.append(("runtime_reference", "delete", path))
        else:
            result.append(("unclassified_reference", "classify", path))
    return sorted(set(result))


def destination_imports(paths: list[str]) -> list[str]:
    return [
        path for path in paths
        if path.startswith(("src/ledger/", "src/accounting/", "src/sections/", "src/report/", "src/application/"))
        and path.endswith(".bqn") and contains(path, IMPORT_TOKEN)
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", choices=("summary", "tsv"), default="summary")
    parser.add_argument("--assert-destination-clean", action="store_true")
    args = parser.parse_args()
    inventory = rows()
    imports = destination_imports(tracked())
    if args.format == "tsv":
        print("category\taction\tpath")
        for row in inventory:
            print("\t".join(row))
    else:
        categories = sorted({category for category, _, _ in inventory})
        for category in categories:
            print(f"{category}\t{sum(row[0] == category for row in inventory)}")
        print(f"destination_src_next_import\t{len(imports)}")
        print(f"cutover_state\t{'blocked' if inventory else 'ready'}")
    if args.assert_destination_clean and imports:
        for path in imports:
            print(f"destination import violation: {path}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
