#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

base="fixtures/src-next-golden"

# Explicit consumer-specific O reaches the human Outlook section through the
# production wrapper.
out="$(tools/report "$base" --section outlook --outlook-as-of 2026-06-18 --no-color)"
if ! grep -Fq '2026-06-18' <<<"$out"; then
  echo "FAIL: explicit --outlook-as-of did not reach Outlook output" >&2
  exit 1
fi

# Missing explicit value fails closed.
set +e
missing_out="$(tools/report "$base" --section outlook --outlook-as-of --no-color 2>&1)"
missing_status=$?
set -e
if [[ $missing_status -eq 0 ]]; then
  echo "FAIL: missing --outlook-as-of value unexpectedly succeeded" >&2
  exit 1
fi
if ! grep -Fq 'ERROR: --outlook-as-of requires YYYY-MM-DD' <<<"$missing_out"; then
  echo "FAIL: missing --outlook-as-of value did not report expected error" >&2
  exit 1
fi

# Invalid Gregorian date fails closed rather than falling back to Today.
set +e
invalid_out="$(tools/report "$base" --section outlook --outlook-as-of 2026-02-30 --no-color 2>&1)"
invalid_status=$?
set -e
if [[ $invalid_status -eq 0 ]]; then
  echo "FAIL: invalid --outlook-as-of date unexpectedly succeeded" >&2
  exit 1
fi
if ! grep -Fq 'ERROR: invalid --outlook-as-of date: 2026-02-30' <<<"$invalid_out"; then
  echo "FAIL: invalid --outlook-as-of date did not report expected error" >&2
  exit 1
fi

# The Outlook-specific O flag must not redefine another section's output.
snapshot_a="$(tools/report "$base" --section snapshot --outlook-as-of 2026-06-18 --no-color)"
snapshot_b="$(tools/report "$base" --section snapshot --outlook-as-of 2026-06-19 --no-color)"
if [[ "$snapshot_a" != "$snapshot_b" ]]; then
  echo "FAIL: Outlook-specific observation changed snapshot section output" >&2
  diff -u <(printf '%s\n' "$snapshot_a") <(printf '%s\n' "$snapshot_b") >&2 || true
  exit 1
fi

echo "check-src-next-outlook-observation-source.sh: OK"
