#!/usr/bin/env bash
# Experiment-only equivalence + timing probe for destination lifetime batching.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

fixture=${1:-fixtures/ledger-facts-phase1-proof}
domain=${2:-JPY}
latest=${3:-2026-01-12}
runs=${RUNS:-3}
[[ $runs =~ ^[1-9][0-9]*$ ]] || { printf 'RUNS must be a positive integer\n' >&2; exit 2; }

work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-report-batch-prototype.XXXXXX")
trap 'rm -rf "$work"' EXIT
cp -R "$fixture" "$work/base"
base="$work/base"

cat >>"$base/actual.journal" <<'EOF'

2025-12-01 prototype prior income anchor
    ; event-id: prototype-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 prototype prior income neutralization
    ; event-id: prototype-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY
EOF
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 prototype historical next income
    ; plan-id: prototype-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

# Semantic gate first: the experiment is useless unless it reproduces the current bytes.
./tools/report-all "$base" "$domain" human "$latest" >"$work/current.txt"
bash experiments/performance/report_batch_lifetime_prototype.sh "$base" "$domain" "$latest" >"$work/prototype.txt"
cmp "$work/current.txt" "$work/prototype.txt"
printf 'byte_equivalence\tok\n'

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

printf 'case\tsample\tphase\treal_seconds\tuser_seconds\tsys_seconds\tbqn_processes\n'
for ((sample=1; sample<=runs; sample++)); do
  measure_once current_report_all "$sample" ./tools/report-all "$base" "$domain" human "$latest"
  measure_once batch_lifetime_prototype "$sample" bash experiments/performance/report_batch_lifetime_prototype.sh "$base" "$domain" "$latest"
done
