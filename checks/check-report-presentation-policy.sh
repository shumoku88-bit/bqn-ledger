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

# Command Hub builds the full current human request set even when one section is
# displayed. Supply neutral prior-cycle evidence so this presentation proof can
# reach the terminal adapter without making Cycle Comparison the subject here.
cat >>"$base/actual.journal" <<'EOF'

2025-12-01 presentation prior income anchor
    ; event-id: presentation-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 presentation prior income neutralization
    ; event-id: presentation-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY
EOF
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 presentation historical next income
    ; plan-id: presentation-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

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

# Verify table column alignment is identical across rows in both minus and parentheses modes
python3 - "$work/minus" "$work/parentheses" <<'PY'
import sys
from pathlib import Path

def get_pipe_positions(filepath):
    lines = Path(filepath).read_text().splitlines()
    table_lines = [l for l in lines if '|' in l]
    return [[i for i, c in enumerate(l) if c == '|'] for l in table_lines]

minus_pipes = get_pipe_positions(sys.argv[1])
paren_pipes = get_pipe_positions(sys.argv[2])

if not minus_pipes or not paren_pipes:
    raise SystemExit('expected table lines with pipe separators')

for idx, pipe_positions in enumerate(minus_pipes):
    if pipe_positions != minus_pipes[0]:
        raise SystemExit(f'minus table line {idx} pipe positions mismatch: {pipe_positions} vs {minus_pipes[0]}')

for idx, pipe_positions in enumerate(paren_pipes):
    if pipe_positions != paren_pipes[0]:
        raise SystemExit(f'parentheses table line {idx} pipe positions mismatch: {pipe_positions} vs {paren_pipes[0]}')
PY

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

# Calendar coordinates are colored as complete tokens, not year-only positive values.
printf 'Account | 2026-01 | 2026-02\nRange: 2026-01..2026-03\n2026-01-12 | 5\n' \
  | env -u NO_COLOR COLOR_FORCE=1 BL_THEME=nord REPORT_NEGATIVE_COLOR=red \
    bash tools/lib/color-filter >"$work/calendar-color"
grep -Fx $'Account | \033[1;38;2;136;192;208m2026-01\033[0m | \033[1;38;2;136;192;208m2026-02\033[0m' "$work/calendar-color" >/dev/null
grep -Fx $'Range: \033[1;38;2;136;192;208m2026-01\033[0m..\033[1;38;2;136;192;208m2026-03\033[0m' "$work/calendar-color" >/dev/null
grep -Fx $'\033[1;38;2;136;192;208m2026-01-12\033[0m | \033[38;2;163;190;140m5\033[0m' "$work/calendar-color" >/dev/null

# Default Nord theme uses theme-native ESC_ERROR (#BF616A / \033[38;2;191;97;106m)
printf 'value -12.5\n' | env -u NO_COLOR COLOR_FORCE=1 BL_THEME=nord REPORT_NEGATIVE_COLOR=red \
  bash tools/lib/color-filter >"$work/nord-minus"
grep -F $'\033[38;2;191;97;106m-12.5\033[0m' "$work/nord-minus" >/dev/null

printf 'Balance: (12.5)\n' | env -u NO_COLOR COLOR_FORCE=1 BL_THEME=nord REPORT_NEGATIVE_COLOR=red \
  bash tools/lib/color-filter >"$work/nord-paren"
grep -F $'\033[38;2;191;97;106m(12.5)\033[0m' "$work/nord-paren" >/dev/null

# Non-numeric parentheses in text (e.g. memo (2026), year (2026)) are not colored as negative numbers
printf 'memo (2026) | (1000)\n' | env -u NO_COLOR COLOR_FORCE=1 BL_THEME=nord REPORT_NEGATIVE_COLOR=red \
  bash tools/lib/color-filter >"$work/text-paren"
grep -F $'memo (2026) | \033[38;2;191;97;106m(1000)\033[0m' "$work/text-paren" >/dev/null

printf 'memo (2026)\nyear (2026)\n' | env -u NO_COLOR COLOR_FORCE=1 BL_THEME=nord REPORT_NEGATIVE_COLOR=red \
  bash tools/lib/color-filter >"$work/prose-paren"
grep -Fx 'memo (2026)' "$work/prose-paren" >/dev/null
grep -Fx 'year (2026)' "$work/prose-paren" >/dev/null

# Non-table summary parenthesized negative amounts (Balance: (1000)) are colored
printf 'Balance: (1000)\n' | env -u NO_COLOR COLOR_FORCE=1 BL_THEME=nord REPORT_NEGATIVE_COLOR=red \
  bash tools/lib/color-filter >"$work/summary-paren"
grep -F $'Balance: \033[38;2;191;97;106m(1000)\033[0m' "$work/summary-paren" >/dev/null

# Compact and JSON machine surfaces do not depend on presentation policy validity in report.toml
cp -R "$fixture" "$work/broken_policy"
python3 - "$work/broken_policy/report.toml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text().replace('negative-style = "minus"', 'negative-style = "invalid_style"')
p.write_text(s)
PY

if ./tools/report "$work/broken_policy" balances human JPY 2026-01-12 >/dev/null 2>&1; then
  echo 'FAIL: human surface succeeded despite invalid presentation negative-style' >&2
  exit 1
fi
./tools/report "$work/broken_policy" balances compact JPY 2026-01-12 >"$work/broken-compact"
grep -F 'ledger_balance: income:salary/JPY -1000' "$work/broken-compact" >/dev/null

./tools/report "$work/broken_policy" balances json JPY 2026-01-12 >"$work/broken-json"
grep -F '"balance": -1000' "$work/broken-json" >/dev/null

echo 'check-report-presentation-policy: OK'
