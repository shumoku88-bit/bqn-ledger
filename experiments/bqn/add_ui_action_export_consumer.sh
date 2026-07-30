#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
probe="$repo_root/experiments/bqn/add_ui_action_export.bqn"
expected="$repo_root/experiments/bqn/add_ui_action_metadata.tsv"
raw="$(mktemp)"
exported="$(mktemp)"
menu="$(mktemp)"
trap 'rm -f "$raw" "$exported" "$menu"' EXIT

bqn "$probe" >"$raw"

awk '
  /^EXPORT_BEGIN$/ { inside=1; next }
  /^EXPORT_END$/ { inside=0; next }
  inside { print }
' "$raw" >"$exported"

diff -u "$expected" "$exported"
grep -Fx 'aligned coordinates: 1' "$raw" >/dev/null
grep -Fx 'unique keys: 1' "$raw" >/dev/null
grep -Fx 'duplicate variant unique: 0' "$raw" >/dev/null
grep -Fx 'known lookup: "ok"' "$raw" >/dev/null
grep -Fx 'unknown lookup: "unknown"' "$raw" >/dev/null

while IFS=$'\t' read -r key label family; do
  printf '%s\t%s\n' "$key" "$label"
done <"$exported" >"$menu"

[[ "$(wc -l <"$menu" | tr -d ' ')" == "12" ]]
grep -Fx $'expense\t支出' "$menu" >/dev/null
grep -Fx $'issue-close\tIssue終了' "$menu" >/dev/null

printf 'add_ui_action_export consumer: complete\n'
