#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tools/lib/safe-write.sh
source tools/lib/safe-write.sh
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
sha() { _safe_write_sha256 "$1"; }
no_backup() { [[ ! -d "$1/.backup" ]] || ! find "$1/.backup" -type f | grep -q .; }

# Successful rewrite: exact bytes, one exact backup, and permissions preserved.
base="$tmp/success"; mkdir -p "$base"; target="$base/file"; candidate="$tmp/candidate"
printf 'original\nbytes' >"$target"; chmod 640 "$target"; printf 'candidate\nbytes\n' >"$candidate"
original_sha="$(sha "$target")"; IFS=$'\t' read -r size mtime digest <<<"$(safe_snapshot_token "$target")"
out="$(safe_rewrite_checked "$target" "$candidate" "$size" "$mtime" "$digest")"
backup="$(awk -F': ' '$1=="Backup"{print $2}' <<<"$out")"
cmp -s "$target" "$candidate" || { echo 'FAIL: candidate not published' >&2; exit 1; }
[[ "$(sha "$backup")" == "$original_sha" ]] || { echo 'FAIL: backup differs' >&2; exit 1; }
[[ "$(find "$base/.backup" -type f | wc -l | tr -d ' ')" == 1 ]] || { echo 'FAIL: backup count' >&2; exit 1; }
mode="$(stat -f %Lp "$target" 2>/dev/null || stat -c %a "$target")"; [[ "$mode" == 640 ]] || { echo 'FAIL: mode changed' >&2; exit 1; }

# Stale before backup.
base="$tmp/stale"; mkdir -p "$base"; target="$base/file"; printf old >"$target"; printf new >"$candidate"
IFS=$'\t' read -r size mtime digest <<<"$(safe_snapshot_token "$target")"; printf changed >"$target"
if safe_rewrite_checked "$target" "$candidate" "$size" "$mtime" "$digest" >/dev/null 2>&1; then echo 'FAIL: stale accepted' >&2; exit 1; fi
no_backup "$base" || { echo 'FAIL: stale created backup' >&2; exit 1; }

# Stale immediately before rename: later bytes stay, candidate is not published, backup removed.
base="$tmp/race"; mkdir -p "$base"; target="$base/file"; printf old >"$target"; printf candidate >"$candidate"
IFS=$'\t' read -r size mtime digest <<<"$(safe_snapshot_token "$target")"
race_hook() { printf later-writer >"$target"; }
if BQN_LEDGER_TEST_MODE=1 SAFE_WRITE_TEST_BEFORE_REWRITE_RENAME_HOOK=race_hook safe_rewrite_checked "$target" "$candidate" "$size" "$mtime" "$digest" >/dev/null 2>&1; then echo 'FAIL: race accepted' >&2; exit 1; fi
[[ "$(cat "$target")" == later-writer ]] || { echo 'FAIL: race published candidate' >&2; exit 1; }
no_backup "$base" || { echo 'FAIL: pre-rename stale backup retained' >&2; exit 1; }

# Missing candidate is side-effect free.
base="$tmp/missing"; mkdir -p "$base"; target="$base/file"; printf old >"$target"; before="$(sha "$target")"
IFS=$'\t' read -r size mtime digest <<<"$(safe_snapshot_token "$target")"
if safe_rewrite_checked "$target" "$tmp/missing-candidate" "$size" "$mtime" "$digest" >/dev/null 2>&1; then echo 'FAIL: missing candidate accepted' >&2; exit 1; fi
[[ "$(sha "$target")" == "$before" ]] && no_backup "$base" || { echo 'FAIL: missing candidate side effect' >&2; exit 1; }

# Existing checked append and replace APIs remain callable.
base="$tmp/regression"; mkdir -p "$base"; target="$base/file"; printf 'one\ntwo\n' >"$target"
IFS=$'\t' read -r size mtime digest <<<"$(safe_snapshot_token "$target")"; safe_append_checked "$target" three "$size" "$mtime" "$digest" >/dev/null
IFS=$'\t' read -r size mtime digest <<<"$(safe_snapshot_token "$target")"; safe_replace_line_checked "$target" 2 two TWO "$size" "$mtime" "$digest" >/dev/null
grep -Fqx THREE "$target" && { echo 'FAIL: unexpected append normalization' >&2; exit 1; } || true
grep -Fqx TWO "$target" && grep -Fqx three "$target" || { echo 'FAIL: append/replace regression' >&2; exit 1; }

printf 'OK safe_rewrite_checked\n'
