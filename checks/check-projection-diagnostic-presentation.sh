#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# The public-fixture golden includes the projection header, tabular rows,
# and source-balance diagnostic emitted by developer_inspection.bqn.
bash checks/check-src-next-golden.sh fixtures/editor-golden >/dev/null

for name in proj_cols BalanceBySourceOk FormatBalanceCheck FormatProjTable; do
  if grep -Eq "^[[:space:]]*${name}[[:space:]]*←|${name}[[:space:]]*⇐" src_next/projection.bqn; then
    echo "FAIL: diagnostic presentation owner leaked back into projection.bqn: $name" >&2
    exit 1
  fi
done

for name in proj_cols BalanceBySourceOk FormatBalanceCheck FormatProjTable; do
  if ! grep -Eq "^[[:space:]]*${name}[[:space:]]*←" src_next/developer_inspection.bqn; then
    echo "FAIL: named developer inspection entrypoint does not own $name" >&2
    exit 1
  fi
  if grep -Eq "^[[:space:]]*${name}[[:space:]]*←" src_next/main.bqn; then
    echo "FAIL: compatibility wrapper owns diagnostic implementation: $name" >&2
    exit 1
  fi
done

if grep -Eq 'proj\.(proj_cols|BalanceBySourceOk|FormatBalanceCheck|FormatProjTable)' src_next/developer_inspection.bqn; then
  echo "FAIL: developer_inspection.bqn still reaches diagnostic presentation through projection.bqn" >&2
  exit 1
fi

if grep -Eq '•Import[[:space:]]+"(main|developer_inspection)\.bqn"' src_next/report.bqn; then
  echo "FAIL: production report path must not depend on a developer inspection entrypoint" >&2
  exit 1
fi

printf 'OK: projection diagnostic presentation ownership passed\n'
