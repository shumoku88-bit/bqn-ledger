#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# The existing public-fixture golden includes the projection header, tabular rows,
# and source-balance diagnostic emitted by src_next/main.bqn.
bash checks/check-src-next-golden.sh fixtures/src-next-golden >/dev/null

for name in proj_cols BalanceBySourceOk FormatBalanceCheck FormatProjTable; do
  if grep -Eq "^[[:space:]]*${name}[[:space:]]*←|${name}[[:space:]]*⇐" src_next/projection.bqn; then
    echo "FAIL: diagnostic presentation owner leaked back into projection.bqn: $name" >&2
    exit 1
  fi
done

for name in proj_cols BalanceBySourceOk FormatBalanceCheck FormatProjTable; do
  if ! grep -Eq "^[[:space:]]*${name}[[:space:]]*←" src_next/main.bqn; then
    echo "FAIL: developer inspection entrypoint does not own $name" >&2
    exit 1
  fi
done

if grep -Eq 'proj\.(proj_cols|BalanceBySourceOk|FormatBalanceCheck|FormatProjTable)' src_next/main.bqn; then
  echo "FAIL: src_next/main.bqn still reaches diagnostic presentation through projection.bqn" >&2
  exit 1
fi

if grep -Eq '•Import[[:space:]]+"main\.bqn"' src_next/report.bqn; then
  echo "FAIL: production report path must not depend on the developer inspection entrypoint" >&2
  exit 1
fi

printf 'OK: projection diagnostic presentation ownership passed\n'
