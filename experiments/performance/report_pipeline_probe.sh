#!/usr/bin/env bash
# Observation-only timing probe for the retained report pipeline.
# No timing is an acceptance threshold. Results describe one machine/run only.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

fixture=${1:-fixtures/ledger-facts-phase1-proof}
domain=${2:-JPY}
latest=${3:-2026-01-12}
runs=${RUNS:-3}
[[ $runs =~ ^[1-9][0-9]*$ ]] || { printf 'RUNS must be a positive integer\n' >&2; exit 2; }

work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-report-perf.XXXXXX")
trap 'rm -rf "$work"' EXIT
cp -R "$fixture" "$work/base"
base="$work/base"
cache="$work/cache"
mkdir "$cache"

# Match the successful public report-cache proof context without touching the fixture.
cat >>"$base/actual.journal" <<'EOF'

2025-12-01 performance prior income anchor
    ; event-id: performance-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 performance prior income neutralization
    ; event-id: performance-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY
EOF
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 performance historical next income
    ; plan-id: performance-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

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

measure_once() {
  local label=$1 sample=$2 phase timing real user sys launches
  shift 2
  phase=repeat
  [[ $sample -eq 1 ]] && phase=first
  : >"$count_file"
  timing="$work/time.${label}.${sample}"
  if ! /usr/bin/time -p "$@" >/dev/null 2>"$timing"; then
    printf 'probe command failed: %s sample %s\n' "$label" "$sample" >&2
    cat "$timing" >&2
    exit 1
  fi
  real=$(awk '$1=="real" {value=$2} END {print value}' "$timing")
  user=$(awk '$1=="user" {value=$2} END {print value}' "$timing")
  sys=$(awk '$1=="sys" {value=$2} END {print value}' "$timing")
  launches=$(wc -l <"$count_file" | tr -d ' ')
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$label" "$sample" "$phase" "$real" "$user" "$sys" "$launches"
}

measure_case() {
  local label=$1 sample
  shift
  for ((sample=1; sample<=runs; sample++)); do
    measure_once "$label" "$sample" "$@"
  done
}

printf 'case\tsample\tphase\treal_seconds\tuser_seconds\tsys_seconds\tbqn_processes\n'

# Small application stages isolate process/startup plus each narrow owner.
measure_case request_balances bqn src/application/report_request_cli.bqn balances human
measure_case route_balances bqn src/application/report_route_plan_cli.bqn balances human JPY "$latest"
measure_case presentation_policy bqn src/application/report_presentation_cli.bqn "$base"
measure_case destination_balances bqn src/application/report_destination_cli.bqn "$base" balances human JPY "$latest"

# Full single-report surfaces include request, route, presentation and destination.
measure_case report_balances ./tools/report "$base" balances human JPY "$latest"
measure_case destination_daily_flow bqn src/application/report_destination_cli.bqn "$base" daily-flow human JPY 2026-01-01 2026-02-01 "$latest"
measure_case report_daily_flow ./tools/report "$base" daily-flow human JPY 2026-01-01 2026-02-01 "$latest"

# Multi-report paths expose repeated process/admission lifetime directly.
measure_case report_all ./tools/report-all "$base" "$domain" human "$latest"
for ((sample=1; sample<=runs; sample++)); do
  measure_once report_cache "$sample" ./tools/report-cache "$base" "$cache" "$((100 + sample))" "$domain" "$latest"
done
measure_case cache_balances_read cat "$cache/balances.txt"
