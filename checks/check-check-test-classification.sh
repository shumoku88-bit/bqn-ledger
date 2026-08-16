#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# Historical migration audits built on retired source topologies stay retired.
[[ ! -e checks/audit-budget-style-explicit.sh ]]
[[ ! -e checks/check-israel-ils-usable-vertical-slice.sh ]]

# bqn-eval positive/negative behavior is already qualified through
# devtools-check.sh + check-devtools-negative.sh. Do not restore a duplicate
# runner-external standalone check for the same contract.
[[ ! -e checks/check-bqn-eval.sh ]]
grep -Fq 'bqn-eval liveness' tools/devtools-check.sh
grep -Fq 'Testing tools/bqn-eval negative paths' checks/check-devtools-negative.sh

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
