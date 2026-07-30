#!/usr/bin/env bash
set -euo pipefail

source_test="tests/test_accounting_sparse_group.bqn"
temporary_test="tests/.test_accounting_sparse_group_candidate.bqn"
production_import='group ← •Import "../src/accounting/sparse_group.bqn"'
candidate_import='group ← •Import "../experiments/bqn/sparse_group_classify_once_candidate.bqn"'

cleanup() {
  rm -f "$temporary_test"
}
trap cleanup EXIT

match_count="$(grep -Fxc "$production_import" "$source_test" || true)"
if [[ "$match_count" != "1" ]]; then
  echo "expected exactly one sparse-group production import, found: $match_count" >&2
  exit 1
fi

sed "s#${production_import}#${candidate_import}#" "$source_test" > "$temporary_test"

if grep -Fq "$production_import" "$temporary_test"; then
  echo "candidate portfolio still imports the production module" >&2
  exit 1
fi

bqn "$temporary_test"
echo "sparse_group candidate portfolio: ok"
