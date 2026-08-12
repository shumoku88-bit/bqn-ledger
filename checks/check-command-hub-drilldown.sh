#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-command-hub-drilldown.XXXXXX")"
trap 'rm -rf "$work"' EXIT
trap 'echo "FAIL: check-command-hub-drilldown line $LINENO: $BASH_COMMAND" >&2' ERR
base="$root/fixtures/ledger-facts-phase1-proof"

require_text() {
  local file="$1" text="$2"
  if ! grep -F "$text" "$file" >/dev/null; then
    echo "FAIL: expected text is missing from $(basename "$file"): $text" >&2
    return 1
  fi
}

bash -n tools/bl

python3 - "$base" "$work" <<'PY'
import fcntl
import os
import pty
import sys
import termios

base, work = sys.argv[1:3]

def run_tty(name, answers):
    master, slave = pty.openpty()
    pid = os.fork()
    if pid == 0:
        os.setsid()
        fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
        os.dup2(slave, 0)
        os.dup2(slave, 1)
        os.dup2(slave, 2)
        os.close(master)
        os.close(slave)
        env = os.environ.copy()
        env["BL_SELECTOR"] = "plain"
        env["NO_COLOR"] = "1"
        os.execve("tools/bl", ["tools/bl", "--base", base], env)

    os.close(slave)
    os.write(master, answers.encode("utf-8"))
    output = bytearray()
    while True:
        try:
            data = os.read(master, 4096)
            if not data:
                break
            output.extend(data)
        except OSError:
            break
    os.close(master)
    _, status = os.waitpid(pid, 0)
    exit_status = os.waitstatus_to_exitcode(status)
    if exit_status != 0:
        raise SystemExit(f"{name} Command Hub PTY failed with status {exit_status}")
    with open(os.path.join(work, f"{name}.out"), "wb") as f:
        f.write(output)

run_tty("top", "4\n")
run_tty("editor", "1\n1\n0\n2\n0\n3\n0\n4\n0\n5\n0\n0\n4\n")
run_tty("reports", "2\n1\n0\n2\n0\n3\n0\n0\n4\n")
run_tty("source", "3\n1\n0\n0\n4\n")
PY

top="$work/top.out"
editor="$work/editor.out"
reports="$work/reports.out"
source_out="$work/source.out"

for label in 'Editor' 'Reports' 'Source & System' 'Exit'; do
  require_text "$top" "$label"
done
for old_top in 'Record / Journal' 'Inspect / Operations'; do
  if grep -F "$old_top" "$top" >/dev/null; then
    echo "FAIL: old top-level Hub category remains visible: $old_top" >&2
    exit 1
  fi
done

for label in \
  'Journal' 'Plans' 'Budget' 'Accounts' 'Issues' \
  'Expense' 'Income' 'Transfer / move' 'Multi-posting transaction' \
  'Reverse with a compensating transaction' \
  'Add Plan' 'Edit Plan date / amount' 'Finish / actualize / replenish Plan' \
  'Retry Budget sync for a completed Plan' 'Related Plan evidence' \
  'Add / move Budget' 'Add Account' 'Add Issue' 'Close Issue'; do
  require_text "$editor" "$label"
done
for browse_label in 'Journal history' 'Open Plans' 'All Plans, including completed' 'List Accounts' 'List open Issues'; do
  if grep -F "$browse_label" "$editor" >/dev/null; then
    echo "FAIL: general read-only browse leaf leaked into Editor: $browse_label" >&2
    exit 1
  fi
done
for report_label in 'Envelope & Backing' 'Account Balances' 'Recent Journal' 'Planned Payments'; do
  if grep -F "$report_label" "$editor" >/dev/null; then
    echo "FAIL: semantic report leaked into Editor: $report_label" >&2
    exit 1
  fi
done

for label in 'Household' 'Accounting' 'Activity' 'All reports' 'Sequential preview'; do
  require_text "$reports" "$label"
done
while IFS=$'\t' read -r key label category owner human structured; do
  [[ $key == key ]] && continue
  require_text "$reports" "$label"
done < <(tools/report-section-metadata)
for action_label in \
  'Expense' 'Income' 'Transfer / move' 'Multi-posting transaction' \
  'Add Plan' 'Edit Plan date / amount' 'Finish / actualize / replenish Plan' \
  'Add / move Budget' 'Add Account' 'Add Issue' 'Close Issue'; do
  if grep -F "$action_label" "$reports" >/dev/null; then
    echo "FAIL: Editor action leaked into Reports: $action_label" >&2
    exit 1
  fi
done

for label in \
  'Open canonical source' 'Household check' 'Ledger / provenance inspection' \
  'Dependency and source diagnosis' 'Export canonical Journals to hledger' \
  'Compact report summary' 'Exact compact-key query (advanced)' \
  'Repository development suite' \
  'Account declarations' 'Actual transactions' 'Future Plans' 'Budget movements' \
  'Budget policy' 'Household policy' 'Report policy' 'Issues and decisions'; do
  require_text "$source_out" "$label"
done
for forbidden in 'Expense' 'Finish / actualize / replenish Plan' 'Account Balances' 'Envelope & Backing'; do
  if grep -F "$forbidden" "$source_out" >/dev/null; then
    echo "FAIL: daily Editor/Report leaf leaked into Source & System: $forbidden" >&2
    exit 1
  fi
done

# Report grouping is a projection of the existing metadata relation. The Hub
# owns friendly group labels, not a second list of the twelve retained keys.
grep -F 'tools/report-section-metadata' tools/bl >/dev/null
grep -F '$3==category' tools/bl >/dev/null

# The raw-source submenu still owns exactly the existing canonical eight keys;
# selector presentation may hide those keys and show their descriptions.
for file in accounts.journal actual.journal plan.journal budget.journal budget.toml household.toml report.toml issues.tsv; do
  grep -F "$file" tools/bl >/dev/null
done

echo 'check-command-hub-drilldown: OK'
