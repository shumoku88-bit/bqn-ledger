#!/usr/bin/env bash
set -euo pipefail

# tools/characterization/report-latency-benchmark.sh — latency benchmark script for report characterization
#
# Runs 1 untimed warmup run followed by 5 timed runs for each benchmark command.
# Uses Perl Time::HiRes to measure process wall-clock elapsed time without per-loop Python invocation.

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
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

# Clean temporary directory for benchmark cache testing and probe output
tmp_bench_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_bench_dir"' EXIT

run_time_ms() {
  perl -MTime::HiRes=time -e '
    my $t0 = time();
    my $pid = fork();
    if (!defined $pid) {
      die "fork failed: $!\n";
    }
    if ($pid == 0) {
      open(STDOUT, ">", "/dev/null");
      open(STDERR, ">", "/dev/null");
      exec(@ARGV);
      exit(127);
    }
    waitpid($pid, 0);
    my $status = $?;
    if ($status != 0) {
      die "command execution failed with status $status: @ARGV\n";
    }
    my $dt = (time() - $t0) * 1000;
    printf "%.2f\n", $dt;
  ' -- "$@"
}

benchmark_cmd() {
  local label="$1"
  shift
  # 1 warmup run (discarded; fails closed on command error)
  "$@" >/dev/null 2>&1

  local runs=()
  for i in {1..5}; do
    local t
    t=$(run_time_ms "$@")
    runs+=("$t")
  done

  # Sort runs numerically to compute min, median, max
  IFS=$'\n' sorted=($(sort -g <<<"${runs[*]}"))
  unset IFS

  local min="${sorted[0]}"
  local median="${sorted[2]}"
  local max="${sorted[4]}"

  printf "%-45s | Min: %7.1f ms | Median: %7.1f ms | Max: %7.1f ms\n" \
    "$label" "$min" "$median" "$max"
}

echo "=========================================================================="
echo "Report Latency Characterization Benchmark"
echo "Target Base Directory: $base_dir"
echo "Date: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
echo "=========================================================================="
echo ""

echo "--- 1. Subprocess & Process Baselines ---"
benchmark_cmd "Command Hub help CLI route (bl --help)" "$ROOT_DIR/tools/bl" --base "$base_dir" help
benchmark_cmd "BQN engine startup (bqn -e 1+1)" bqn -e '1+1'
benchmark_cmd "BQN report_sections.bqn import baseline" bqn -e '•Import "src_next/report_sections.bqn"'
benchmark_cmd "BQN report.bqn --list-sections baseline" bqn src_next/report.bqn "$base_dir" --list-sections
echo "Note: Interactive TTY main menu (bl without args) opens fzf/gum menu upon TTY input."
echo ""

echo "--- 2. Cache Invalidation Scan Components ---"
benchmark_cmd "Journal path resolution (actual_journal)" bqn "$ROOT_DIR/src_edit/actual_journal_file_cmd.bqn" "$base_dir"
benchmark_cmd "report-section-metadata command execution" "$ROOT_DIR/tools/report-section-metadata"
echo ""

echo "--- 3. Cold Section Cache vs Warm Metadata Export ---"
benchmark_cmd "Cold section cache generation" "$ROOT_DIR/tools/report" "$base_dir" --write-section-cache "$tmp_bench_dir" --no-color
benchmark_cmd "Warm selector section-metadata command" "$ROOT_DIR/tools/report-section-metadata"
echo "Note: Warm selector measurement captures tools/report-section-metadata execution,"
echo "      not full TTY fzf/gum rendering or user interaction availability."
echo ""

echo "--- 4. Direct Selected Sections ---"
benchmark_cmd "Direct section: snapshot" "$ROOT_DIR/tools/report" "$base_dir" --section snapshot --no-color
benchmark_cmd "Direct section: cycle" "$ROOT_DIR/tools/report" "$base_dir" --section cycle --no-color
benchmark_cmd "Direct section: outlook" "$ROOT_DIR/tools/report" "$base_dir" --section outlook --no-color
benchmark_cmd "Direct section: daily-trend" "$ROOT_DIR/tools/report" "$base_dir" --section daily-trend --no-color
benchmark_cmd "Direct section: balances (selected human)" "$ROOT_DIR/tools/report" "$base_dir" --section balances --no-color
echo ""

echo "--- 5. Full Report ---"
benchmark_cmd "Full report (all sections)" "$ROOT_DIR/tools/report" "$base_dir" --no-color
echo ""

echo "--- 6. Detailed BQN Internal Probe (Harness Sequence) ---"
probe_tmp_dir="$tmp_bench_dir/probe_tmp"
mkdir -p "$probe_tmp_dir"
bqn "$ROOT_DIR/tools/characterization/report_latency_probe.bqn" "$base_dir" "$probe_tmp_dir"
echo ""
