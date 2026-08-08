#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-report-presentation.XXXXXX")
trap 'rm -rf "$work"' EXIT
trap 'status=$?; echo "FAIL: check-report-presentation-policy line $LINENO" >&2; echo "::error file=checks/check-report-presentation-policy.sh,line=$LINENO::Report presentation policy check failed" >&2; exit "$status"' ERR
cp -R "$fixture" "$work/base"
base="$work/base"

bqn src/application/report_presentation_cli.bqn "$base" >"$work/presentation"
grep -Fx $'negative_style\tminus' "$work/presentation" >/dev/null
grep -Fx $'negative_color\tred' "$work/presentation" >/dev/null
grep -Fx $'daily_flow_max_date_columns\t5' "$work/presentation" >/dev/null

./tools/report "$base" balances human JPY 2026-01-12 >"$work/minus"
grep -F 'income:salary' "$work/minus" | grep -F -- '-1000' >/dev/null

python3 - "$base/report.toml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old_style = 'negative-style = "minus"'
new_style = 'negative-style = "parentheses"'
old_color = 'negative-color = "red"'
new_color = 'negative-color = "cyan"'
if s.count(old_style) != 1:
    raise SystemExit('expected one negative-style')
if s.count(old_color) != 1:
    raise SystemExit('expected one negative-color')
p.write_text(s.replace(old_style, new_style).replace(old_color, new_color))
PY
./tools/report "$base" balances human JPY 2026-01-12 >"$work/parentheses"
grep -F 'income:salary' "$work/parentheses" | grep -F '(1000)' >/dev/null
if grep -F 'income:salary' "$work/parentheses" | grep -F -- '-1000' >/dev/null; then
  echo 'FAIL: human Report ignored canonical parentheses notation' >&2
  exit 1
fi
# Compact ledger_* values stay signed machine data, not presentation prose.
./tools/report "$base" balances compact JPY 2026-01-12 >"$work/compact"
grep -F 'ledger_balance: income:salary/JPY -1000' "$work/compact" >/dev/null

# The Command Hub owns terminal adaptation, but report.toml owns the color token.
# A pre-existing environment value cannot replace the admitted canonical policy.
env -u NO_COLOR COLOR_FORCE=1 BL_THEME=classic REPORT_NEGATIVE_COLOR=red \
  ./tools/main-ui.sh --base "$base" --domain JPY --latest 2026-01-12 balances >"$work/command-hub-color"
grep -F $'\033[36m(1000)\033[0m' "$work/command-hub-color" >/dev/null
if grep -F $'\033[31m(1000)\033[0m' "$work/command-hub-color" >/dev/null; then
  echo 'FAIL: Command Hub environment overrode canonical Report color policy' >&2
  exit 1
fi

# Terminal color remains a presentation-layer concern and NO_COLOR still wins.
printf 'value -12\n' | env -u NO_COLOR COLOR_FORCE=1 BL_THEME=classic REPORT_NEGATIVE_COLOR=cyan \
  bash tools/lib/color-filter >"$work/color"
grep -F $'\033[36m-12\033[0m' "$work/color" >/dev/null

printf 'value -12\n' | NO_COLOR=1 REPORT_NEGATIVE_COLOR=cyan bash tools/lib/color-filter >"$work/plain"
grep -Fx 'value -12' "$work/plain" >/dev/null

echo 'check-report-presentation-policy: OK'
