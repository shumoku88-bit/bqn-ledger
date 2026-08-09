#!/usr/bin/env bash
# Temporary PR observation: compare current production batch paths with current main
# on the same runner. This file is removed after the result is recorded on the PR.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$root"
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-current-batch-observation.XXXXXX")
baseline_root="$work/main"
cleanup() {
  git worktree remove --force "$baseline_root" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

git worktree add --detach "$baseline_root" origin/main >/dev/null
cp -R fixtures/ledger-facts-phase1-proof "$work/template"
cat >>"$work/template/actual.journal" <<'EOF'

2025-12-01 observation prior income anchor
    ; event-id: observation-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 observation prior income neutralization
    ; event-id: observation-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY
EOF
cat >>"$work/template/plan.journal" <<'EOF'

2026-01-02 observation historical next income
    ; plan-id: observation-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF
cp -R "$work/template" "$work/baseline-base"
cp -R "$work/template" "$work/production-base"
baseline_base="$work/baseline-base"
production_base="$work/production-base"
domain=JPY
latest=2026-01-12

"$baseline_root/tools/report-all" "$baseline_base" "$domain" human "$latest" >"$work/baseline.txt"
"$root/tools/report-all" "$production_base" "$domain" human "$latest" >"$work/production.txt"
cmp "$work/baseline.txt" "$work/production.txt"
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

measure() {
  local label=$1 sample=$2 timing real user sys launches
  shift 2
  : >"$count_file"
  timing="$work/time.$label.$sample"
  if ! /usr/bin/time -p "$@" >/dev/null 2>"$timing"; then
    printf 'FAIL: %s sample %s\n' "$label" "$sample" >&2
    cat "$timing" >&2
    exit 1
  fi
  real=$(awk '$1=="real" {value=$2} END {print value}' "$timing")
  user=$(awk '$1=="user" {value=$2} END {print value}' "$timing")
  sys=$(awk '$1=="sys" {value=$2} END {print value}' "$timing")
  launches=$(wc -l <"$count_file" | tr -d ' ')
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$label" "$sample" "$real" "$user" "$sys" "$launches"
}

printf 'case\tsample\treal_seconds\tuser_seconds\tsys_seconds\tbqn_processes\n'
for sample in 1 2 3; do
  measure baseline_report_all "$sample" "$baseline_root/tools/report-all" "$baseline_base" "$domain" human "$latest"
  measure production_report_all "$sample" "$root/tools/report-all" "$production_base" "$domain" human "$latest"
  measure baseline_report_cache "$sample" "$baseline_root/tools/report-cache" "$baseline_base" "$work/cache.baseline.$sample" "$sample" "$domain" "$latest"
  measure production_report_cache "$sample" "$root/tools/report-cache" "$production_base" "$work/cache.production.$sample" "$sample" "$domain" "$latest"
done
