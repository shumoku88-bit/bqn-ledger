#!/usr/bin/env bash
set -euo pipefail

# tools/report-latency-benchmark.sh — latency benchmark script for report characterization
# Runs 1 untimed warmup run followed by 5 timed runs for each command.
# Reports min, median, max elapsed time (in ms).

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/tools/lib/system-defaults.sh"

base_dir="${LEDGER_DATA_DIR:-$(get_default_base_dir)}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base_dir="$2"
      shift 2
      ;;
    *)
      base_dir="$1"
      shift
      ;;
  esac
done

ensure_ledger_report_base "$base_dir"

run_time_ms() {
  local start end elapsed
  start=$(python3 -c 'import time; print(int(time.time() * 1000000))')
  "$@" >/dev/null 2>&1
  end=$(python3 -c 'import time; print(int(time.time() * 1000000))')
  elapsed=$(( (end - start) / 1000 ))
  echo "$elapsed"
}

benchmark_cmd() {
  local label="$1"
  shift
  # 1 warmup run
  "$@" >/dev/null 2>&1 || true

  local runs=()
  for i in {1..5}; do
    local t
    t=$(run_time_ms "$@")
    runs+=("$t")
  done

  # Sort runs to compute min, median, max
  IFS=$'\n' sorted=($(sort -n <<<"${runs[*]}"))
  unset IFS

  local min="${sorted[0]}"
  local median="${sorted[2]}"
  local max="${sorted[4]}"

  printf "%-40s | Min: %5d ms | Median: %5d ms | Max: %5d ms | Runs: %s\n" \
    "$label" "$min" "$median" "$max" "${runs[*]}"
}

echo "=========================================================================="
echo "Report Latency Characterization Benchmark"
echo "Target Base Directory: $base_dir"
echo "Date: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
echo "=========================================================================="
echo ""

echo "--- 1. Baseline & Command Hub Entrance ---"
benchmark_cmd "Command Hub entrance (bl --help)" "$ROOT_DIR/tools/bl" --base "$base_dir" help
benchmark_cmd "BQN engine startup (bqn -e 1+1)" bqn -e '1+1'
benchmark_cmd "BQN report.bqn import baseline" bqn -e '•Import "src_next/report.bqn"'
echo ""

echo "--- 2. Cache Invalidation Scan Components ---"
benchmark_cmd "Journal path resolution (actual_journal)" bqn "$ROOT_DIR/src_edit/actual_journal_file_cmd.bqn" "$base_dir"
benchmark_cmd "report-section-metadata export" "$ROOT_DIR/tools/report-section-metadata"
echo ""

echo "--- 3. Cold vs Warm Section Cache ---"
tmp_cache_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_cache_dir"' EXIT

benchmark_cmd "Cold section cache generation" "$ROOT_DIR/tools/report" "$base_dir" --write-section-cache "$tmp_cache_dir" --no-color
benchmark_cmd "Warm selector section-metadata" "$ROOT_DIR/tools/report-section-metadata"
echo ""

echo "--- 4. Direct Selected Sections ---"
benchmark_cmd "Direct section: snapshot" "$ROOT_DIR/tools/report" "$base_dir" --section snapshot --no-color
benchmark_cmd "Direct section: cycle" "$ROOT_DIR/tools/report" "$base_dir" --section cycle --no-color
benchmark_cmd "Direct section: outlook" "$ROOT_DIR/tools/report" "$base_dir" --section outlook --no-color
benchmark_cmd "Direct section: daily-trend" "$ROOT_DIR/tools/report" "$base_dir" --section daily-trend --no-color
benchmark_cmd "Direct section: balances (selected)" "$ROOT_DIR/tools/report" "$base_dir" --section balances --no-color
echo ""

echo "--- 5. Full Report ---"
benchmark_cmd "Full report (all sections)" "$ROOT_DIR/tools/report" "$base_dir" --no-color
echo ""

echo "--- 6. Detailed BQN Internal Probe ---"
bqn "$ROOT_DIR/src_next/report_latency_probe.bqn" "$base_dir"
echo ""
