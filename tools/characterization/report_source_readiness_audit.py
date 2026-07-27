#!/usr/bin/env python3
"""Readonly strict-source readiness audit for explicit public/base directories.

This tool never writes source data. It reports only paths and aggregate counts;
do not publish output for a private base without explicit human direction.
"""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Readiness:
    base: Path
    default_currency: str
    account_rows: int
    account_currency_missing: int
    account_role_missing: int
    plan_rows: int
    plan_currency_missing: int
    plan_id_missing: int
    budget_rows: int
    budget_currency_missing: int
    actual_layout: str


def source_lines(path: Path) -> list[str]:
    try:
        rows = path.read_text(encoding="utf-8").splitlines()
    except (FileNotFoundError, IsADirectoryError):
        return []
    return [row for row in rows if row and not row.startswith(("#", "\\"))]


def metadata(fields: list[str]) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for field in fields:
        if "=" not in field:
            continue
        key, value = field.split("=", 1)
        result.setdefault(key, []).append(value)
    return result


def one_nonempty(values: list[str] | None) -> bool:
    return values is not None and len(values) == 1 and bool(values[0])


def config_values(path: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for row in source_lines(path):
        separator = "\t" if "\t" in row else "="
        if separator not in row:
            continue
        key, value = row.split(separator, 1)
        result.setdefault(key, []).append(value)
    return result


def state_for(values: list[str] | None) -> str:
    if values is None:
        return "missing"
    if len(values) != 1:
        return "duplicate"
    if not values[0]:
        return "empty"
    return "explicit"


def audit(base: Path) -> Readiness:
    config = config_values(base / "config.tsv")

    accounts = source_lines(base / "accounts.tsv")
    account_currency_missing = 0
    account_role_missing = 0
    for row in accounts:
        fields = row.split("\t")
        meta = metadata(fields[1:])
        account_currency_missing += not one_nonempty(meta.get("currency"))
        account_role_missing += not one_nonempty(meta.get("role"))

    plans = source_lines(base / "plan.tsv")
    plan_currency_missing = 0
    plan_id_missing = 0
    for row in plans:
        fields = row.split("\t")
        meta = metadata(fields[5:])
        plan_currency_missing += not one_nonempty(meta.get("currency"))
        plan_id_missing += not one_nonempty(meta.get("plan_id"))

    budgets = source_lines(base / "budget_alloc.tsv")
    budget_currency_missing = 0
    for row in budgets:
        fields = row.split("\t")
        meta = metadata(fields[5:])
        budget_currency_missing += not one_nonempty(meta.get("currency"))

    actual_values = config.get("ACTUAL_JOURNAL_FILE", ["actual.journal"])
    actual_name = actual_values[-1] if actual_values and actual_values[-1] else "actual.journal"
    direct = (base / actual_name).is_file()
    nested = (base / "data" / actual_name).is_file()
    actual_layout = "direct"
    if nested and not direct:
        actual_layout = "nested_fallback"
    elif not direct:
        actual_layout = "missing"

    return Readiness(
        base=base,
        default_currency=state_for(config.get("DEFAULT_CURRENCY")),
        account_rows=len(accounts),
        account_currency_missing=account_currency_missing,
        account_role_missing=account_role_missing,
        plan_rows=len(plans),
        plan_currency_missing=plan_currency_missing,
        plan_id_missing=plan_id_missing,
        budget_rows=len(budgets),
        budget_currency_missing=budget_currency_missing,
        actual_layout=actual_layout,
    )


def bases_for(path: Path, children: bool) -> list[Path]:
    if not children:
        return [path]
    return sorted(child for child in path.iterdir() if child.is_dir())


def print_tsv(rows: list[Readiness]) -> None:
    print(
        "base\tdefault_currency\taccount_rows\taccount_currency_missing\t"
        "account_role_missing\tplan_rows\tplan_currency_missing\t"
        "plan_id_missing\tbudget_rows\tbudget_currency_missing\tactual_layout"
    )
    for row in rows:
        print(
            f"{row.base.as_posix()}\t{row.default_currency}\t{row.account_rows}\t"
            f"{row.account_currency_missing}\t{row.account_role_missing}\t"
            f"{row.plan_rows}\t{row.plan_currency_missing}\t{row.plan_id_missing}\t"
            f"{row.budget_rows}\t{row.budget_currency_missing}\t{row.actual_layout}"
        )


def print_summary(rows: list[Readiness]) -> None:
    totals: Counter[str] = Counter()
    for row in rows:
        totals.update(
            bases=1,
            default_currency_not_explicit=int(row.default_currency != "explicit"),
            account_rows=row.account_rows,
            account_currency_missing=row.account_currency_missing,
            account_role_missing=row.account_role_missing,
            plan_rows=row.plan_rows,
            plan_currency_missing=row.plan_currency_missing,
            plan_id_missing=row.plan_id_missing,
            budget_rows=row.budget_rows,
            budget_currency_missing=row.budget_currency_missing,
            actual_nested_fallback=int(row.actual_layout == "nested_fallback"),
            actual_missing=int(row.actual_layout == "missing"),
        )
    print("metric\tvalue")
    for key in (
        "bases",
        "default_currency_not_explicit",
        "account_rows",
        "account_currency_missing",
        "account_role_missing",
        "plan_rows",
        "plan_currency_missing",
        "plan_id_missing",
        "budget_rows",
        "budget_currency_missing",
        "actual_nested_fallback",
        "actual_missing",
    ):
        print(f"{key}\t{totals[key]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path, help="explicit base or fixtures root")
    parser.add_argument(
        "--children", action="store_true", help="audit each direct child directory"
    )
    parser.add_argument("--summary", action="store_true", help="print aggregate counts")
    args = parser.parse_args()

    if not args.path.is_dir():
        parser.error(f"not a directory: {args.path}")
    rows = [audit(base) for base in bases_for(args.path, args.children)]
    if args.summary:
        print_summary(rows)
    else:
        print_tsv(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
