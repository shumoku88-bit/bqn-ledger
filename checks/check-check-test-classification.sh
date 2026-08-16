#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# Historical migration/retired-topology characterization stays retired.
for retired in \
  checks/audit-budget-style-explicit.sh \
  checks/check-israel-ils-usable-vertical-slice.sh \
  checks/check-report-labels.sh \
  checks/check-ui-smoke.sh; do
  [[ ! -e "$retired" ]] || { echo "FAIL: obsolete characterization returned: $retired" >&2; exit 1; }
done
[[ ! -e config/report_labels.tsv ]] || { echo 'FAIL: unused legacy report label catalog returned' >&2; exit 1; }

# bqn-eval positive/negative behavior is already qualified through
# devtools-check.sh + check-devtools-negative.sh. Do not restore a duplicate
# runner-external standalone check for the same contract.
[[ ! -e checks/check-bqn-eval.sh ]]
grep -Fq 'bqn-eval liveness' tools/devtools-check.sh
grep -Fq 'Testing tools/bqn-eval negative paths' checks/check-devtools-negative.sh

# Current standalone laws that were outside the full runner are promoted.
grep -Fq 'checks/check-json-clock-independence.sh' tools/check.sh
grep -Fq 'check-edit-bqn-journal-event-identity-inventory.sh' tools/check.sh

# A transitive law guard remains valid when a directly qualified meta-tool owns
# its invocation. Repository index integrity is one such current boundary.
[[ -f checks/check-repo-index.sh ]]
grep -Fq 'bash checks/check-repo-index.sh' tools/devtools-check.sh

# The Phase-1 proof fixture remains deliberate standalone characterization: it
# is a larger golden end-to-end witness, not required on every full-suite run.
[[ -f checks/check-ledger-facts-phase1-proof-fixture.sh ]]
if grep -Fq 'check-ledger-facts-phase1-proof-fixture.sh' tools/check.sh; then
  echo 'FAIL: standalone Phase-1 proof fixture was accidentally promoted into every full-suite run' >&2
  exit 1
fi

# The current currency editor qualification is canonical-source aware. Legacy
# TSV presence is observed only to prove it is not a writer authority.
grep -Fq 'fixtures/editor-currency-m2' checks/check-edit-bqn-currency-m2.sh
grep -Fq 'accounts.journal' checks/check-edit-bqn-currency-m2.sh
grep -Fq 'legacy accounts.tsv' checks/check-edit-bqn-currency-m2.sh

# Coverage output is an evidence inventory, not a manually maintained claim that
# a module is or is not tested. The old map contained retired/nonexistent owner
# names and labelled integration-tested src_edit owners as "untested".
grep -Fq 'qualification inventory, not line/module code coverage' tools/coverage
if rg -n 'editor_cmd\)|journal_add_cmd\)|untested:|covered: [0-9]+ / [0-9]+ BQN modules' tools/coverage >/dev/null; then
  echo 'FAIL: tools/coverage regained the retired fixed module-coverage map' >&2
  exit 1
fi
grep -Fq 'Qualification authority: tools/check.sh' tools/coverage

# The full suite still auto-runs every BQN unit test and explicitly runs the
# repository/editor/report law guards. Classification must not weaken the gate.
grep -Fq 'for test_file in tests/test_*.bqn' tools/check.sh
grep -Fq 'check-devtools.sh' tools/check.sh
grep -Fq 'check-devtools-negative.sh' tools/check.sh
grep -Fq 'check-bqn-review-queue.sh' tools/check.sh

echo 'check-check-test-classification: OK'
