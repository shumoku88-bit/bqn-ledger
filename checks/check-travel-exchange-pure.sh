#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
unset LEDGER_DATA_DIR

bqn tests/test_src_next_travel_exchange_event.bqn >/dev/null
if rg -n '•FChars|•file|•SH|•Out|•Exit' src_next/travel_exchange_event.bqn; then
  echo 'FAIL: pure exchange module contains an I/O primitive' >&2
  exit 1
fi
if rg -n 'rate⇐|journal_row⇐' src_next/travel_exchange_event.bqn; then
  echo 'FAIL: exchange preview exposes rate or journal-row output' >&2
  exit 1
fi
printf 'OK: pure Israel exchange contract has no I/O, rate, or journal output\n'
