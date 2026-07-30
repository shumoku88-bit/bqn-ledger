#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }
trap 'status=$?; echo "FAIL: check-add-action-catalog line $LINENO status $status" >&2' ERR

bash -n tools/add || fail "tools/add syntax"
pass "tools/add syntax"

expected="$(mktemp)"
actual="$(mktemp)"
err="$(mktemp)"
trap 'rm -f "$expected" "$actual" "$err"' EXIT

bqn src/application/add_ui_action_catalog_cli.bqn >"$expected" \
  || fail "BQN action catalog CLI"
bash tools/add --list-actions >"$actual" \
  || fail "tools/add --list-actions"
cmp -s "$expected" "$actual" \
  || fail "tools/add list differs from BQN catalog"
pass "tools/add publishes BQN catalog exactly"

row_count="$(awk -F'\t' 'NF == 3 { count++ } END { print count + 0 }' "$actual")"
[[ "$row_count" -eq 12 ]] || fail "expected 12 action rows, found $row_count"
pass "action catalog has 12 admitted rows"

first="$(head -1 "$actual")"
last="$(tail -1 "$actual")"
[[ "$first" == $'account-add\tアカウント追加\taccount' ]] \
  || fail "unexpected first action row: $first"
[[ "$last" == $'issue-close\tIssues & Decisions を閉じる\tissue' ]] \
  || fail "unexpected last action row: $last"
pass "action order and labels are stable"

[[ "$(bash tools/add --select-only expense)" == "expense" ]] \
  || fail "direct action admission"
pass "direct action admission uses catalog"

if bash tools/add --select-only does-not-exist >"$actual" 2>"$err"; then
  fail "unknown action unexpectedly succeeded"
fi
grep -qF 'Unknown action mode: does-not-exist' "$err" \
  || fail "unknown action error missing"
pass "unknown action fails closed"

selected="$(printf '2\n' | ADD_SELECTOR=plain bash tools/add --select-only 2>/dev/null)"
[[ "$selected" == "expense" ]] || fail "plain selector returned: $selected"
pass "plain selector consumes BQN catalog rows"

grep -qF 'exec "$ROOT_DIR/tools/add-ui.sh" "${base_args[@]}" "$mode"' tools/add \
  || fail "launcher no longer delegates selected mode to add-ui"
pass "writer and mode execution remain delegated"

echo "OK: add action catalog checks passed" >&2
