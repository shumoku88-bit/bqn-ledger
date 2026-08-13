#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-home-selector.XXXXXX")"
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

# Non-TTY callers retain the calendar contract. An explicit calendar mode is
# identical, and BQN owns the selector key/label relation.
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

# Exercise the terminal-only selector with the plain adapter. Day 20 is the
# twentieth semantic choice because BQN publishes source-ordered month days.
python3 - "$base" "$work/selector.out" <<'PY'
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
    env["BL_SELECTOR"] = "plain"
    env["NO_COLOR"] = "1"
    os.execve(
        "tools/home-calendar",
        ["tools/home-calendar", base, "2026-01-20"],
        env,
    )

os.close(slave)
os.write(master, b"20\n")
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
    raise SystemExit(f"Home selector PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

out="$work/selector.out"
for expected in \
  '2026-01' \
  'Mo  Tu  We  Th  Fr  Sa  Su' \
  '20?' \
  '=== Home date ===' \
  '2026-01-20' \
  'Actual' \
  '(none)' \
  'ISSUE-001' \
  'Synthetic reminder' \
  'Fixture-only evidence'; do
  grep -Fq "$expected" "$out" || {
    echo "FAIL: Home date selector output missing: $expected" >&2
    cat "$out" >&2
    exit 1
  }
done

echo 'check-home-calendar-selector: ok'
