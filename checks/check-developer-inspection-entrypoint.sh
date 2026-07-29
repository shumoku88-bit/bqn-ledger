#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fixture="${1:-fixtures/editor-golden}"
new_out="$(mktemp)"
new_err="$(mktemp)"
old_out="$(mktemp)"
old_err="$(mktemp)"
trap 'rm -f "$new_out" "$new_err" "$old_out" "$old_err"' EXIT

set +e
bqn src_next/developer_inspection.bqn "$fixture" >"$new_out" 2>"$new_err"
new_status=$?
bqn src_next/main.bqn "$fixture" >"$old_out" 2>"$old_err"
old_status=$?
set -e

if [ "$new_status" -ne 0 ]; then
  echo "FAIL: named developer inspection entrypoint failed with status $new_status" >&2
  cat "$new_err" >&2
  exit 1
fi

if [ "$old_status" -ne "$new_status" ]; then
  echo "FAIL: main compatibility status differs: new=$new_status old=$old_status" >&2
  cat "$old_err" >&2
  exit 1
fi

if ! cmp -s "$new_out" "$old_out"; then
  echo "FAIL: main compatibility stdout differs from developer_inspection.bqn" >&2
  diff -u "$new_out" "$old_out" >&2 || true
  exit 1
fi

if ! cmp -s "$new_err" "$old_err"; then
  echo "FAIL: main compatibility stderr differs from developer_inspection.bqn" >&2
  diff -u "$new_err" "$old_err" >&2 || true
  exit 1
fi

if ! grep -Eq '^[[:space:]]*inspection[[:space:]]*←[[:space:]]*•Import[[:space:]]+"developer_inspection\.bqn"[[:space:]]*$' src_next/main.bqn; then
  echo "FAIL: src_next/main.bqn does not import the named inspection module" >&2
  exit 1
fi

if ! grep -Eq '^[[:space:]]*inspection\.Run[[:space:]]+⊑•args[[:space:]]*$' src_next/main.bqn; then
  echo "FAIL: src_next/main.bqn does not delegate its argument to inspection.Run" >&2
  exit 1
fi

if grep -Eq '^[[:space:]]*(Run|Main|PrintAccountKey|FormatProjTable|BalanceBySourceOk)[[:space:]]*←' src_next/main.bqn; then
  echo "FAIL: src_next/main.bqn contains diagnostic implementation" >&2
  exit 1
fi

if ! grep -Eq 'exec[[:space:]]+bqn[[:space:]]+src_next/developer_inspection\.bqn' tools/report-next; then
  echo "FAIL: tools/report-next does not use the named developer inspection entrypoint" >&2
  exit 1
fi

printf 'OK: developer inspection entrypoint and main compatibility wrapper passed\n'
