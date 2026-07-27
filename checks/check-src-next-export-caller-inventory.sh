#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src_next" "$tmp/tests" "$tmp/checks" "$tmp/tools"

cat >"$tmp/src_next/a.bqn" <<'EOF'
Used ← {𝕩}
TestOnly ← {𝕩}
CheckOnly ← {𝕩}
PreparedForTest ← {𝕩}
Dead ← {𝕩}
{Used⇐Used,TestOnly⇐TestOnly,CheckOnly⇐CheckOnly,PreparedForTest⇐PreparedForTest,Dead⇐Dead}
EOF
cat >"$tmp/src_next/b.bqn" <<'EOF'
a ← •Import "a.bqn"
a.Used 1
EOF
cat >"$tmp/tests/t.bqn" <<'EOF'
a ← •Import "../src_next/a.bqn"
a.TestOnly 1
 a.PreparedForTest 1
EOF
cat >"$tmp/checks/c.sh" <<'EOF'
a←•Import "src_next/a.bqn" ⋄ a.CheckOnly 1
EOF

out=$(python3 tools/characterization/src_next_export_callers.py "$tmp")
row() { awk -F'\t' -v name="$1" 'NR>1 && $2==name {print}' <<<"$out"; }

[[ "$(row Used)" == *$'\trepository_runtime_caller\t'* ]]
[[ "$(row TestOnly)" == *$'\ttest_or_check_only\t'* ]]
[[ "$(row CheckOnly)" == *$'\ttest_or_check_only\t'* ]]
[[ "$(row PreparedForTest)" == *$'\ttest_seam\t'* ]]
[[ "$(row Dead)" == *$'\tzero_repository_caller\t'* ]]

summary=$(python3 tools/characterization/src_next_export_callers.py "$tmp" --summary)
grep -Fqx $'exports\t5' <<<"$summary"
grep -Fqx $'repository_runtime_caller\t1' <<<"$summary"
grep -Fqx $'test_or_check_only\t2' <<<"$summary"
grep -Fqx $'test_seam\t1' <<<"$summary"
grep -Fqx $'zero_repository_caller\t1' <<<"$summary"

if python3 tools/characterization/src_next_export_callers.py "$tmp/missing" >/dev/null 2>&1; then
  echo "FAIL: missing source root succeeded" >&2
  exit 1
fi

echo "check-src-next-export-caller-inventory: OK"
