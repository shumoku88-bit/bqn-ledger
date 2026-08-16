#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-household-surface.XXXXXX")"
trap 'rm -rf "$work"' EXIT

bash -n tools/household-surface
[[ -x tools/household-surface ]]

./tools/household-surface-metadata >"$work/surface.tsv"
[[ "$(wc -l <"$work/surface.tsv" | tr -d ' ')" == 25 ]]
head -n1 "$work/surface.tsv" | grep -Fx $'domain_index\tdomain_key\tdomain_label\toperation_index\toperation_key\toperation_label\tenabled\tcell_label' >/dev/null

# The visible surface is one rectangular Domain × Operation relation.
[[ "$(awk -F'\t' 'NR>1{seen[$2]=1} END{print length(seen)}' "$work/surface.tsv")" == 6 ]]
[[ "$(awk -F'\t' 'NR>1{seen[$5]=1} END{print length(seen)}' "$work/surface.tsv")" == 4 ]]
[[ "$(awk -F'\t' 'NR>1 && $7==1{n++} END{print n+0}' "$work/surface.tsv")" == 15 ]]

require_cell() {
  local domain="$1" operation="$2" enabled="$3" label="$4"
  awk -F'\t' -v d="$domain" -v o="$operation" -v e="$enabled" -v l="$label" \
    'NR>1 && $2==d && $5==o && $7==e && $8==l{found=1} END{exit !found}' "$work/surface.tsv"
}
require_cell actual observe 1 Journal
require_cell actual change 0 ''
require_cell actual resolve 1 Reverse
require_cell plan change 1 Edit
require_cell plan resolve 1 Finish
require_cell envelope add 1 Move
require_cell issue resolve 1 Close
require_cell household observe 1 Reports
require_cell household add 0 ''

./tools/report-section-metadata >"$work/reports.tsv"
# Report placement is owned by the existing report catalog, not duplicated in
# the Household surface relation.
awk -F'\t' 'NR>1 && $5=="actual" && $6=="recent" && $1=="recent"{a=1}
             NR>1 && $5=="plan" && $6=="future" && $1=="planned"{p=1}
             NR>1 && $5=="envelope" && $1=="envelopes"{e=1}
             NR>1 && $5=="account" && $6=="month" && $1=="monthly-accounts"{m=1}
             NR>1 && $5=="issue" && $1=="issues"{i=1}
             NR>1 && $5=="household" && $1=="balance-sheet"{h=1}
             END{exit !(a&&p&&e&&m&&i&&h)}' "$work/reports.tsv"

./tools/household-surface-metadata actions actual add >"$work/actual-add.tsv"
[[ "$(awk 'END{print NR}' "$work/actual-add.tsv")" == 5 ]]
for action in expense income move multi; do
  grep -Eq $'^[0-9]+\tactual\tadd\tselected-date\t'"$action"$'\t' "$work/actual-add.tsv"
done
./tools/household-surface-metadata actions plan observe >"$work/plan-observe.tsv"
grep -F $'planned\tPlanned Payments\treport' "$work/plan-observe.tsv" >/dev/null
grep -F $'plan-related\tRelated Plan evidence\tcommand' "$work/plan-observe.tsv" >/dev/null
./tools/household-surface-metadata actions household observe >"$work/household-observe.tsv"
grep -F $'daily-target\tDaily Target\treport' "$work/household-observe.tsv" >/dev/null
grep -F $'balance-sheet\tBalance Sheet\treport' "$work/household-observe.tsv" >/dev/null

if ./tools/household-surface-metadata actions actual >"$work/invalid.out" 2>&1; then
  echo 'FAIL: incomplete action coordinate succeeded' >&2
  exit 1
fi
grep -F 'expected no arguments or: actions DOMAIN OPERATION' "$work/invalid.out" >/dev/null

# The primary surface is raw-terminal spatial navigation, not a fuzzy selector.
if rg -n 'fzf|gum' tools/household-surface >/dev/null; then
  echo 'FAIL: primary Household surface depends on fzf/gum' >&2
  exit 1
fi

python3 - "$root/fixtures/ledger-facts-phase1-proof" "$work/tty.out" <<'PY'
import fcntl
import os
import pty
import sys
import termios

base, output_path = sys.argv[1:3]
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
    env["NO_COLOR"] = "1"
    env["TERM"] = "xterm-256color"
    os.execve(
        "tools/household-surface",
        ["tools/household-surface", base, "2026-08-16"],
        env,
    )
os.close(slave)
# next day, enter matrix, move to Plan/Add coordinate without opening it, quit
os.write(master, b"\x1b[C\t\x1b[B\x1b[Cq")
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
    raise SystemExit(f"Household surface PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

for text in \
  'Selected date: 2026-08-16' \
  'Selected date: 2026-08-17' \
  'Focus: calendar' \
  'Focus: matrix' \
  'Actual' 'Plan' 'Envelope' 'Account' 'Issue' 'Household' \
  'Observe' 'Add' 'Change' 'Resolve' \
  'Journal' 'Record' 'Reverse' 'Backing' 'Reports'; do
  grep -Fq "$text" "$work/tty.out" || {
    echo "FAIL: Household surface PTY output missing: $text" >&2
    cat "$work/tty.out" >&2
    exit 1
  }
done

if rg -n 'fzf|gum|ANSI|escape sequence|mouse' src/application/household_surface.bqn >/dev/null; then
  echo 'FAIL: physical frontend vocabulary leaked into Household surface semantics' >&2
  exit 1
fi
if rg -n 'actual\.journal|plan\.journal|budget\.journal|issues\.tsv|•FChars|source_io' src/application/household_surface.bqn >/dev/null; then
  echo 'FAIL: Household surface semantics gained canonical source ownership' >&2
  exit 1
fi

echo 'check-household-surface: OK'