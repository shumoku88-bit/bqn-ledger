#!/usr/bin/env python3
"""Inventory tracked src_next deletion blockers without reading household data."""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IMPORT_TOKEN = 'src_next/'


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
            result.append(("src_next_test", "delete_or_replace", path))
        elif path.startswith("tests/") and p.suffix == ".bqn" and contains(path, IMPORT_TOKEN):
            result.append(("other_test_import", "migrate_or_delete", path))
        if path.startswith("checks/check-src-next-") and p.suffix == ".sh":
            result.append(("src_next_check", "delete_or_replace", path))
        outside_known = path.startswith(("src_next/", "src_edit/", "tests/", "src/"))
        if p.suffix == ".bqn" and not outside_known and contains(path, IMPORT_TOKEN):
            result.append(("other_bqn_import", "delete_or_migrate", path))
    fixture_dirs = sorted({"/".join(path.split("/")[:2]) for path in paths if path.startswith("fixtures/src-next-")})
    result.extend(("src_next_fixture", "delete_or_rename", path) for path in fixture_dirs)
    for path, action in (
        ("tools/report", "replace"),
        ("tools/report-next", "delete"),
        ("tools/report-next-summary", "delete"),
        ("tools/report-section-metadata", "replace"),
        ("tools/query", "replace"),
        ("tools/main-ui.sh", "migrate"),
        ("tools/command-hub-cache-refresh", "migrate"),
    ):
        if path in paths:
            result.append(("route_or_consumer", action, path))
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
