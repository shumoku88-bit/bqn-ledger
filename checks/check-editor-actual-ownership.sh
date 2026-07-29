#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-editor-actual.XXXXXX")
trap 'rm -rf "$work"' EXIT

if rg -n '•SH|/data/|fallbackId|physical_fallback' src/application/editor_actual.bqn >/dev/null; then
  echo 'FAIL: strict editor Actual owner gained old runtime, path fallback, or fabricated identity' >&2; exit 1
fi
bqn tests/test_application_editor_actual.bqn >/dev/null

cp -R fixtures/plan-completion "$work/implicit"
python3 - "$work/implicit/accounts.tsv" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
p.write_text(p.read_text().replace('\tcurrency=JPY', '', 1))
PY
if bqn src_edit/journal_list_cmd.bqn "$work/implicit" tsv >"$work/implicit.out" 2>&1; then
  echo 'FAIL: implicit Account currency entered strict editor Actual facts' >&2; exit 1
fi
grep -F 'native Journal source rejected' "$work/implicit.out" >/dev/null

cp -R fixtures/plan-completion "$work/no-config"
rm "$work/no-config/config.tsv"
if bqn src_edit/journal_list_cmd.bqn "$work/no-config" tsv >"$work/no-config.out" 2>&1; then
  echo 'FAIL: missing explicit Actual config succeeded' >&2; exit 1
fi
grep -F 'config source is not readable' "$work/no-config.out" >/dev/null

echo 'check-editor-actual-ownership: OK'
