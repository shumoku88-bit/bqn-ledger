#!/usr/bin/env python3
"""Safely apply the reviewed JPY currency migration to one ledger directory.

The BQN dry-run remains the semantic authority for which source rows change.
This helper validates that protocol, stages complete replacement files, checks
snapshots twice, creates recoverable backups, atomically replaces the set, and
rolls back the set if a write or post-check fails.
"""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass

SOURCE_FILES = ("accounts.tsv", "journal.tsv", "plan.tsv", "budget_alloc.tsv")
DEFAULT_LINE = "DEFAULT_CURRENCY=JPY"
FILE_CHANGE_RE = re.compile(r"^FILE (accounts\.tsv|journal\.tsv|plan\.tsv|budget_alloc\.tsv) ROW ([0-9]+)$")
FILE_SUMMARY_RE = re.compile(
    r"^file=(accounts\.tsv|journal\.tsv|plan\.tsv|budget_alloc\.tsv) "
    r"state=([^ ]+) missing=([0-9]+) explicit=([0-9]+) errors=([0-9]+)$"
)


class MigrationError(RuntimeError):
    pass


@dataclass(frozen=True)
class Snapshot:
    size: int
    mtime_ns: int
    sha256: str


@dataclass(frozen=True)
class Change:
    file_name: str
    row_index: int
    old: str
    new: str


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def snapshot(path: Path) -> Snapshot:
    data = path.read_bytes()
    stat = path.stat()
    return Snapshot(size=len(data), mtime_ns=stat.st_mtime_ns, sha256=digest(data))


def assert_snapshot(path: Path, expected: Snapshot) -> None:
    if snapshot(path) != expected:
        raise MigrationError(f"source became stale during migration: {path}")


def run(command: list[str], *, cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


def parse_dry_run(output: str, returncode: int) -> tuple[list[Change], dict[str, int], bool]:
    lines = output.splitlines()
    summaries: dict[str, int] = {}
    changes: list[Change] = []
    missing_default = False

    for line in lines:
        match = FILE_SUMMARY_RE.match(line)
        if match:
            file_name, state, missing, _explicit, errors = match.groups()
            if state != "ok" or int(errors) != 0:
                raise MigrationError(f"dry-run source audit is not clean: {line}")
            summaries[file_name] = int(missing)
        if line == "ERROR: missing ledger config key: DEFAULT_CURRENCY":
            missing_default = True

    index = 0
    while index < len(lines):
        match = FILE_CHANGE_RE.match(lines[index])
        if not match:
            index += 1
            continue
        if index + 2 >= len(lines):
            raise MigrationError(f"truncated dry-run change after: {lines[index]}")
        old_line = lines[index + 1]
        new_line = lines[index + 2]
        if not old_line.startswith("-") or not new_line.startswith("+"):
            raise MigrationError(f"invalid dry-run change protocol after: {lines[index]}")
        file_name, row_text = match.groups()
        old = old_line[1:]
        new = new_line[1:]
        if new != old + "\tcurrency=JPY":
            raise MigrationError(
                f"unsafe proposal for {file_name} row {row_text}: expected exact tab + currency=JPY append"
            )
        changes.append(Change(file_name=file_name, row_index=int(row_text), old=old, new=new))
        index += 3

    if set(summaries) != set(SOURCE_FILES):
        raise MigrationError("dry-run did not report all four source files")
    for file_name, expected_count in summaries.items():
        actual_count = sum(change.file_name == file_name for change in changes)
        if actual_count != expected_count:
            raise MigrationError(
                f"dry-run count mismatch for {file_name}: summary={expected_count} proposals={actual_count}"
            )

    changed_line = next((line for line in lines if line.startswith("changed_count=")), None)
    if changed_line is None:
        raise MigrationError("dry-run did not report changed_count")
    changed_count = int(changed_line.split("=", 1)[1])
    if changed_count != len(changes):
        raise MigrationError(f"dry-run total mismatch: summary={changed_count} proposals={len(changes)}")

    if returncode != 0 and not missing_default:
        raise MigrationError(f"dry-run failed with exit {returncode}\n{output}")
    if returncode == 0 and missing_default:
        raise MigrationError("dry-run protocol contradicted itself about DEFAULT_CURRENCY")

    error_lines = [line for line in lines if line.startswith("ERROR:")]
    allowed_errors = ["ERROR: missing ledger config key: DEFAULT_CURRENCY"] if missing_default else []
    if error_lines != allowed_errors:
        raise MigrationError("unexpected dry-run errors:\n" + "\n".join(error_lines))

    return changes, summaries, missing_default


def split_body_and_ending(raw_line: bytes) -> tuple[bytes, bytes]:
    if raw_line.endswith(b"\r\n"):
        return raw_line[:-2], b"\r\n"
    if raw_line.endswith(b"\n"):
        return raw_line[:-1], b"\n"
    return raw_line, b""


def stage_source(path: Path, changes: list[Change]) -> bytes:
    raw_lines = path.read_bytes().splitlines(keepends=True)
    by_row = {change.row_index: change for change in changes}
    if len(by_row) != len(changes):
        raise MigrationError(f"duplicate proposed row index for {path.name}")

    for row_index, change in by_row.items():
        if row_index >= len(raw_lines):
            raise MigrationError(f"proposal row out of range for {path.name}: {row_index}")
        body, ending = split_body_and_ending(raw_lines[row_index])
        try:
            body_text = body.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise MigrationError(f"non-UTF-8 source row in {path.name}: {row_index}") from exc
        if body_text != change.old:
            raise MigrationError(f"proposal old row no longer matches {path.name} row {row_index}")
        raw_lines[row_index] = change.new.encode("utf-8") + ending

    return b"".join(raw_lines)


def config_state(data: bytes) -> str:
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise MigrationError("config.tsv is not UTF-8") from exc

    values: list[str] = []
    for raw in text.splitlines():
        line = raw.rstrip("\r")
        if not line or line.startswith("#") or line.startswith("\\"):
            continue
        if "\t" in line:
            key, value = line.split("\t", 1)
        elif "=" in line:
            key, value = line.split("=", 1)
        else:
            continue
        if key == "DEFAULT_CURRENCY":
            values.append(value)

    if not values:
        return "missing"
    if len(values) > 1:
        raise MigrationError("duplicate ledger config key: DEFAULT_CURRENCY")
    if values[0] != "JPY":
        raise MigrationError(f"production JPY migration requires DEFAULT_CURRENCY=JPY, found {values[0]!r}")
    return "explicit-jpy"


def stage_config(data: bytes, state: str) -> bytes:
    if state == "explicit-jpy":
        return data
    if state != "missing":
        raise MigrationError(f"unsupported config state: {state}")
    separator = b"" if not data or data.endswith((b"\n", b"\r")) else b"\n"
    return data + separator + DEFAULT_LINE.encode("utf-8") + b"\n"


def choose_backup(base: Path, file_name: str, stamp: str) -> Path:
    backup_dir = base / ".backup"
    candidate = backup_dir / f"{file_name}.{stamp}.currency-m25.bak"
    suffix = 2
    while candidate.exists():
        candidate = backup_dir / f"{file_name}.{stamp}-{suffix}.currency-m25.bak"
        suffix += 1
    return candidate


def write_temp_for_target(target: Path, data: bytes) -> Path:
    fd, name = tempfile.mkstemp(prefix=f".{target.name}.currency-m25-", dir=target.parent)
    temp_path = Path(name)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        shutil.copymode(target, temp_path)
        return temp_path
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise


def restore_all(backups: dict[Path, Path], targets: list[Path]) -> None:
    failures: list[str] = []
    for target in targets:
        backup = backups.get(target)
        if backup is None or not backup.exists():
            continue
        try:
            shutil.copy2(backup, target)
        except Exception as exc:  # pragma: no cover
            failures.append(f"{target}: {exc}")
    if failures:
        raise MigrationError("rollback failed:\n" + "\n".join(failures))


def post_check(root: Path, base: Path, mode: str) -> None:
    audit = run([str(root / "tools" / "currency-setup"), "audit", str(base)], cwd=root)
    combined = "\n".join(part for part in (audit.stdout, audit.stderr) if part)
    required = ("state=ok", "changed_count=0", "error_count=0")
    if audit.returncode != 0 or any(item not in audit.stdout for item in required):
        raise MigrationError(f"post-migration audit failed\n{combined}")

    lint = run(["bqn", "src_next/report.bqn", str(base)], cwd=root)
    if lint.returncode != 0:
        combined = "\n".join(part for part in (lint.stdout, lint.stderr) if part)
        raise MigrationError(f"post-migration ledger lint failed\n{combined}")

    if mode == "full":
        full = run(["bash", "tools/check.sh"], cwd=root)
        if full.returncode != 0:
            combined = "\n".join(part for part in (full.stdout, full.stderr) if part)
            raise MigrationError(f"repository full check failed\n{combined}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--base", required=True, type=Path)
    parser.add_argument("--post-check", choices=("lint", "full"), default="full")
    parser.add_argument("--yes", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    base = args.base.resolve()
    paths = {name: base / name for name in ("config.tsv",) + SOURCE_FILES}
    for path in paths.values():
        if not path.is_file():
            raise MigrationError(f"required source file not found: {path}")

    snapshots = {path: snapshot(path) for path in paths.values()}
    dry = run([str(root / "tools" / "currency-setup"), "dry-run", str(base)], cwd=root)
    dry_output = "\n".join(part for part in (dry.stdout.rstrip("\n"), dry.stderr.rstrip("\n")) if part)
    changes, summaries, missing_default = parse_dry_run(dry_output, dry.returncode)

    current_config = paths["config.tsv"].read_bytes()
    config_kind = config_state(current_config)
    if missing_default != (config_kind == "missing"):
        raise MigrationError("dry-run and direct config inspection disagree")

    staged: dict[Path, bytes] = {paths["config.tsv"]: stage_config(current_config, config_kind)}
    for file_name in SOURCE_FILES:
        staged[paths[file_name]] = stage_source(
            paths[file_name], [change for change in changes if change.file_name == file_name]
        )

    changed_targets = [path for path, candidate in staged.items() if candidate != path.read_bytes()]
    print("Currency migration apply preview")
    print(f"Base: {base}")
    print(f"DEFAULT_CURRENCY: {'append JPY' if config_kind == 'missing' else 'already JPY'}")
    for file_name in SOURCE_FILES:
        print(f"{file_name}: add currency=JPY to {summaries[file_name]} row(s)")
    print(f"Source rows: {len(changes)}")
    print(f"Files to replace: {len(changed_targets)}")
    print(f"Post-check: {args.post_check}")

    if not changed_targets:
        print("Already migrated. No files were modified.")
        return 0

    if not args.yes:
        if not sys.stdin.isatty():
            raise MigrationError("apply requires an interactive confirmation or --yes")
        answer = input("Apply this migration? [y/N]: ").strip().lower()
        if answer not in {"y", "yes"}:
            print("Cancelled. No files were modified.")
            return 0

    for path, expected in snapshots.items():
        assert_snapshot(path, expected)

    stamp = time.strftime("%Y%m%d%H%M%S")
    backups: dict[Path, Path] = {}
    for target in changed_targets:
        backup = choose_backup(base, target.name, stamp)
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(target, backup)
        backups[target] = backup

    hook = os.environ.get("CURRENCY_SETUP_TEST_BEFORE_COMMIT_HOOK")
    if os.environ.get("BQN_LEDGER_TEST_MODE") == "1" and hook:
        subprocess.run(["bash", "-c", hook], cwd=root, check=True)

    try:
        for path, expected in snapshots.items():
            assert_snapshot(path, expected)

        temps = {target: write_temp_for_target(target, staged[target]) for target in changed_targets}
        replaced: list[Path] = []
        try:
            for target in changed_targets:
                os.replace(temps[target], target)
                replaced.append(target)
        except Exception:
            for temp_path in temps.values():
                temp_path.unlink(missing_ok=True)
            restore_all(backups, replaced)
            raise

        try:
            post_check(root, base, args.post_check)
        except Exception:
            restore_all(backups, changed_targets)
            raise
    except Exception:
        print("Migration failed. Source files were restored from backups.", file=sys.stderr)
        for target, backup in backups.items():
            print(f"Restore copy: {backup} -> {target}", file=sys.stderr)
        raise

    print("Migration applied successfully.")
    for target, backup in backups.items():
        print(f"Backup: {backup}")
    print("Idempotence: audit reports changed_count=0")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MigrationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
