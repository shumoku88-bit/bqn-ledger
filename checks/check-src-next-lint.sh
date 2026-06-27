#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-src-next-lint.sh
# Ensures that report-next-summary outputs correct lint counts for invalid fixtures.

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

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

assert_eq() {
  local expected="$1" actual="$2" label="${3:-}"
  if [ "$expected" = "$actual" ]; then
    pass
  else
    fail "${label:-assert_eq}: expected [$expected] got [$actual]"
  fi
}

echo "Running src_next lint on fixtures/src-next-lint-failures..." >&2
out=$(tools/report-next-summary fixtures/src-next-lint-failures 2>/dev/null || true)

# Helper to extract a value by key
get_val() {
  local key="$1"
  echo "$out" | awk -F': ' -v k="$key" '$1 == k { print $2; exit }'
}

unknown_acc=$(get_val "src_next_readiness_unknown_account_count")
unknown_role=$(get_val "src_next_readiness_unknown_role_accounts_count")
unknown_type=$(get_val "src_next_readiness_unknown_type_accounts_count")
unknown_spend=$(get_val "src_next_readiness_unknown_spend_class_accounts_count")
dup_acc=$(get_val "src_next_readiness_duplicate_accounts_count")
dup_keys=$(get_val "src_next_readiness_accounts_with_dup_keys_count")

assert_eq "2" "$unknown_acc" "unknown account references (2 projection rows)"
assert_eq "1" "$unknown_role" "unknown role account (magical)"
assert_eq "0" "$unknown_type" "unknown type accounts"
assert_eq "1" "$unknown_spend" "unknown spend_class account (maybe)"
assert_eq "1" "$dup_acc" "duplicate account definitions (expenses:food)"
assert_eq "1" "$dup_keys" "accounts with duplicate keys (assets:bank has 2 type keys)"

echo "check-src-next-lint: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
