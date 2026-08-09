#!/usr/bin/env bash
# Experiment only: preserve current request construction, then execute all human
# destinations in one BQN process with shared admitted Household evidence.
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  printf 'Usage: %s BASE DOMAIN [LATEST]\n' "$0" >&2
  exit 2
fi

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
caller_pwd=$PWD
base=$1
domain=$2
latest=${3:-}
[[ $base == /* ]] || base="$caller_pwd/$base"
cd "$root"

request_args=("$base" "$domain" human)
[[ -z $latest ]] || request_args+=("$latest")
request_set=""
if ! request_set="$(bqn src/application/current_report_profile_cli.bqn "${request_args[@]}" 2>&1)"; then
  printf '%s\n' "$request_set" >&2
  exit 1
fi
mapfile -t lines <<<"$request_set"
[[ ${lines[0]:-} == $'key\tsurface\targuments' ]] || {
  printf 'ERROR\tcurrent_request_header_invalid\tcurrent request set header is invalid\n' >&2
  exit 1
}
rows=("${lines[@]:1}")
[[ ${#rows[@]} -gt 0 ]] || {
  printf 'ERROR\tcurrent_request_empty\tcurrent request set is empty\n' >&2
  exit 1
}

exec bqn experiments/performance/report_batch_destination_prototype.bqn "$base" "${rows[@]}"
