#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-current-batch.XXXXXX")
trap 'rm -rf "$work"' EXIT
cp -R "$fixture" "$work/base"
base="$work/base"
domain=JPY
latest=2026-01-12

AssertSame() {
  local label=$1 left=$2 right=$3
  cmp -s "$left" "$right" && return 0
  printf 'FAIL: %s bytes differ\n' "$label" >&2
  diff -u "$left" "$right" >&2 || true
  exit 1
}
ExpectLine() {
  local expected=$1 file=$2
  grep -Fx "$expected" "$file" >/dev/null || {
    printf 'FAIL: expected exact line: %s\n' "$expected" >&2
    cat "$file" >&2
    exit 1
  }
}

cat >>"$base/actual.journal" <<'EOF'

2025-12-01 batch prior income anchor
    ; event-id: batch-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 batch prior income neutralization
    ; event-id: batch-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY
EOF
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 batch historical next income
    ; plan-id: batch-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

build_single_oracle() {
  local surface=$1 output=$2 request_set
  request_set="$(bqn src/application/current_report_profile_cli.bqn "$base" "$domain" "$surface" "$latest")"
  printf '%s\n' "$request_set" >"$work/requests.$surface"
  mapfile -t lines <<<"$request_set"
  [[ ${lines[0]:-} == $'key\tsurface\targuments' ]] || {
    echo "FAIL: $surface current request header invalid" >&2
    exit 1
  }
  : >"$output"
  for row in "${lines[@]:1}"; do
    IFS=$'\t' read -r -a fields <<<"$row"
    ./tools/report "$base" "${fields[@]}" >>"$output"
  done
}

for surface in human compact json; do
  build_single_oracle "$surface" "$work/oracle.$surface"
  ./tools/report-all "$base" "$domain" "$surface" "$latest" >"$work/batch.$surface"
  AssertSame "$surface report-all vs single-report oracle" "$work/oracle.$surface" "$work/batch.$surface"
done

# Single and batch adapters share one semantic key-to-compose owner.
for file in src/application/report_destination_cli.bqn src/application/current_report_batch_cli.bqn; do
  grep -F 'destination ← •Import "report_destination.bqn"' "$file" >/dev/null || {
    echo "FAIL: $file does not import shared report destination" >&2; exit 1;
  }
  grep -F 'destination.Build' "$file" >/dev/null || {
    echo "FAIL: $file does not call shared report destination" >&2; exit 1;
  }
done
if grep -Fq 'compose.' src/application/report_destination_cli.bqn || grep -Fq 'compose.' src/application/current_report_batch_cli.bqn; then
  echo 'FAIL: application CLI owns report composition dispatch outside report_destination.bqn' >&2
  exit 1
fi
grep -F 'compose.Balances' src/application/report_destination.bqn >/dev/null || { echo 'FAIL: shared destination lacks balances dispatch' >&2; exit 1; }
grep -F 'compose.Issues' src/application/report_destination.bqn >/dev/null || { echo 'FAIL: shared destination lacks issues dispatch' >&2; exit 1; }

# Batch rows fail closed before source lifetime is shared.
if bqn src/application/current_report_batch_cli.bqn "$base" concat human $'balances\thuman\tJPY' >"$work/invalid.out" 2>&1; then
  echo 'FAIL: invalid batch route succeeded' >&2
  exit 1
fi
ExpectLine $'ERROR\tusage_balances\tbalances requires DOMAIN AS_OF' "$work/invalid.out"
if bqn src/application/current_report_batch_cli.bqn "$base" concat human $'envelopes\tcompact\tJPY\t2026-01-01\t2026-02-01\t2026-01-12' >"$work/surface.out" 2>&1; then
  echo 'FAIL: mismatched batch surface succeeded' >&2
  exit 1
fi
ExpectLine $'ERROR\tcurrent_request_surface_mismatch\tcurrent request row surface differs from selection' "$work/surface.out"

# Count actual BQN process launches on the production paths.
real_bqn=$(command -v bqn)
probe_bin="$work/bin"
count_file="$work/bqn-processes"
mkdir "$probe_bin"
cat >"$probe_bin/bqn" <<'EOF'
#!/usr/bin/env bash
printf '1\n' >>"$BQN_PROBE_COUNT"
exec "$BQN_PROBE_REAL" "$@"
EOF
chmod +x "$probe_bin/bqn"
export BQN_PROBE_REAL="$real_bqn"
export BQN_PROBE_COUNT="$count_file"
export PATH="$probe_bin:$PATH"

: >"$count_file"
./tools/report-all "$base" "$domain" human "$latest" >/dev/null
report_all_processes=$(wc -l <"$count_file" | tr -d ' ')
[[ $report_all_processes -eq 2 ]] || {
  echo "FAIL: report-all launched $report_all_processes BQN processes, expected 2" >&2
  exit 1
}

cache="$work/cache"
mkdir "$cache"
: >"$count_file"
./tools/report-cache "$base" "$cache" 201 "$domain" "$latest"
report_cache_processes=$(wc -l <"$count_file" | tr -d ' ')
[[ $report_cache_processes -eq 3 ]] || {
  echo "FAIL: report-cache launched $report_cache_processes BQN processes, expected 3" >&2
  exit 1
}
AssertSame 'cache all vs single-report human oracle' "$work/oracle.human" "$cache/all.txt"

# Each framed cache body still equals the independent single-report path.
mapfile -t keys < <("$BQN_PROBE_REAL" src/application/report_selection_cli.bqn all human)
mapfile -t human_lines <"$work/requests.human"
for key in "${keys[@]}"; do
  found=0
  for row in "${human_lines[@]:1}"; do
    IFS=$'\t' read -r -a fields <<<"$row"
    [[ ${fields[0]} == "$key" ]] || continue
    "$root/tools/report" "$base" "${fields[@]}" >"$work/single.$key"
    AssertSame "cache $key vs single-report path" "$work/single.$key" "$cache/$key.txt"
    found=1
    break
  done
  [[ $found -eq 1 ]] || { echo "FAIL: missing current request row for $key" >&2; exit 1; }
done

echo 'check-current-report-batch: OK'
