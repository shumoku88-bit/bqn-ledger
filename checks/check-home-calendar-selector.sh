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

# Non-TTY callers retain the calendar contract. Explicit selector/cursor
# relations are BQN-owned and preserve configured marker meaning.
legacy="$(tools/home-calendar "$base" 2026-01-20)"
explicit="$(tools/home-calendar "$base" 2026-01-20 calendar)"
[[ "$legacy" == "$explicit" ]] || {
  echo 'FAIL: non-TTY Home calendar behavior changed' >&2
  exit 1
}
choices="$(tools/home-calendar "$base" 2026-01-20 choices)"
grep -Fq $'2026-01-20\t20?  2026-01-20' <<<"$choices" || {
  echo 'FAIL: semantic Home date choice did not retain configured marker' >&2
  printf '%s\n' "$choices" >&2
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

echo 'check-home-calendar-selector: ok'
