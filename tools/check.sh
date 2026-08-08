#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

GithubEscape() {
  local text=${1:0:2000}
  text=${text//'%'/'%25'}
  text=${text//$'\r'/'%0D'}
  text=${text//$'\n'/'%0A'}
  printf '%s' "$text"
}

echo '[1/3] BQN tests' >&2
for test_file in tests/test_*.bqn; do
  [[ -f $test_file ]] || continue
  if ! output=$(bqn "$test_file" 2>&1); then
    echo "FAIL: $test_file" >&2
    printf '%s\n' "$output" >&2
    printf '::error file=%s::%s\n' "$test_file" "$(GithubEscape "$output")"
    exit 1
  fi
done

echo '[2/3] final report checks' >&2
for check in \
  checks/check-ledger-facts.sh \
  checks/check-report-manifest-config.sh \
  checks/check-report-manifest-routing.sh \
  checks/check-report-route-plan-shell.sh \
  checks/check-report-destination-route-admission.sh \
  checks/check-report-destination-registry-error.sh \
  checks/check-report-composition.sh \
  checks/check-canonical-actual-reports.sh \
  checks/check-current-report-profile.sh \
  checks/check-report-cache.sh \
  checks/check-report-section-metadata.sh \
  checks/check-report-summary-query.sh \
  checks/check-ledger-operations.sh; do
  if ! output=$(bash "$check" 2>&1); then
    echo "FAIL: $check" >&2
    printf '%s\n' "$output" >&2
    printf '::error file=%s::%s\n' "$check" "$(GithubEscape "$output")"
    exit 1
  fi
done

echo '[3/3] repository/editor/tool checks' >&2
checks=(
  check-canonical-household-source-topology.sh
  check-devtools.sh check-devtools-negative.sh check-edit-bqn-account-list.sh
  check-edit-bqn-journal-add.sh check-edit-bqn-journal-block-add.sh check-edit-bqn-currency-m2.sh
  check-edit-bqn-travel-friend-add.sh check-travel-exchange-pure.sh check-edit-bqn-travel-exchange-add.sh
  check-edit-bqn-issue-close.sh check-edit-bqn-journal-list.sh check-edit-bqn-journal-cleanup-plan.sh
  check-edit-bqn-journal-cleanup-apply.sh check-edit-bqn-journal-canonical-surface.sh
  check-journal-reconstructible-identity-cleanup.sh check-edit-bqn-journal-reverse.sh
  check-edit-bqn-plan-list.sh check-edit-bqn-plan-related.sh check-edit-bqn-plan-add.sh
  check-edit-bqn-plan-budget-sync.sh check-plan-finish-replenish-ui.sh check-edit-bqn-plan-edit.sh
  check-workflow-drift.sh check-structured-ui-boundary.sh check-ui-preferences.sh
  check-safe-replace-line.sh check-safe-rewrite-checked.sh check-bash-safety.sh
  check-source-io-ownership.sh check-source-io-unreadable.sh check-editor-config-ownership.sh
  check-editor-actual-ownership.sh check-editor-account-ownership.sh check-editor-currency-ownership.sh
  check-editor-runtime-boundary.sh check-absolute-links.sh
)
for name in "${checks[@]}"; do
  [[ -f checks/$name ]] || continue
  if ! output=$(bash "checks/$name" 2>&1); then
    echo "FAIL: checks/$name" >&2
    printf '%s\n' "$output" >&2
    printf '::error file=checks/%s::%s\n' "$name" "$(GithubEscape "$output")"
    exit 1
  fi
done

if rg -n 'src_next/|tools/report-(next|destination)|tools/query-destination' \
  src src_edit tools checks tests --glob '!tools/check.sh'; then
  echo 'FAIL: retired runtime reference remains' >&2
  exit 1
fi
if find . -maxdepth 1 -type d -name src_next | grep -q .; then
  echo 'FAIL: src_next still exists' >&2
  exit 1
fi
git diff --check
echo OK >&2
