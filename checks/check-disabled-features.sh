#!/usr/bin/env bash
set -euo pipefail

# This check intentionally covers the legacy standalone plan finish helper
# at tools/legacy/finish-preview.go. The active write-capable path is tools/edit
# (BQN editor + shell safe-write). Keep this legacy helper preview-only until
# it is either removed or archived.

# Get the physical directory of the script
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

tmp_bin="$(mktemp /tmp/bqn-ledger-finish-disabled.XXXXXX)"
tmp_out="$(mktemp /tmp/bqn-ledger-disabled-output.XXXXXX)"
tmp_base="$(mktemp -d /tmp/bqn-ledger-finish-fixture.XXXXXX)"
trap 'rm -f "$tmp_bin" "$tmp_out"; rm -rf "$tmp_base"' EXIT

BASE="${1:-data}"

before_journal="$(cksum "$BASE/journal.tsv")"
before_plan="$(cksum "$BASE/plan.tsv")"

go vet tools/legacy/finish-preview.go
go build -o "$tmp_bin" tools/legacy/finish-preview.go
"$tmp_bin" --base "$BASE" --index 1 --actual-date 2026-06-11 >"$tmp_out"
rg -q "Preview only. No files will be modified." "$tmp_out"
rg -q "Plan action:" "$tmp_out"
rg -q "UNCHANGED" "$tmp_out"

if [[ "$before_journal" != "$(cksum "$BASE/journal.tsv")" ]]; then
  echo "FAIL: preview finish command changed journal.tsv" >&2
  exit 1
fi
if [[ "$before_plan" != "$(cksum "$BASE/plan.tsv")" ]]; then
  echo "FAIL: preview finish command changed plan.tsv" >&2
  exit 1
fi

printf '%s\n' \
  'assets:bank' \
  'expenses:rent' \
  >"$tmp_base/accounts.tsv"
printf '%s\n' \
  $'2026-06-15\trent\tassets:bank\texpenses:rent\t64000\trecur=cycle\tanchor=income:pension\toffset=0\tseries=rent\ttax=private' \
  >"$tmp_base/plan.tsv"
printf '%s\n' \
  $'2026-06-01\topening\tassets:bank\texpenses:rent\t1' \
  >"$tmp_base/journal.tsv"

fixture_plan_before="$(cksum "$tmp_base/plan.tsv")"
fixture_journal_before="$(cksum "$tmp_base/journal.tsv")"
"$tmp_bin" --base "$tmp_base" --index 1 --actual-date 2026-06-16 >"$tmp_out"
rg -q $'2026-06-16\trent\tassets:bank\texpenses:rent\t64000\tseries=rent\ttax=private' "$tmp_out"
if rg -q 'recur=cycle\|anchor=income:pension\|offset=0' "$tmp_out"; then
  echo "FAIL: preview journal candidate retained plan-only metadata" >&2
  exit 1
fi
if [[ "$fixture_plan_before" != "$(cksum "$tmp_base/plan.tsv")" ]]; then
  echo "FAIL: preview finish command changed fixture plan.tsv" >&2
  exit 1
fi
if [[ "$fixture_journal_before" != "$(cksum "$tmp_base/journal.tsv")" ]]; then
  echo "FAIL: preview finish command changed fixture journal.tsv" >&2
  exit 1
fi
if "$tmp_bin" --base "$tmp_base" --index 1 --actual-date 2026-02-30 >"$tmp_out" 2>&1; then
  echo "FAIL: preview finish command accepted an invalid date" >&2
  exit 1
fi
rg -q "invalid date" "$tmp_out"

echo "OK"
