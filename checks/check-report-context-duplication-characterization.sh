#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

grep -q 'cycle.ReadCycleFromAdmittedTransactions ⟨base, preliminary.transactions⟩' src_next/selected_domain_context.bqn
if grep -Eq 'cycle\.ReadCycle[[:space:]]+(base|⟨base)' src_next/selected_domain_context.bqn; then
  echo "selected-domain adapter must not reload Actual evidence through compatibility ReadCycle" >&2
  exit 1
fi
grep -q 'actual_source.LoadCycleEvidence base2' src_next/context.bqn
grep -q 'cycle.ReadCycleFromActualEvidence ⟨base2, cycleEvidence⟩' src_next/context.bqn
grep -q 'cycle.ReadCycleFromActualEvidenceAt ⟨base2, as_of, cycleEvidence⟩' src_next/context.bqn
if grep -Eq 'cycle\.ReadCycle[[:space:]]' src_next/context.bqn; then
  echo "legacy BuildContext must reuse source-owned cycle evidence" >&2
  exit 1
fi

grep -q 'BuildFromPreparedCore ⟨selectedCurrency, raw, resolved, cy, sourceFile, snapshot, 1, preliminary⟩' src_next/selected_domain_context.bqn
if grep -q 'result ↩ BuildFromPrepared ⟨selectedCurrency, raw, resolved, cy, sourceFile, snapshot⟩' src_next/selected_domain_context.bqn; then
  echo "selected-domain production adapter must reuse preliminary admission" >&2
  exit 1
fi

out="$(bqn tools/characterization/report_context_duplication_probe.bqn fixtures/src-next-golden JPY)"

grep -q '^--- REPORT CONTEXT DUPLICATION PROBE ---$' <<<"$out"
grep -Eq '^Legacy_BuildContext_ms: [0-9]' <<<"$out"
grep -Eq '^Selected_Build_adapter_total_ms: [0-9]' <<<"$out"
grep -Eq '^Prepared_cycle_resolution_ms: [0-9]' <<<"$out"
grep -Eq '^Selected_BuildFromPrepared_ms: [0-9]' <<<"$out"
grep -q '^Direct_prepared_shape_parity: ok$' <<<"$out"
grep -q '^Legacy_cycle_start: 2026-06-15$' <<<"$out"
grep -q '^Selected_cycle_start: 2026-06-15$' <<<"$out"
grep -q '^Legacy_posting_rows: 8$' <<<"$out"
grep -q '^Selected_posting_rows: 8$' <<<"$out"

echo "check-report-context-duplication-characterization: OK"
