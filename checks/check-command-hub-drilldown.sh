#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-household-cutover.XXXXXX")"
trap 'rm -rf "$work"' EXIT
base="$root/fixtures/ledger-facts-phase1-proof"

for file in tools/bl tools/household-surface tools/add-ui.sh tools/plan-finish-replenish-ui.sh; do
  bash -n "$file"
done

# The old Editor / Reports discovery hierarchy is no longer an interactive
# owner in tools/bl. Explicit direct commands remain below the no-command gate.
for retired in run_interactive_hub run_editor_hub run_reports_hub top_menu editor_menu editor_plans_menu; do
  if grep -Fq "$retired" tools/bl; then
    echo "FAIL: retired hierarchical Hub owner remains: $retired" >&2
    exit 1
  fi
done
grep -Fq 'exec "$ROOT_DIR/tools/household-surface"' tools/bl

# The Household surface owns the selected Date coordinate and passes it only as
# UI context. Canonical source/accounting meaning remains in downstream owners.
grep -Fq 'BL_SELECTED_DATE="$selected_date" "$@"' tools/household-surface
grep -Fq 'today="${BL_SELECTED_DATE:-$(date +%Y-%m-%d)}"' tools/add-ui.sh
grep -Fq 'selected_date="$BL_SELECTED_DATE"' tools/add-ui.sh
grep -Fq 'issue_close_args+=(--closed-date "$BL_SELECTED_DATE")' tools/add-ui.sh
grep -Fq 'reverse_args+=(--date "$BL_SELECTED_DATE")' tools/add-ui.sh
grep -Fq 'actual_date="$BL_SELECTED_DATE"' tools/plan-finish-replenish-ui.sh

# Invalid physical Date context fails before any writer interaction.
if BL_SELECTED_DATE=not-a-date tools/add-ui.sh --base "$base" --check >"$work/invalid.out" 2>"$work/invalid.err"; then
  echo 'FAIL: invalid BL_SELECTED_DATE was accepted by add-ui' >&2
  exit 1
fi
grep -Fq 'BL_SELECTED_DATE must be YYYY-MM-DD' "$work/invalid.err"

# Standalone add-ui is intentionally a compact writer-only shortcut rather than
# a second Household taxonomy. Its physical modes must nevertheless cover
# exactly the current non-Observe command actions. Two names are local physical
# aliases: budget -> budget-move and issue -> issue-add.
tools/household-surface-metadata actions \
  | awk -F'\t' 'NR>1 && $7=="command" && $3!="observe" {print $5}' \
  | sort >"$work/logical-writers"
sed -n '/^choose_mode()/,/^}/p' tools/add-ui.sh \
  | awk -F'\t' 'index($0,"\t") {print $1}' \
  | sed -e 's/^budget$/budget-move/' -e 's/^issue$/issue-add/' \
  | sort >"$work/add-ui-writers"
[[ "$(wc -l <"$work/logical-writers" | tr -d ' ')" == 12 ]]
[[ "$(wc -l <"$work/add-ui-writers" | tr -d ' ')" == 12 ]]
cmp "$work/logical-writers" "$work/add-ui-writers"

# Non-mutating Plan observation proves that the same selected Date reaches an
# explicit direct route when it is used as a temporal observation coordinate.
BL_SELECTED_DATE=2026-01-13 tools/bl --base "$base" plans upcoming --format tsv >"$work/bl-plan"
tools/edit --base "$base" plan list --temporal upcoming --as-of 2026-01-13 --format tsv >"$work/edit-plan"
cmp "$work/bl-plan" "$work/edit-plan"

# `bl --latest DATE` seeds the no-command Calendar focus, then Calendar movement
# remains BQN-owned through tools/home-calendar.
python3 - "$base" "$work/entry.out" <<'PY'
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
        "tools/bl",
        ["tools/bl", "--base", base, "--latest", "2026-08-16"],
        env,
    )
os.close(slave)
# next day, enter matrix, move to Plan/Add without opening a writer, quit
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
    raise SystemExit(f"Household cutover PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

grep -Fq 'Selected date: 2026-08-16' "$work/entry.out"
grep -Fq 'Selected date: 2026-08-17' "$work/entry.out"
grep -Fq 'Focus: calendar' "$work/entry.out"
grep -Fq 'Focus: matrix' "$work/entry.out"
if grep -Fq 'BQN-Ledger Command Hub' "$work/entry.out"; then
  echo 'FAIL: old hierarchical Hub reappeared through tools/bl' >&2
  exit 1
fi

# Wide report navigation is a presentation capability, not a gum/fzf
# dependency. `-S` keeps long lines unwrapped and horizontally scrollable.
grep -Fq 'less -SRFX' tools/main-ui.sh

echo 'check-command-hub-drilldown: OK'
