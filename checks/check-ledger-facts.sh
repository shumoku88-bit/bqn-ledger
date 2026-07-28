#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

bqn tests/test_ledger_account_admission.bqn >/dev/null
bqn tests/test_ledger_journal_transaction_structure.bqn >/dev/null
bqn tests/test_ledger_facts.bqn >/dev/null
bqn tests/test_ledger_companion_facts.bqn >/dev/null

if rg -n '•Import ".*(src_next|src_edit|context\.bqn|report\.bqn|journal_profile)' src/ledger; then
  echo "FAIL: destination ledger facts import an old runtime/shape" >&2
  exit 1
fi

if rg -n '•FChars|•SH|ReadLines|ReadRaw|BuildContext|BuildAll' src/ledger; then
  echo "FAIL: destination ledger fact core performs I/O or builds a broad context" >&2
  exit 1
fi

echo "check-ledger-facts: OK"
