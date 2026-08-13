#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-home-detail-frame.XXXXXX")"
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

# The explicit application publication must contain all three semantic surfaces
# from one observation: calendar text, CellRelation, and complete detail evidence.
detail_frame="$(tools/home-calendar "$base" 2026-01-20 detail-frame)"
for expected in \
  '2026-01' \
  'Mo  Tu  We  Th  Fr  Sa  Su' \
  'HOME_CURSOR_CELLS' \
  $'2026-01-20\t3\t1\t20?' \
  'HOME_SELECTED_DETAIL' \
  '2026-01-20' \
  'Actual' \
  'ISSUE-001' \
  'Synthetic reminder' \
  'Fixture-only evidence'; do
  grep -Fq "$expected" <<<"$detail_frame" || {
    echo "FAIL: Home detail-frame publication missing: $expected" >&2
    printf '%s\n' "$detail_frame" >&2
    exit 1
  }
done

# Instrument interactive BQN launches. Initial Home uses one frame observation;
# Inspect uses exactly one detail-frame observation and never a separate detail
# observation that could be combined with an older calendar cache.
real_bqn="$(command -v bqn)"
mkdir -p "$work/bin"
cat >"$work/bin/bqn" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${HOME_DETAIL_CALL_LOG:?}"
: "${REAL_BQN:?}"
printf '%s\t' "$@" >>"$HOME_DETAIL_CALL_LOG"
printf '\n' >>"$HOME_DETAIL_CALL_LOG"
exec "$REAL_BQN" "$@"
SH
chmod +x "$work/bin/bqn"
: >"$work/calls.log"

python3 - "$base" "$work/tty.out" "$work/bin" "$work/calls.log" "$real_bqn" <<'PY'
import fcntl
import os
import pty
import struct
import sys
import termios

base, output_path, shim_bin, call_log, real_bqn = sys.argv[1:6]
master, slave = pty.openpty()
# Give the detail pane enough space to show the fixture while still exercising
# explicit terminal viewport geometry.
fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 100, 0, 0))
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
    env["HOME_DETAIL_CALL_LOG"] = call_log
    env["REAL_BQN"] = real_bqn
    os.execve(
        "tools/home-calendar",
        ["tools/home-calendar", base, "2026-01-20"],
        env,
    )

os.close(slave)
# Inspect, then q from the detail frame. q retains the Home/back 130 signal.
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
    raise SystemExit(f"Home detail-frame PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

mapfile -t calls <"$work/calls.log"
if ((${#calls[@]} != 2)); then
  echo "FAIL: Home inspect launched ${#calls[@]} BQN applications, expected frame + detail-frame" >&2
  cat "$work/calls.log" >&2
  exit 1
fi
case "${calls[0]}" in
  *$'src/application/home_calendar_cli.bqn\t'"$base"$'\t2026-01-20\tframe\t') ;;
  *)
    echo 'FAIL: initial Home publication was not frame' >&2
    cat "$work/calls.log" >&2
    exit 1
    ;;
esac
case "${calls[1]}" in
  *$'src/application/home_calendar_cli.bqn\t'"$base"$'\t2026-01-20\tdetail-frame\t') ;;
  *)
    echo 'FAIL: Inspect did not use one detail-frame publication' >&2
    cat "$work/calls.log" >&2
    exit 1
    ;;
esac
if grep -Fq $'\tdetail\t' "$work/calls.log"; then
  echo 'FAIL: interactive Inspect still launched a separate detail observation' >&2
  cat "$work/calls.log" >&2
  exit 1
fi

for expected in \
  '2026-01' \
  'Home date: 2026-01-20' \
  '--- Selected date detail ---' \
  'Actual' \
  'ISSUE-001' \
  'Synthetic reminder' \
  'Fixture-only evidence' \
  'scroll'; do
  grep -Fq -- "$expected" "$work/tty.out" || {
    echo "FAIL: Home detail viewport missing: $expected" >&2
    cat "$work/tty.out" >&2
    exit 1
  }
done
python3 - "$work/tty.out" <<'PY'
import sys
raw = open(sys.argv[1], "rb").read()
frames = raw.split(b"\x1b[H\x1b[2J")
panes = [frame for frame in frames if b"--- Selected date detail ---" in frame]
if not panes:
    raise SystemExit("FAIL: selected-date detail did not render in a Home frame")
frame = panes[-1]
for expected in (
    b"2026-01",
    b"Mo  Tu  We  Th  Fr  Sa  Su",
    b"\x1b[7m20?\x1b[0m",
    b"Home date: 2026-01-20",
    b"Actual",
    b"ISSUE-001",
):
    if expected not in frame:
        raise SystemExit(f"FAIL: detail viewport frame lost same-frame evidence: {expected!r}")
PY

# A canonical/detail publication failure is not Home/back. Fail only the
# detail-frame application with status 7, then require that status and diagnostic
# survive terminal cleanup instead of being collapsed to 130.
cat >"$work/bin/bqn" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${REAL_BQN:?}"
last="${!#:-}"
if [[ $last == detail-frame ]]; then
  printf 'ERROR\thome_detail_fixture_failure\tfixture detail-frame failure\n'
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
os.write(master, b"\n")
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
    raise SystemExit(f"Home detail failure became status {exit_status}, expected 7")
with open(output_path, "wb") as f:
    f.write(output)
PY

grep -Fq 'ERROR'$'\t''home_detail_fixture_failure'$'\t''fixture detail-frame failure' "$work/failure.out" || {
  echo 'FAIL: Home detail failure diagnostic was hidden by terminal cleanup' >&2
  cat "$work/failure.out" >&2
  exit 1
}

echo 'check-home-single-observation-detail-frame: ok'
