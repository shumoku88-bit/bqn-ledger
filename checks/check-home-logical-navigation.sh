#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-home-navigation.XXXXXX")"
trap 'rm -rf "$work"' EXIT
base="$work/household"
cp -R fixtures/canonical-household-v1 "$base"

# Public explicit movement modes are source-free logical Home navigation.
[[ "$(tools/home-calendar "$base" 2026-01-28 week-next)" == '2026-02-04' ]] || {
  echo 'FAIL: Home week-next did not cross the month boundary continuously' >&2
  exit 1
}
[[ "$(tools/home-calendar "$base" 2026-01-05 week-prev)" == '2025-12-29' ]] || {
  echo 'FAIL: Home week-prev did not cross the year boundary continuously' >&2
  exit 1
}

# An explicit focus date is already the logical coordinate. Pure movement must
# not read the application clock merely because date_today is available.
mkdir -p "$work/bin"
cat >"$work/bin/date" <<'SH'
#!/usr/bin/env bash
echo 'FAIL: pure Home movement touched the clock' >&2
exit 77
SH
chmod +x "$work/bin/date"
clock_free="$(PATH="$work/bin:$PATH" tools/home-calendar "$base" 2026-01-28 week-next)" || {
  echo 'FAIL: explicit Home movement depended on date(1)' >&2
  exit 1
}
[[ "$clock_free" == '2026-02-04' ]] || {
  echo 'FAIL: clock-free Home movement changed logical result' >&2
  exit 1
}

# The terminal Down key maps to the same logical week-next action. Start on the
# last Wednesday of January and cross into the first Wednesday of February.
python3 - "$base" "$work/down.out" <<'PY'
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
        ["tools/home-calendar", base, "2026-01-28"],
        env,
    )

os.close(slave)
os.write(master, b"\x1b[Bq")
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
    raise SystemExit(f"Home logical-navigation PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

for expected in \
  'Home date: 2026-01-28' \
  'Home date: 2026-02-04' \
  '2026-01' \
  '2026-02'; do
  grep -Fq "$expected" "$work/down.out" || {
    echo "FAIL: Home logical-navigation output missing: $expected" >&2
    cat "$work/down.out" >&2
    exit 1
  }
done

echo 'check-home-logical-navigation: OK'
