#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-home-cursor.XXXXXX")"
trap 'rm -rf "$work"' EXIT
base="$work/household"
cp -R fixtures/canonical-household-v1 "$base"

cat >"$base/issues.tsv" <<'EOF'
issue_id	status	date	due	category	title	amount	currency	details
ISSUE-001	open	2026-01-20	2026-01-20	general	Synthetic reminder	100	JPY	Fixture-only evidence
EOF
cat >>"$base/report.toml" <<'EOF'

[presentation.calendar]
issue-due-marker = "?"
EOF

# Non-TTY callers retain the calendar contract. The explicit cursor relation is
# BQN-owned and preserves configured marker meaning.
legacy="$(tools/home-calendar "$base" 2026-01-20)"
explicit="$(tools/home-calendar "$base" 2026-01-20 calendar)"
[[ "$legacy" == "$explicit" ]] || {
  echo 'FAIL: non-TTY Home calendar behavior changed' >&2
  exit 1
}
cells="$(tools/home-calendar "$base" 2026-01-20 cells)"
grep -Fq $'2026-01-01\t0\t3\t 1 ' <<<"$cells" || {
  echo 'FAIL: Home cursor cells did not preserve January 2026 matrix origin' >&2
  printf '%s\n' "$cells" >&2
  exit 1
}
grep -Fq $'2026-01-20\t3\t1\t20?' <<<"$cells" || {
  echo 'FAIL: Home cursor cells did not retain selected-date coordinate/marker' >&2
  printf '%s\n' "$cells" >&2
  exit 1
}

# Adjacent-day and adjacent-month focus are BQN-owned and do not need to open
# canonical source observations. Horizontal edge movement therefore delegates
# Gregorian continuity instead of reconstructing month lengths in shell.
[[ "$(tools/home-calendar "$base" 2026-01-31 day-next)" == '2026-02-01' ]] || {
  echo 'FAIL: Home next-day focus did not cross January end' >&2
  exit 1
}
[[ "$(tools/home-calendar "$base" 2026-02-01 day-prev)" == '2026-01-31' ]] || {
  echo 'FAIL: Home previous-day focus did not cross February start' >&2
  exit 1
}
[[ "$(tools/home-calendar "$base" 2026-12-31 day-next)" == '2027-01-01' ]] || {
  echo 'FAIL: Home next-day focus did not cross year end' >&2
  exit 1
}
[[ "$(tools/home-calendar "$base" 2027-01-01 day-prev)" == '2026-12-31' ]] || {
  echo 'FAIL: Home previous-day focus did not cross year start' >&2
  exit 1
}
[[ "$(tools/home-calendar "$base" 2026-01-31 month-next)" == '2026-02-28' ]] || {
  echo 'FAIL: Home next-month focus did not clip January 31 to February end' >&2
  exit 1
}
[[ "$(tools/home-calendar "$base" 2026-03-31 month-prev)" == '2026-02-28' ]] || {
  echo 'FAIL: Home previous-month focus did not clip March 31 to February end' >&2
  exit 1
}

# Exercise the terminal matrix cursor. Start on Jan 12, move right to Jan 13,
# then down one week in the same weekday column to Jan 20, inspect it, and q
# from the detail pane. Exit 130 is the existing Home/back signal.
python3 - "$base" "$work/cursor.out" <<'PY'
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
        "tools/home-calendar",
        ["tools/home-calendar", base, "2026-01-12"],
        env,
    )

os.close(slave)
# Right arrow -> Jan 13, down arrow -> Jan 20, Enter, then q in detail.
os.write(master, b"\x1b[C\x1b[B\nq")
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
if exit_status not in (0, 130):
    raise SystemExit(f"Home cursor PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

out="$work/cursor.out"
for expected in \
  '2026-01' \
  'Mo  Tu  We  Th  Fr  Sa  Su' \
  'Home date: 2026-01-12' \
  'Home date: 2026-01-13' \
  'Home date: 2026-01-20' \
  '20?' \
  '2026-01-20' \
  'Actual' \
  '(none)' \
  'ISSUE-001' \
  'Synthetic reminder' \
  'Fixture-only evidence'; do
  grep -Fq "$expected" "$out" || {
    echo "FAIL: Home calendar cursor output missing: $expected" >&2
    cat "$out" >&2
    exit 1
  }
done

# Cursor highlight is presentation-only reverse video layered over BQN's fixed
# three-character cell; require that the terminal path actually emitted it.
python3 - "$out" <<'PY'
import sys
raw = open(sys.argv[1], "rb").read()
if b"\x1b[7m20?\x1b[0m" not in raw:
    raise SystemExit("FAIL: selected Home cell was not reverse-video highlighted")
PY

# Walk across calendar months through both printable and terminal-native keys.
# Every transition asks BQN for the adjacent focus and reloads BQN-owned calendar
# and cell relations; the shell does not derive February length or weekdays.
python3 - "$base" "$work/month.out" <<'PY'
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
        "tools/home-calendar",
        ["tools/home-calendar", base, "2026-01-20"],
        env,
    )

os.close(slave)
# ] -> Feb, PgUp -> Jan, PgDn -> Feb, [ -> Jan, then q.
os.write(master, b"]\x1b[5~\x1b[6~[q")
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
if exit_status not in (0, 130):
    raise SystemExit(f"Home month-navigation PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

month_out="$work/month.out"
for expected in \
  '2026-01' \
  '2026-02' \
  'Home date: 2026-01-20' \
  'Home date: 2026-02-20' \
  '[ ] / PgUp PgDn: month'; do
  grep -Fq "$expected" "$month_out" || {
    echo "FAIL: Home month-navigation output missing: $expected" >&2
    cat "$month_out" >&2
    exit 1
  }
done

# Horizontal movement is a continuous date walk across month boundaries. Start
# on Jan 31, use a real right arrow to enter Feb 1, a real left arrow to return,
# then repeat through l/h. The month rebuild happens only at the edge.
python3 - "$base" "$work/day-edge.out" <<'PY'
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
        "tools/home-calendar",
        ["tools/home-calendar", base, "2026-01-31"],
        env,
    )

os.close(slave)
# Right -> Feb 1, Left -> Jan 31, l -> Feb 1, h -> Jan 31, q.
os.write(master, b"\x1b[C\x1b[Dl hq".replace(b" ", b""))
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
if exit_status not in (0, 130):
    raise SystemExit(f"Home continuous-day PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

day_edge_out="$work/day-edge.out"
for expected in \
  '2026-01' \
  '2026-02' \
  'Home date: 2026-01-31' \
  'Home date: 2026-02-01'; do
  grep -Fq "$expected" "$day_edge_out" || {
    echo "FAIL: Home continuous-day output missing: $expected" >&2
    cat "$day_edge_out" >&2
    exit 1
  }
done

# Exercise xterm SGR mouse reporting against the same BQN-owned cell relation.
# Jan 20 is row 3 / column 1, so its three-character cell occupies terminal
# line 6, columns 5..7. Press at the center selects/highlights it; release opens
# the existing selected-date detail. No date or weekday arithmetic is repeated
# in the interactive adapter.
python3 - "$base" "$work/mouse.out" <<'PY'
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
        "tools/home-calendar",
        ["tools/home-calendar", base, "2026-01-12"],
        env,
    )

os.close(slave)
# SGR left-button press/release at x=6, y=6 -> Jan 20; then q in detail.
os.write(master, b"\x1b[<0;6;6M\x1b[<0;6;6mq")
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
if exit_status not in (0, 130):
    raise SystemExit(f"Home mouse PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

mouse_out="$work/mouse.out"
for expected in \
  'Home date: 2026-01-12' \
  'Home date: 2026-01-20' \
  '2026-01-20' \
  'Actual' \
  '(none)' \
  'ISSUE-001' \
  'Synthetic reminder' \
  'Fixture-only evidence'; do
  grep -Fq "$expected" "$mouse_out" || {
    echo "FAIL: Home calendar mouse output missing: $expected" >&2
    cat "$mouse_out" >&2
    exit 1
  }
done

python3 - "$mouse_out" <<'PY'
import sys
raw = open(sys.argv[1], "rb").read()
if b"\x1b[?1000h\x1b[?1006h" not in raw:
    raise SystemExit("FAIL: Home calendar did not enable SGR mouse reporting")
if b"\x1b[7m20?\x1b[0m" not in raw:
    raise SystemExit("FAIL: mouse-selected Home cell was not highlighted")
if b"\x1b[?1006l\x1b[?1000l" not in raw:
    raise SystemExit("FAIL: Home calendar did not disable mouse reporting")
PY

echo 'check-home-calendar-selector: ok'
