#!/usr/bin/env python3
from pathlib import Path

replacements = {
    Path("tools/check.sh"): [
        (
            "bash checks/check-edit-bqn-journal-add.sh >/dev/null\n",
            "bash checks/check-edit-bqn-journal-add.sh >/dev/null\n"
            "bash checks/check-edit-bqn-currency-m2.sh >/dev/null\n",
        ),
    ],
    Path("checks/check-edit-bqn-account-list.sh"): [
        (
            "grep -Fq $'income:友人精算\\trole=income' <<< \"$preview\"",
            "grep -Fq $'income:友人精算\\trole=income\\tcurrency=JPY' <<< \"$preview\"",
        ),
        (
            "grep -Fxq $'income:友人精算\\trole=income' \"$tmp/accounts.tsv\"",
            "grep -Fxq $'income:友人精算\\trole=income\\tcurrency=JPY' \"$tmp/accounts.tsv\"",
        ),
    ],
    Path("checks/check-edit-bqn-journal-add.sh"): [
        (
            "journal add --date 2026-06-29 --memo \"bad amount\" --from assets:bank --to expenses:食費 --amount 12.3 --yes --post-check none",
            "journal add --date 2026-06-29 --memo \"bad amount\" --from assets:bank --to expenses:食費 --amount 12x --yes --post-check none",
        ),
    ],
}

for path, rules in replacements.items():
    text = path.read_text(encoding="utf-8")
    for old, new in rules:
        count = text.count(old)
        if count != 1:
            raise SystemExit(f"{path}: expected exactly one match, got {count}: {old!r}")
        text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")
