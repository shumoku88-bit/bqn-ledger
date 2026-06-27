#!/usr/bin/env bash
# tools/scaffold-check.sh
# Generate a new check script boilerplate under checks/.
#
# Usage:
#   tools/scaffold-check.sh <check-name>
#
# Example:
#   tools/scaffold-check.sh my-new-fixture-test
#   → creates checks/check-my-new-fixture-test.sh with boilerplate

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: tools/scaffold-check.sh <check-name>

Generate a new checks/check-<name>.sh with boilerplate:
  - repo root resolution
  - temp dir + trap cleanup
  - assert helper function
  - PASS/FAIL counter
  - summary at exit

The generated script is marked executable.
USAGE
  exit 1
}

NAME="${1:-}"
[ -z "$NAME" ] && usage

# Resolve repo root
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

OUTFILE="$ROOT_DIR/checks/check-${NAME}.sh"

if [ -f "$OUTFILE" ]; then
  echo "ERROR: $OUTFILE already exists." >&2
  exit 1
fi

cat > "$OUTFILE" << 'TEMPLATE'
#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-__NAME__.sh
# __PURPOSE__

# Resolve repo root
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# ── Test state ──
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

# ── Temp dir ──
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# ── Assert helpers ──
assert_eq() {
  local expected="$1" actual="$2" label="${3:-}"
  if [ "$expected" = "$actual" ]; then
    pass
  else
    fail "${label:-assert_eq}: expected [$expected] got [$actual]"
  fi
}

assert_contains() {
  local needle="$1" haystack="$2" label="${3:-}"
  if echo "$haystack" | grep -qF "$needle"; then
    pass
  else
    fail "${label:-assert_contains}: [$needle] not found"
  fi
}

# ── Tests ──
# TODO: add test cases here

# ── Summary ──
echo "check-__NAME__: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
TEMPLATE

# Replace placeholders
sed -i '' "s/__NAME__/${NAME}/g" "$OUTFILE"
sed -i '' "s/__PURPOSE__/Check: ${NAME}/" "$OUTFILE"

chmod +x "$OUTFILE"
echo "Created: $OUTFILE" >&2
