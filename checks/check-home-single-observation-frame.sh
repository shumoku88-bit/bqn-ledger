#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-home-frame.XXXXXX")"
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

# Explicit frame mode publishes the rendered calendar and semantic CellRelation
# from one application observation, separated only by a physical protocol marker.
frame="$(tools/home-calendar "$base" 2026-01-20 frame)"
for expected in \
  '2026-01' \
  'Mo  Tu  We  Th  Fr  Sa  Su' \
  '20?' \
  'HOME_CURSOR_CELLS' \
  $'2026-01-01\t0\t3\t 1 ' \
  $'2026-01-20\t3\t1\t20?'; do
  grep -Fq "$expected" <<<"$frame" || {
    echo "FAIL: Home frame publication missing: $expected" >&2
    printf '%s\n' "$frame" >&2
    exit 1
  }
done

# Count actual BQN application launches for the first visible TTY frame. A q-only
# session must need exactly one home_calendar_cli invocation, and that invocation
# must request frame rather than separate calendar/cells observations.
real_bqn="$(command -v bqn)"
mkdir -p "$work/bin"
cat >"$work/bin/bqn" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${HOME_FRAME_CALL_LOG:?}"
: "${REAL_BQN:?}"
printf '%s\t' "$@" >>"$HOME_FRAME_CALL_LOG"
printf '\n' >>"$HOME_FRAME_CALL_LOG"
exec "$REAL_BQN" "$@"
SH
chmod +x "$work/bin/bqn"
: >"$work/calls.log"

python3 - "$base" "$work/tty.out" "$work/bin" "$work/calls.log" "$real_bqn" <<'PY'
import fcntl
import os
import pty
import sys
import termios

base, output_path, shim_bin, call_log, real_bqn = sys.argv[1:6]
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
    env["PATH"] = shim_bin + os.pathsep + env["PATH"]
    env["HOME_FRAME_CALL_LOG"] = call_log
    env["REAL_BQN"] = real_bqn
    os.execve(
        "tools/home-calendar",
        ["tools/home-calendar", base, "2026-01-20"],
        env,
    )

os.close(slave)
os.write(master, b"q")
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
    raise SystemExit(f"Home single-frame PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

mapfile -t calls <"$work/calls.log"
if ((${#calls[@]} != 1)); then
  echo "FAIL: initial Home frame launched ${#calls[@]} BQN applications, expected exactly 1" >&2
  cat "$work/calls.log" >&2
  exit 1
fi
case "${calls[0]}" in
  *$'src/application/home_calendar_cli.bqn\t'"$base"$'\t2026-01-20\tframe\t') ;;
  *)
    echo 'FAIL: initial Home BQN application did not request one frame publication' >&2
    cat "$work/calls.log" >&2
    exit 1
    ;;
esac

for expected in \
  '2026-01' \
  'Home date: 2026-01-20' \
  '20?'; do
  grep -Fq "$expected" "$work/tty.out" || {
    echo "FAIL: q-only Home frame missing visible evidence: $expected" >&2
    cat "$work/tty.out" >&2
    exit 1
  }
done

python3 - "$work/tty.out" <<'PY'
import sys
raw = open(sys.argv[1], "rb").read()
if b"\x1b[7m20?\x1b[0m" not in raw:
    raise SystemExit("FAIL: single-observation Home frame lost selected-cell highlight")
PY

# A cursor publication failure is an application failure, not navigation/back.
# Keep the canonical diagnostic and original status visible even before the
# alternate screen has been entered.
cat >"$work/bin/bqn" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${REAL_BQN:?}"
last="${!#:-}"
if [[ $last == frame ]]; then
  printf 'ERROR\thome_frame_fixture_failure\tfixture cursor-frame failure\n'
  exit 7
fi
exec "$REAL_BQN" "$@"
SH
chmod +x "$work/bin/bqn"

python3 - "$base" "$work/failure.out" "$work/bin" "$real_bqn" <<'PY'
import fcntl
import os
import pty
import sys
import termios

base, output_path, shim_bin, real_bqn = sys.argv[1:5]
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
    env["PATH"] = shim_bin + os.pathsep + env["PATH"]
    env["REAL_BQN"] = real_bqn
    os.execve(
        "tools/home-calendar",
        ["tools/home-calendar", base, "2026-01-20"],
        env,
    )

os.close(slave)
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
if exit_status != 7:
    raise SystemExit(f"Home frame failure became status {exit_status}, expected 7")
with open(output_path, "wb") as f:
    f.write(output)
PY

grep -Fq 'ERROR'$'\t''home_frame_fixture_failure'$'\t''fixture cursor-frame failure' "$work/failure.out" || {
  echo 'FAIL: Home frame failure diagnostic was hidden by shell capture' >&2
  cat "$work/failure.out" >&2
  exit 1
}

echo 'check-home-single-observation-frame: ok'
