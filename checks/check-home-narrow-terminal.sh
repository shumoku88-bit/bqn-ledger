#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-home-narrow.XXXXXX")"
trap 'rm -rf "$work"' EXIT
base="$work/household"
cp -R fixtures/canonical-household-v1 "$base"

python3 - "$base" "$work/narrow.out" <<'PY'
import fcntl
import os
import pty
import struct
import sys
import termios

base, output_path = sys.argv[1:3]
master, slave = pty.openpty()
fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 14, 40, 0, 0))
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
        ["tools/home-calendar", base, "2026-01-10"],
        env,
    )

os.close(slave)
os.write(master, b"\nq")
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
    raise SystemExit(f"Home narrow-terminal PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

python3 - "$work/narrow.out" <<'PY'
import sys
raw = open(sys.argv[1], "rb").read()
for expected, message in (
    (b"\x1b[?7l", "Home did not disable terminal autowrap"),
    (b"\x1b[?7h", "Home did not restore terminal autowrap"),
    (b"--- Selected date detail ---", "narrow Home did not open detail viewport"),
    (b"2026-01", "narrow Home lost calendar frame"),
    (b"Home date: 2026-01-10", "narrow Home lost selected date"),
):
    if expected not in raw:
        raise SystemExit("FAIL: " + message)
PY

echo 'check-home-narrow-terminal: ok'
