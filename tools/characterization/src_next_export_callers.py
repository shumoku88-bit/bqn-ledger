#!/usr/bin/env python3
"""Inventory final-record src_next exports and qualified BQN callers.

This is a source-level migration aid, not a BQN parser. It recognizes the
project convention that importable modules end in one export namespace record.
"""

from __future__ import annotations

import argparse
import re
from collections import Counter, defaultdict
from pathlib import Path

IMPORT_RE = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)\s*←\s*•Import\s+"([^"]+)"')
EXPORT_RE = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\s*⇐')


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def final_exports(path: Path) -> list[str]:
    text = read(path).rstrip()
    if not text.endswith("}"):
        return []
    start = text.rfind("\n{")
    if start < 0:
        if text.startswith("{"):
            start = -1
        else:
            return []
    suffix = text[start + 1 :]
    names = EXPORT_RE.findall(suffix)
    return list(dict.fromkeys(names))


def scope(root: Path, path: Path) -> str:
    relative = path.relative_to(root)
    head = relative.parts[0]
    if head == "src_next":
        return "runtime"
    if head == "src_edit":
        return "editor"
    if head == "tests":
        return "test"
    if head == "checks":
        return "check"
    if head == "tools":
        return "tool"
    return "other"


def disposition(name: str, counts: Counter[str]) -> str:
    total = sum(counts.values())
    production = counts["runtime"] + counts["editor"] + counts["tool"]
    if "ForTest" in name:
        return "test_seam"
    if total == 0:
        return "zero_repository_caller"
    if production == 0:
        return "test_or_check_only"
    return "repository_runtime_caller"


def inventory(root: Path) -> list[dict[str, object]]:
    modules = sorted((root / "src_next").rglob("*.bqn"))
    exports = {module.resolve(): final_exports(module) for module in modules}
    calls: dict[tuple[Path, str], list[tuple[str, Path, int]]] = defaultdict(list)

    source_files: list[Path] = []
    for directory in ("src_next", "src_edit", "tests"):
        source_files.extend(sorted((root / directory).rglob("*.bqn")))
    for directory in ("checks", "tools"):
        for candidate in sorted((root / directory).rglob("*")):
            if not candidate.is_file() or candidate.stat().st_size > 1_000_000:
                continue
            try:
                candidate.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            source_files.append(candidate)

    for caller in source_files:
        text = read(caller)
        for match in IMPORT_RE.finditer(text):
            alias, raw_target = match.groups()
            import_base = caller.parent if caller.suffix == ".bqn" else root
            target = (import_base / raw_target).resolve()
            if target not in exports:
                continue
            for name in exports[target]:
                references = len(re.findall(rf"\b{re.escape(alias)}\.{re.escape(name)}\b", text))
                if references:
                    calls[(target, name)].append((scope(root, caller), caller, references))

    rows: list[dict[str, object]] = []
    for module in modules:
        target = module.resolve()
        for name in exports[target]:
            entries = calls[(target, name)]
            counts: Counter[str] = Counter()
            for caller_scope, _caller, references in entries:
                counts[caller_scope] += references
            caller_files = ",".join(
                sorted({caller.relative_to(root).as_posix() for _, caller, _ in entries})
            )
            rows.append(
                {
                    "module": module.relative_to(root).as_posix(),
                    "export": name,
                    "runtime": counts["runtime"],
                    "editor": counts["editor"],
                    "test": counts["test"],
                    "check": counts["check"],
                    "tool": counts["tool"],
                    "total": sum(counts.values()),
                    "disposition": disposition(name, counts),
                    "caller_files": caller_files,
                }
            )
    return rows


def print_rows(rows: list[dict[str, object]]) -> None:
    fields = (
        "module",
        "export",
        "runtime",
        "editor",
        "test",
        "check",
        "tool",
        "total",
        "disposition",
        "caller_files",
    )
    print("\t".join(fields))
    for row in rows:
        print("\t".join(str(row[field]) for field in fields))


def print_summary(rows: list[dict[str, object]]) -> None:
    dispositions = Counter(str(row["disposition"]) for row in rows)
    print("metric\tvalue")
    print(f"modules_with_exports\t{len({row['module'] for row in rows})}")
    print(f"exports\t{len(rows)}")
    for key in (
        "repository_runtime_caller",
        "test_or_check_only",
        "test_seam",
        "zero_repository_caller",
    ):
        print(f"{key}\t{dispositions[key]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", type=Path, default=Path("."))
    parser.add_argument("--summary", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    if not (root / "src_next").is_dir():
        parser.error(f"src_next directory not found under: {root}")
    rows = inventory(root)
    if args.summary:
        print_summary(rows)
    else:
        print_rows(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
