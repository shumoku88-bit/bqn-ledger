#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

set +e
trace="$(bash -x checks/check-edit-bqn-issue-close.sh 2>&1)"
status=$?
set -e
if [[ $status -ne 0 ]]; then
  escaped=${trace//'%'/'%25'}
  escaped=${escaped//$'\r'/'%0D'}
  escaped=${escaped//$'\n'/'%0A'}
  printf '::error title=Issue close focused trace::%s\n' "$escaped"
  exit "$status"
fi

echo 'check-issue-close-debug: ok'
