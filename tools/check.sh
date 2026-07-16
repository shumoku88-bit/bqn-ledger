#!/usr/bin/env bash
set -euo pipefail

# tools/check.sh — src_next engine-only check suite
#
# Runs unit tests, editor tests, and all src_next fixture/golden checks.

export NO_COLOR=1

# Resolve repo root — use CWD if it looks like the root, otherwise resolve from script location
if [ -f "src_next/report.bqn" ]; then
    ROOT_DIR="$PWD"
else
    SOURCE="${BASH_SOURCE[0]}"
    while [ -L "$SOURCE" ]; do
        DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

check_bqn_presentation_boundary() {
    local status=0 file

    if grep -RIl $'\033' src_next tests >/dev/null; then
        echo "FAIL: literal ANSI ESC byte found in BQN source" >&2
        grep -RIn $'\033' src_next tests >&2 || true
        status=1
    fi

    while IFS= read -r file; do
        if ! awk '
            /^[[:space:]]*#/ { next }
            /@[[:space:]]*\+[[:space:]]*27|\\033|\\x1[Bb]|\\u001[Bb]|\\e\[[0-9;]*m/ {
                print FILENAME ":" FNR ": " $0
                found=1
            }
            END { exit found ? 1 : 0 }
        ' "$file"; then
            status=1
        fi
    done < <(find src_next tests -type f -name '*.bqn' | sort)

    if [ "$status" -ne 0 ]; then
        echo "FAIL: BQN source must not emit terminal styling; keep color in presentation layer" >&2
        exit 1
    fi
}

echo "[1/5] unit tests" >&2
for test_file in tests/test_*.bqn; do
    if [ -f "$test_file" ]; then
        if ! bqn "$test_file" >/dev/null; then
            echo "FAIL: $test_file" >&2
            bqn "$test_file" # rerun without redirect to show error
            exit 1
        fi
    fi
done

echo "[2/5] src_next golden checks" >&2
bash checks/check-src-next-golden.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-missing-plan >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-empty-projection >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-unknown-account >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-out-of-cycle-journal >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-currency-accountkey >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-expense-role-metadata >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-household-mapping-policy >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-income-anchor-golden >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-stale-plan >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-anchor-unmet >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-zero-vs-unavailable >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-missing-budget-mapping >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-broken-empty-columns >/dev/null
bash checks/check-src-next-golden.sh fixtures/src-next-budget-group-rename >/dev/null

echo "[3/5] src_next section checks" >&2
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-empty-projection >/dev/null
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-unknown-account >/dev/null
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-out-of-cycle-journal >/dev/null
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-currency-accountkey >/dev/null
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-missing-plan >/dev/null
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-expense-role-metadata >/dev/null
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-household-mapping-policy >/dev/null
bash checks/check-src-next-minimal-summary.sh fixtures/src-next-income-anchor-golden >/dev/null
bash checks/check-src-next-cycle-summary.sh >/dev/null
bash checks/check-src-next-ytd-summary.sh >/dev/null
bash checks/check-src-next-expense-breakdown.sh >/dev/null
bash checks/check-src-next-recent-journal.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-recent-journal.sh fixtures/src-next-empty-projection >/dev/null
bash checks/check-src-next-planned-payments.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-planned-payments.sh fixtures/src-next-missing-plan >/dev/null
bash checks/check-src-next-planned-payments.sh fixtures/plan-completion >/dev/null
bash checks/check-src-next-balances.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-balances.sh fixtures/src-next-empty-projection >/dev/null
bash checks/check-currency-m3-balances.sh >/dev/null
bash checks/check-src-next-readiness.sh >/dev/null
bash checks/check-src-next-household-metadata.sh >/dev/null
bash checks/check-src-next-plan-journal-overlap.sh >/dev/null
bash checks/check-src-next-envelope-computation.sh fixtures/src-next-envelope-computation >/dev/null
bash checks/check-src-next-execution-plan-coverage.sh fixtures/src-next-execution-plan-coverage >/dev/null
bash checks/check-src-next-envelope-production-guard.sh >/dev/null
bash checks/check-src-next-actual-comparison.sh fixtures/actual-comparison-numeric-owner-target ok >/dev/null
bash checks/check-src-next-actual-comparison.sh fixtures/actual-comparison-projection-normal error >/dev/null
bash checks/check-src-next-actual-comparison.sh fixtures/actual-comparison-history-boundary unavailable >/dev/null
bash checks/check-src-next-actual-comparison.sh fixtures/actual-comparison-invalid-date-rejected error >/dev/null
bash checks/check-src-next-snapshot.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-report.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-outlook-observation-source.sh >/dev/null
bash checks/check-src-next-actual-snapshot.sh >/dev/null
bash checks/check-src-next-outlook-remaining-plan.sh >/dev/null
bash checks/check-src-next-daily-trend-plan-numeric-owner.sh >/dev/null
bash checks/check-json-clock-independence.sh >/dev/null
bash checks/check-report-section-metadata.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-stage4-fields.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-currency-domain-proof.sh >/dev/null
bash checks/check-src-next-checked-posting-projection.sh >/dev/null
bash checks/check-src-next-compact-summary.sh fixtures/src-next-golden >/dev/null
bash checks/check-src-next-compact-summary.sh fixtures/empty-fields >/dev/null
bash checks/check-src-next-compact-summary.sh fixtures/src-next-envelope-computation >/dev/null
bash checks/check-src-next-cycle-remaining-plan-characterization.sh >/dev/null

echo "[4/5] MCP core and transport checks" >&2
npm --prefix mcp-server run lint
npm --prefix mcp-server test

echo "[5/5] engine-independent checks" >&2
bash checks/check-repo-index.sh >/dev/null
bash checks/check-src-next-clock-boundary.sh >/dev/null
bash checks/check-src-next-budget-actual-zero.sh >/dev/null
bash checks/check-devtools.sh >/dev/null
bash checks/check-devtools-negative.sh >/dev/null
bash checks/check-missing-role-fallback.sh >/dev/null
bash checks/check-src-next-lint.sh >/dev/null
bash checks/check-report-labels.sh >/dev/null
bash checks/check-edit-bqn-account-list.sh >/dev/null
bash checks/check-edit-bqn-journal-add.sh >/dev/null
bash checks/check-edit-bqn-income-budget-sync.sh >/dev/null
bash checks/check-edit-bqn-currency-m2.sh >/dev/null
bash checks/check-edit-bqn-journal-post-check-recovery.sh >/dev/null
bash checks/check-edit-bqn-travel-friend-add.sh >/dev/null
bash checks/check-travel-exchange-pure.sh >/dev/null
bash checks/check-edit-bqn-travel-exchange-add.sh >/dev/null
bash checks/check-israel-travel-four-path-rehearsal.sh >/dev/null
bash checks/check-edit-bqn-issue-close.sh >/dev/null
bash checks/check-edit-bqn-journal-list.sh >/dev/null
bash checks/check-edit-bqn-journal-reverse.sh >/dev/null
bash checks/check-edit-bqn-plan-list.sh >/dev/null
bash checks/check-edit-bqn-plan-related.sh >/dev/null
bash checks/check-edit-bqn-plan-add.sh >/dev/null
bash checks/check-edit-bqn-plan-finish.sh >/dev/null
bash checks/check-edit-bqn-plan-budget-sync.sh >/dev/null
bash checks/check-plan-finish-replenish-ui.sh >/dev/null
bash checks/check-edit-bqn-plan-edit.sh >/dev/null
bash checks/check-workflow-drift.sh >/dev/null
bash checks/check-docs-lifecycle.sh >/dev/null
bash checks/check-structured-ui-boundary.sh >/dev/null
bash checks/check-safe-replace-line.sh >/dev/null
bash checks/check-bash-safety.sh >/dev/null
bash checks/check-ui-smoke.sh >/dev/null
bash checks/check-absolute-links.sh >/dev/null
bash checks/check-loader-util-ownership.sh >/dev/null
bash checks/check-loader-unreadable.sh >/dev/null
bash checks/check-currency-usd-single.sh >/dev/null
bash checks/audit-budget-style-explicit.sh >/dev/null
check_bqn_presentation_boundary

echo "OK" >&2
