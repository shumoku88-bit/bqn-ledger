#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-command-hub-home.XXXXXX")"
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

bash -n tools/bl

direct="$(tools/home-calendar "$base" 2026-01-20)"
hub_direct="$(tools/bl --base "$base" home 2026-01-20)"
[[ "$hub_direct" == "$direct" ]] || {
  echo 'FAIL: tools/bl home differs from canonical Home calendar command' >&2
  exit 1
}

python3 - "$base" "$work/home.out" <<'PY'
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
        "tools/bl",
        ["tools/bl", "--base", base, "--latest", "2026-01-20"],
        env,
    )

os.close(slave)
os.write(master, b"4\n")
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
    raise SystemExit(f"Command Hub Home PTY failed with status {exit_status}")
with open(output_path, "wb") as f:
    f.write(output)
PY

out="$work/home.out"
for expected in \
  '2026-01' \
  'Mo  Tu  We  Th  Fr  Sa  Su' \
  '20?' \
  'Editor' 'Reports' 'Source & System' 'Exit'; do
  grep -Fq "$expected" "$out" || {
    echo "FAIL: Command Hub Home entrance missing: $expected" >&2
    cat "$out" >&2
    exit 1
  }
done

# Home is an observation header, not a fifth interaction category.
if grep -Eq '^[[:space:]]*[0-9]+\)[[:space:]]+Home[[:space:]]*$' "$out"; then
  echo 'FAIL: Home became a selectable top-level category' >&2
  cat "$out" >&2
  exit 1
fi
grep -Fq 'Select [0-4]>' "$out" || {
  echo 'FAIL: Command Hub top menu no longer has exactly four choices' >&2
  cat "$out" >&2
  exit 1
}

# The shell remains an adapter: Home meaning and rendering stay delegated.
grep -Fq 'tools/home-calendar' tools/bl
grep -Fq 'select_menu "BQN-Ledger Command Hub' tools/bl

echo 'check-command-hub-home: OK'
