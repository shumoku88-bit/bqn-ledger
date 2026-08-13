#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

echo '[1/3] BQN tests' >&2
for test_file in tests/test_*.bqn; do
  [[ -f $test_file ]] || continue
  bqn "$test_file" >/dev/null || {
    echo "FAIL: $test_file" >&2
    echo "::error file=$test_file::BQN test failed"
    bqn "$test_file"
    exit 1
  }
done

echo '[2/3] final report checks' >&2
for check in \
  checks/check-ledger-facts.sh \
  checks/check-report-manifest-routing.sh \
  checks/check-report-route-plan-shell.sh \
  checks/check-report-destination-route-admission.sh \
  checks/check-report-destination-registry-error.sh \
  checks/check-report-composition.sh \
  checks/check-canonical-actual-reports.sh \
  checks/check-canonical-household-read-cutover.sh \
  checks/check-canonical-report-policy-cutover.sh \
  checks/check-current-report-profile.sh \
  checks/check-current-report-batch.sh \
  checks/check-report-cache.sh \
  checks/check-report-section-metadata.sh \
  checks/check-report-summary-query.sh \
  checks/check-report-presentation-policy.sh \
  checks/check-ledger-operations.sh; do
  bash "$check" >/dev/null || {
    echo "FAIL: $check" >&2
    echo "::error file=$check::Repository check failed"
    exit 1
  }
done

echo '[3/3] repository/editor/tool checks' >&2
checks=(
  check-bqn-review-queue.sh
  check-canonical-household-source-topology.sh check-doctor-canonical-household.sh
  check-devtools.sh check-devtools-negative.sh check-edit-bqn-account-list.sh
  check-edit-bqn-budget-add.sh check-edit-bqn-journal-add.sh check-edit-bqn-journal-block-add.sh check-edit-bqn-currency-m2.sh
  check-edit-bqn-travel-friend-add.sh check-travel-exchange-pure.sh check-edit-bqn-travel-exchange-add.sh
  check-edit-bqn-issue-close.sh check-issue-due-compatibility.sh check-edit-bqn-journal-list.sh check-edit-bqn-journal-cleanup-plan.sh
  check-edit-bqn-journal-cleanup-apply.sh check-edit-bqn-journal-canonical-surface.sh
  check-journal-reconstructible-identity-cleanup.sh check-edit-bqn-journal-reverse.sh
  check-edit-bqn-plan-list.sh check-edit-bqn-plan-related.sh check-edit-bqn-plan-add.sh
  check-edit-bqn-plan-edit.sh check-edit-bqn-plan-finish.sh check-edit-bqn-plan-budget-sync.sh
  check-plan-finish-replenish-ui.sh check-command-hub-recovery.sh check-command-hub-drilldown.sh check-command-hub-home.sh
  check-home-calendar.sh check-home-calendar-selector.sh check-home-logical-navigation.sh
  check-home-single-observation-frame.sh check-home-single-observation-detail-frame.sh check-home-narrow-terminal.sh
  check-workflow-drift.sh check-structured-ui-boundary.sh check-ui-preferences.sh
  check-safe-replace-line.sh check-safe-rewrite-checked.sh check-bash-safety.sh
  check-source-io-ownership.sh check-source-io-unreadable.sh check-editor-config-ownership.sh
  check-editor-actual-ownership.sh check-editor-account-ownership.sh check-editor-currency-ownership.sh
  check-editor-runtime-boundary.sh check-absolute-links.sh
)
for name in "${checks[@]}"; do
  [[ -f checks/$name ]] || continue
  check_output=""
  if ! check_output="$(bash "checks/$name" 2>&1)"; then
    [[ -z "$check_output" ]] || printf '%s\n' "$check_output" >&2
    echo "FAIL: checks/$name" >&2
    echo "::error file=checks/$name::Repository check failed"
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
