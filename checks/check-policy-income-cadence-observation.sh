#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Exact runtime-reference map. A behavioral consumer may still use renamed concepts,
# so this is evidence only, not a repository-wide absence proof.
mapfile -t runtime_matches < <(
  grep -RIl -E 'POLICY_INCOME_CADENCE|PolicyIncomeCadence' src_next | sort
)

if [ "${#runtime_matches[@]}" -ne 1 ] || [ "${runtime_matches[0]}" != "src_next/config.bqn" ]; then
  echo "FAIL: unexpected exact src_next income-cadence reference map" >&2
  printf '%s\n' "${runtime_matches[@]}" >&2
  exit 1
fi

echo "income cadence observation: exact src_next refs=config only" >&2
