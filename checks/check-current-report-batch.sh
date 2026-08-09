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
  local surface=$1 output=$2 request_set part
  if ! request_set="$(bqn src/application/current_report_profile_cli.bqn "$base" "$domain" "$surface" "$latest" 2>&1)"; then
    echo "FAIL: $surface current report profile failed" >&2
    printf '%s\n' "$request_set" >&2
    exit 1
  fi
  printf '%s\n' "$request_set" >"$work/requests.$surface"
  mapfile -t lines <<<"$request_set"
  [[ ${lines[0]:-} == $'key\tsurface\targuments' ]] || {
    echo "FAIL: $surface current request header invalid" >&2
    exit 1
  }
  : >"$output"
  for row in "${lines[@]:1}"; do
    IFS=$'\t' read -r -a fields <<<"$row"
    part="$work/oracle-part.$surface.${fields[0]}"
    if ! ./tools/report "$base" "${fields[@]}" >"$part"; then
      echo "FAIL: single-report oracle failed for $surface ${fields[0]}" >&2
      cat "$part" >&2
      exit 1
    fi
    cat "$part" >>"$output"
  done
}

for surface in human compact; do
  build_single_oracle "$surface" "$work/oracle.$surface"
  if ! ./tools/report-all "$base" "$domain" "$surface" "$latest" >"$work/batch.$surface"; then
    echo "FAIL: production report-all failed for $surface" >&2
    cat "$work/batch.$surface" >&2
    exit 1
  fi
  AssertSame "$surface report-all vs single-report oracle" "$work/oracle.$surface" "$work/batch.$surface"
done

# Aggregate JSON remains intentionally unsupported; this check does not invent a schema.
if ./tools/report-all "$base" "$domain" json "$latest" >"$work/json.out" 2>&1; then
  echo 'FAIL: aggregate JSON unexpectedly succeeded' >&2
  exit 1
fi
ExpectLine $'ERROR\treport_surface_unsupported\tall has no aggregate JSON schema' "$work/json.out"

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

# Lifetime law: a current batch must be able to consume Actual once and reuse the
# admitted evidence for every report. /dev/stdin becomes empty after the first read,
# so re-admitting Actual later in the same batch would fail or change the bytes.
one_shot_base="$work/one-shot-base"
cp -R "$base" "$one_shot_base"
cp "$one_shot_base/actual.journal" "$work/actual-once.journal"
rm "$one_shot_base/actual.journal"
ln -s /dev/stdin "$one_shot_base/actual.journal"
mapfile -t human_rows < <(tail -n +2 "$work/requests.human")
if ! cat "$work/actual-once.journal" | bqn src/application/current_report_batch_cli.bqn \
  "$one_shot_base" concat human "${human_rows[@]}" >"$work/one-shot.out"; then
  echo 'FAIL: current batch re-read one-shot Actual or failed to retain admitted evidence' >&2
  exit 1
fi
AssertSame 'one-shot Actual batch vs normal human batch' "$work/batch.human" "$work/one-shot.out"

# Process-scaling law: orchestration may change internally, but it must not scale
# with the number of selected reports. Human and compact deliberately select
# different report counts; their report-all process counts must therefore match.
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

CountProcesses() {
  local label=$1 output=$2
  shift 2
  : >"$count_file"
  if ! "$@" >"$output"; then
    echo "FAIL: process-count execution failed for $label" >&2
    cat "$output" >&2 || true
    exit 1
  fi
  wc -l <"$count_file" | tr -d ' '
}

human_report_count=$(( $(wc -l <"$work/requests.human") - 1 ))
compact_report_count=$(( $(wc -l <"$work/requests.compact") - 1 ))
[[ $human_report_count -ne $compact_report_count ]] || {
  echo 'FAIL: process-scaling fixture needs different human and compact report counts' >&2
  exit 1
}
report_all_human_processes=$(CountProcesses report-all-human "$work/process-report-all-human.out" \
  ./tools/report-all "$base" "$domain" human "$latest")
report_all_compact_processes=$(CountProcesses report-all-compact "$work/process-report-all-compact.out" \
  ./tools/report-all "$base" "$domain" compact "$latest")
[[ $report_all_human_processes -gt 0 ]] || { echo 'FAIL: report-all launched no BQN process' >&2; exit 1; }
[[ $report_all_human_processes -eq $report_all_compact_processes ]] || {
  echo "FAIL: report-all BQN process count scales with selected reports: human=$human_report_count/$report_all_human_processes compact=$compact_report_count/$report_all_compact_processes" >&2
  exit 1
}

cache="$work/cache"
mkdir "$cache"
report_cache_processes=$(CountProcesses report-cache "$work/process-report-cache.out" \
  ./tools/report-cache "$base" "$cache" 201 "$domain" "$latest")
[[ $report_cache_processes -lt $human_report_count ]] || {
  echo "FAIL: report-cache orchestration grew to report-count scale: reports=$human_report_count processes=$report_cache_processes" >&2
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
    if ! "$root/tools/report" "$base" "${fields[@]}" >"$work/single.$key"; then
      echo "FAIL: cache oracle single report failed for $key" >&2
      cat "$work/single.$key" >&2
      exit 1
    fi
    AssertSame "cache $key vs single-report path" "$work/single.$key" "$cache/$key.txt"
    found=1
    break
  done
  [[ $found -eq 1 ]] || { echo "FAIL: missing current request row for $key" >&2; exit 1; }
done

echo 'check-current-report-batch: OK'
