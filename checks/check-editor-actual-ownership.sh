#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-editor-actual.XXXXXX")
trap 'rm -rf "$work"' EXIT

if rg -n '•SH|/data/|fallbackId|physical_fallback|accounts\.tsv|config\.tsv|ACTUAL_JOURNAL_FILE|report_source_adapter\.bqn' src/application/editor_actual.bqn >/dev/null; then
  echo 'FAIL: strict editor Actual owner gained legacy source, Report aggregate dependency, path fallback, or fabricated identity' >&2; exit 1
fi
grep -Fq 'actualSource ← •Import "actual_source_adapter.bqn"' src/application/editor_actual.bqn \
  || { echo 'FAIL: editor Actual must use the canonical Actual source owner directly' >&2; exit 1; }
if rg -n 'accounts\.tsv|editor_accounts\.bqn' src_edit/journal_block_add_cmd.bqn >/dev/null; then
  echo 'FAIL: native Journal append still reads legacy Account TSV evidence' >&2; exit 1
fi
grep -F 'account_source_adapter.bqn' src_edit/journal_block_add_cmd.bqn >/dev/null \
  || { echo 'FAIL: native Journal append does not use canonical Account source owner' >&2; exit 1; }
bqn tests/test_application_editor_actual.bqn >/dev/null

cp -R fixtures/plan-completion "$work/baseline"
bqn src_edit/journal_list_cmd.bqn "$work/baseline" tsv >"$work/baseline.out"

# Legacy Account TSV cannot influence canonical Actual admission.
cp -R fixtures/plan-completion "$work/legacy-accounts"
printf 'broken\tlegacy\n' >"$work/legacy-accounts/accounts.tsv"
bqn src_edit/journal_list_cmd.bqn "$work/legacy-accounts" tsv >"$work/legacy-accounts.out"
cmp "$work/baseline.out" "$work/legacy-accounts.out"

# Legacy config cannot select or disable canonical actual.journal.
cp -R fixtures/plan-completion "$work/no-config"
rm -f "$work/no-config/config.tsv"
bqn src_edit/journal_list_cmd.bqn "$work/no-config" tsv >"$work/no-config.out"
cmp "$work/baseline.out" "$work/no-config.out"
printf 'ACTUAL_JOURNAL_FILE=missing.journal\n' >"$work/no-config/config.tsv"
bqn src_edit/journal_list_cmd.bqn "$work/no-config" tsv >"$work/redirect.out"
cmp "$work/baseline.out" "$work/redirect.out"

# Canonical Account evidence remains mandatory.
cp -R fixtures/plan-completion "$work/invalid-canonical"
printf 'account broken\n  type: Unknown\n' >"$work/invalid-canonical/accounts.journal"
if bqn src_edit/journal_list_cmd.bqn "$work/invalid-canonical" tsv >"$work/invalid-canonical.out" 2>&1; then
  echo 'FAIL: invalid canonical Accounts succeeded' >&2; exit 1
fi
grep -F 'canonical Actual source rejected' "$work/invalid-canonical.out" >/dev/null

echo 'check-editor-actual-ownership: OK'
