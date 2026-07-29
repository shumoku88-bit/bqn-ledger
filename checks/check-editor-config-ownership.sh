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
  src/application/actual_journal_admission.bqn
  src/application/actual_journal_config.bqn
  src/application/editor_plan_budget_config.bqn
)
if rg -n '•SH|POLICY_(BUDGET|RISK|INCOME)|HOUSEHOLD_GROUP' "${modules[@]}" >/dev/null; then
  echo 'FAIL: editor config owner gained old runtime/report policy or shell fallback' >&2; exit 1
fi
bqn tests/test_application_editor_config.bqn >/dev/null

mkdir "$work/no-config"
if bqn src_edit/actual_journal_file_cmd.bqn "$work/no-config" >"$work/no-config.out" 2>&1; then
  echo 'FAIL: missing explicit editor config fell back to repository defaults' >&2; exit 1
fi
grep -F 'config source is not readable' "$work/no-config.out" >/dev/null

mkdir "$work/base"
printf 'BUDGET_ID_SPENT=budget:spent\n' >"$work/base/config.tsv"
if bqn -e 'c←•Import "src/application/editor_plan_budget_config.bqn" ⋄ x←c.Load "'"$work/base"'" ⋄ •Out x.BudgetPrefix @' \
  >"$work/missing.out" 2>&1; then
  echo 'FAIL: missing required editor config succeeded' >&2; exit 1
fi
grep -F 'missing value for BUDGET_PREFIX' "$work/missing.out" >/dev/null
if grep -Eq '^budget:' "$work/missing.out"; then
  echo 'FAIL: missing editor config published a fabricated value' >&2; exit 1
fi

printf 'ACTUAL_JOURNAL_FILE=one.journal\nACTUAL_JOURNAL_FILE=two.journal\n' >"$work/base/config.tsv"
if bqn src_edit/actual_journal_file_cmd.bqn "$work/base" >"$work/duplicate.out" 2>&1; then
  echo 'FAIL: duplicate Actual Journal config succeeded' >&2; exit 1
fi
grep -F 'duplicate value for ACTUAL_JOURNAL_FILE' "$work/duplicate.out" >/dev/null

echo 'check-editor-config-ownership: OK'
