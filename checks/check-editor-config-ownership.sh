#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-editor-config.XXXXXX")
trap 'rm -rf "$work"' EXIT

modules=(
  src/application/config_rows.bqn
  src/application/system_defaults.bqn
  src/application/editor_config_path.bqn
  src/application/actual_journal_config.bqn
  src/application/editor_plan_budget_config.bqn
)
if rg -n '•SH|POLICY_(BUDGET|RISK|INCOME)|HOUSEHOLD_GROUP' "${modules[@]}" >/dev/null; then
  echo 'FAIL: editor config owner gained old runtime/report policy or shell fallback' >&2; exit 1
fi
bqn tests/test_application_editor_config.bqn >/dev/null

mkdir "$work/no-config"
actual_file="$(bqn src_edit/actual_journal_file_cmd.bqn "$work/no-config")"
[[ "$actual_file" == "actual.journal" ]] || { echo 'FAIL: Actual writer target is not canonical actual.journal' >&2; exit 1; }

printf 'ACTUAL_JOURNAL_FILE=legacy.journal\n' >"$work/no-config/config.tsv"
actual_file="$(bqn src_edit/actual_journal_file_cmd.bqn "$work/no-config")"
[[ "$actual_file" == "actual.journal" ]] || { echo 'FAIL: legacy config redirected canonical Actual writer target' >&2; exit 1; }

if rg -n 'ACTUAL_JOURNAL_FILE|config\.tsv|editor_config_path|actual_journal_admission' \
  src/application/actual_journal_config.bqn src_edit/actual_journal_file_cmd.bqn; then
  echo 'FAIL: canonical Actual target still depends on legacy config admission' >&2
  exit 1
fi

mkdir "$work/base"
printf 'BUDGET_ID_SPENT=budget:spent\n' >"$work/base/config.tsv"
if bqn -e 'c←•Import "src/application/editor_plan_budget_config.bqn" ⋄ x←c.Load "'"$work/base"'" ⋄ •Out x.BudgetPrefix @' \
  >"$work/missing.out" 2>&1; then
  echo 'FAIL: missing required Plan/Budget editor config succeeded' >&2; exit 1
fi
grep -F 'missing value for BUDGET_PREFIX' "$work/missing.out" >/dev/null
if grep -Eq '^budget:' "$work/missing.out"; then
  echo 'FAIL: missing Plan/Budget editor config published a fabricated value' >&2; exit 1
fi

echo 'check-editor-config-ownership: OK'
