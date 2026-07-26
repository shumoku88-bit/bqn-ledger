#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTION="$ROOT_DIR/src_next/projection.bqn"
LAYER="$ROOT_DIR/src_next/layer.bqn"
CUBE="$ROOT_DIR/src_next/cube.bqn"
CYCLE="$ROOT_DIR/src_next/cycle.bqn"
ACTUAL_SNAPSHOT="$ROOT_DIR/src_next/actual_snapshot.bqn"
ACTUAL_COMPARISON="$ROOT_DIR/src_next/actual_comparison.bqn"
YTD_SUMMARY="$ROOT_DIR/src_next/ytd_summary.bqn"
PLANNED_PAYMENTS="$ROOT_DIR/src_next/planned_payments.bqn"
ACTUAL_SOURCE="$ROOT_DIR/src_next/actual_source.bqn"
TBDS="$ROOT_DIR/src_next/tbds.bqn"
DAILY_FLOW="$ROOT_DIR/src_next/daily_flow.bqn"
DAILY_TREND="$ROOT_DIR/src_next/daily_trend.bqn"
DAILY_TREND_PLAN="$ROOT_DIR/src_next/daily_trend_plan.bqn"
SNAPSHOT="$ROOT_DIR/src_next/snapshot.bqn"
CALC_MAIN="$ROOT_DIR/src_next/calc/main.bqn"
OUTLOOK="$ROOT_DIR/src_next/outlook.bqn"
OUTLOOK_REMAINING_PLAN="$ROOT_DIR/src_next/outlook_remaining_plan.bqn"
CYCLE_SUMMARY="$ROOT_DIR/src_next/cycle_summary.bqn"
ENVELOPE_COMPUTATION="$ROOT_DIR/src_next/envelope_computation.bqn"
PLAN_ROWS="$ROOT_DIR/src_next/plan_rows.bqn"
EVENT_LENS="$ROOT_DIR/src_next/event_lens.bqn"
JOURNAL_POSTING_IR="$ROOT_DIR/src_next/journal_posting_ir_stage2a.bqn"
CONTEXT="$ROOT_DIR/src_next/context.bqn"
JOURNAL_CURRENCY_CARRIER="$ROOT_DIR/src_next/journal_currency_proof_carrier_stage2a.bqn"
DATE_TEST="$ROOT_DIR/tests/test_src_next_date.bqn"
LAYER_TEST="$ROOT_DIR/tests/test_src_next_layer.bqn"
ACCOUNT_KEY_TEST="$ROOT_DIR/tests/test_src_next_account_key.bqn"
DAILY_TREND_EMPTY_TEST="$ROOT_DIR/tests/test_src_next_daily_trend_empty_frontier_fallback_row.bqn"
DAILY_TREND_FRONTIER_TEST="$ROOT_DIR/tests/test_src_next_daily_trend_row_set_frontier_redundancy.bqn"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

require_match() {
    local pattern="$1" description="$2"
    grep -Eq "$pattern" "$PROJECTION" || fail "$description"
}

reject_match() {
    local pattern="$1" description="$2"
    if grep -Eq "$pattern" "$PROJECTION"; then
        fail "$description"
    fi
}

require_file_match() {
    local file="$1" pattern="$2" description="$3"
    grep -Eq "$pattern" "$file" || fail "$description"
}

reject_file_match() {
    local file="$1" pattern="$2" description="$3"
    if grep -Eq "$pattern" "$file"; then
        fail "$description"
    fi
}

# P4b establishes one low-dependency Layer vocabulary owner while preserving
# projection.bqn and cube.bqn as compatibility surfaces for current callers.
reject_file_match "$LAYER" '•Import' 'pure Layer vocabulary owner acquired a dependency'
require_file_match "$LAYER" '^[[:space:]]*layer_actual[[:space:]]*←[[:space:]]*0[[:space:]]*$' 'Layer owner actual index changed'
require_file_match "$LAYER" '^[[:space:]]*layer_plan[[:space:]]*←[[:space:]]*1[[:space:]]*$' 'Layer owner plan index changed'
require_file_match "$LAYER" '^[[:space:]]*layer_budget[[:space:]]*←[[:space:]]*2[[:space:]]*$' 'Layer owner budget index changed'
require_file_match "$LAYER" '^[[:space:]]*layer_forecast[[:space:]]*←[[:space:]]*3[[:space:]]*$' 'Layer owner forecast index changed'
require_file_match "$LAYER" '^[[:space:]]*layer_names[[:space:]]*←[[:space:]]*⟨"actual", "plan", "budget", "forecast"⟩[[:space:]]*$' 'Layer owner vocabulary/order changed'
require_file_match "$LAYER" '^[[:space:]]*layer_count[[:space:]]*←[[:space:]]*≠[[:space:]]*layer_names[[:space:]]*$' 'Layer count is not derived from the owned vocabulary'
require_file_match "$LAYER" '^[[:space:]]*LayerName[[:space:]]*←' 'Layer owner index-to-name representation is missing'
reject_file_match "$LAYER" 'SourceLayer' 'source routing leaked into the pure Layer vocabulary owner'

require_file_match "$PROJECTION" '^[[:space:]]*layer[[:space:]]*←[[:space:]]*•Import "layer[.]bqn"' 'projection does not import the Layer owner'
for symbol in actual plan budget forecast; do
    require_file_match "$PROJECTION" "^[[:space:]]*layer_${symbol}[[:space:]]*←[[:space:]]*layer[.]layer_${symbol}[[:space:]]*$" "projection layer_${symbol} compatibility delegate is missing"
    reject_file_match "$PROJECTION" "^[[:space:]]*layer_${symbol}[[:space:]]*←[[:space:]]*[0-9]" "projection independently defines layer_${symbol}"
    require_file_match "$CUBE" "^[[:space:]]*layer_${symbol}[[:space:]]*←[[:space:]]*layer[.]layer_${symbol}[[:space:]]*$" "cube layer_${symbol} compatibility delegate is missing"
    reject_file_match "$CUBE" "^[[:space:]]*layer_${symbol}[[:space:]]*←[[:space:]]*[0-9]" "cube independently defines layer_${symbol}"
done
require_file_match "$PROJECTION" '^[[:space:]]*LayerName[[:space:]]*←[[:space:]]*layer[.]LayerName[[:space:]]*$' 'projection LayerName compatibility delegate is missing'
reject_file_match "$PROJECTION" '^[[:space:]]*LayerName[[:space:]]*←[[:space:]]*\{' 'projection independently defines LayerName'
require_match '^[[:space:]]*SourceLayer[[:space:]]*←' 'source routing boundary disappeared from projection'

require_file_match "$CUBE" '^[[:space:]]*layer[[:space:]]*←[[:space:]]*•Import "layer[.]bqn"' 'cube does not import the Layer owner'
require_file_match "$CUBE" '^[[:space:]]*layer_names[[:space:]]*←[[:space:]]*layer[.]layer_names[[:space:]]*$' 'cube layer_names compatibility delegate is missing'
require_file_match "$CUBE" '^[[:space:]]*layer_count[[:space:]]*←[[:space:]]*layer[.]layer_count[[:space:]]*$' 'cube layer_count compatibility delegate is missing'
reject_file_match "$CUBE" '^[[:space:]]*layer_names[[:space:]]*←[[:space:]]*⟨' 'cube independently defines Layer names'
reject_file_match "$CUBE" '^[[:space:]]*layer_count[[:space:]]*←[[:space:]]*[0-9]' 'cube independently defines Layer count'
require_file_match "$LAYER_TEST" '•Import "[.][.]/src_next/layer[.]bqn"' 'focused Layer owner test does not import the owner directly'

# P2a removals must not reappear as definitions or public fields.
reject_match '^[[:space:]]*ResolveDay[[:space:]]*←' 'legacy ResolveDay definition returned'
reject_match '^[[:space:]]*ResolveDay[[:space:]]*⇐' 'legacy ResolveDay export returned'
reject_match '^[[:space:]]*IsDigits[[:space:]]*←' 'dead IsDigits definition returned'
reject_match '^[[:space:]]*IsDigits[[:space:]]*⇐' 'dead IsDigits export returned'
reject_match '^[[:space:]]*IsIntegerText[[:space:]]*←' 'dead IsIntegerText definition returned'
reject_match '^[[:space:]]*IsIntegerText[[:space:]]*⇐' 'dead IsIntegerText export returned'
reject_match '^[[:space:]]*MetaValue[[:space:]]*⇐' 'private MetaValue helper became public again'

# P2b removes the unused effectful proof wrapper. Proof decisions remain data-only
# here; terminal rendering and exit behavior belong to context compatibility wrappers.
reject_match '^[[:space:]]*RequireArithmeticCurrencyProof[[:space:]]*←' 'dead proof wrapper definition returned'
reject_match '^[[:space:]]*RequireArithmeticCurrencyProof[[:space:]]*⇐' 'dead proof wrapper export returned'

# No executable BQN source or test may retain a qualified call to a removed field.
if grep -REn '[.]ResolveDay([^A-Za-z0-9_]|$)|[.](IsDigits|IsIntegerText|MetaValue|RequireArithmeticCurrencyProof)([^A-Za-z0-9_]|$)' \
    "$ROOT_DIR/src_next" "$ROOT_DIR/tests"; then
    fail 'qualified caller of a removed projection compatibility field remains'
fi

# P3a-P3j restore direct date ownership in date-only projection consumers.
for file in "$CYCLE" "$ACTUAL_SNAPSHOT" "$ACTUAL_COMPARISON" "$YTD_SUMMARY" "$PLANNED_PAYMENTS" "$ACTUAL_SOURCE" "$TBDS" "$DAILY_FLOW" "$DAILY_TREND" "$SNAPSHOT" "$CALC_MAIN" "$OUTLOOK"; do
    require_file_match "$file" '•Import "([.][.]/)?date[.]bqn"' "direct date import is missing from ${file#$ROOT_DIR/}"
    reject_file_match "$file" '•Import "([.][.]/)?projection[.]bqn"' "date-only projection dependency returned in ${file#$ROOT_DIR/}"
    reject_file_match "$file" 'proj[.](IsValidDateText|DaysFromEpoch)' "forwarded projection date call remains in ${file#$ROOT_DIR/}"
done
reject_file_match "$DATE_TEST" '•Import "[.][.]/src_next/projection[.]bqn"' 'focused date test imports projection again'
reject_file_match "$DATE_TEST" 'proj[.](IsValidDateText|DaysFromEpoch)' 'focused date test treats projection aliases as contract again'

# P3k restores direct date ownership in a mixed projection consumer.
require_file_match "$DAILY_TREND_PLAN" '•Import "([.][.]/)?date[.]bqn"' 'direct date import is missing from src_next/daily_trend_plan.bqn'
require_file_match "$DAILY_TREND_PLAN" '•Import "([.][.]/)?projection[.]bqn"' 'live non-date projection dependency disappeared from src_next/daily_trend_plan.bqn'
reject_file_match "$DAILY_TREND_PLAN" 'proj[.](IsValidDateText|DaysFromEpoch)' 'forwarded projection date call remains in src_next/daily_trend_plan.bqn'
require_file_match "$DAILY_TREND_PLAN" 'proj[.]FieldOrEmpty' 'live FieldOrEmpty dependency disappeared from src_next/daily_trend_plan.bqn'
require_file_match "$DAILY_TREND_PLAN" 'proj[.]layer_plan' 'live layer_plan dependency disappeared from src_next/daily_trend_plan.bqn'

# P3l restores direct date ownership in a second mixed projection consumer.
require_file_match "$OUTLOOK_REMAINING_PLAN" '•Import "([.][.]/)?date[.]bqn"' 'direct date import is missing from src_next/outlook_remaining_plan.bqn'
require_file_match "$OUTLOOK_REMAINING_PLAN" '•Import "([.][.]/)?projection[.]bqn"' 'live non-date projection dependency disappeared from src_next/outlook_remaining_plan.bqn'
reject_file_match "$OUTLOOK_REMAINING_PLAN" 'proj[.](IsValidDateText|DaysFromEpoch)' 'forwarded projection date call remains in src_next/outlook_remaining_plan.bqn'
require_file_match "$OUTLOOK_REMAINING_PLAN" 'proj[.]FieldOrEmpty' 'live FieldOrEmpty dependency disappeared from src_next/outlook_remaining_plan.bqn'
require_file_match "$OUTLOOK_REMAINING_PLAN" 'proj[.]layer_actual' 'live layer_actual dependency disappeared from src_next/outlook_remaining_plan.bqn'

# P3m restores direct date ownership in a third mixed projection consumer.
require_file_match "$CYCLE_SUMMARY" '•Import "([.][.]/)?date[.]bqn"' 'direct date import is missing from src_next/cycle_summary.bqn'
require_file_match "$CYCLE_SUMMARY" '•Import "([.][.]/)?projection[.]bqn"' 'live non-date projection dependency disappeared from src_next/cycle_summary.bqn'
reject_file_match "$CYCLE_SUMMARY" 'proj[.](IsValidDateText|DaysFromEpoch)' 'forwarded projection date call remains in src_next/cycle_summary.bqn'
require_file_match "$CYCLE_SUMMARY" 'proj[.]FieldOrEmpty' 'live FieldOrEmpty dependency disappeared from src_next/cycle_summary.bqn'
require_file_match "$CYCLE_SUMMARY" 'proj[.]layer_plan' 'live layer_plan dependency disappeared from src_next/cycle_summary.bqn'

# P3n restores direct date ownership while preserving the live cycle-relative helper.
require_file_match "$ENVELOPE_COMPUTATION" '•Import "([.][.]/)?date[.]bqn"' 'direct date import is missing from src_next/envelope_computation.bqn'
require_file_match "$ENVELOPE_COMPUTATION" '•Import "([.][.]/)?projection[.]bqn"' 'live cycle-relative projection dependency disappeared from src_next/envelope_computation.bqn'
reject_file_match "$ENVELOPE_COMPUTATION" 'proj[.](IsValidDateText|DaysFromEpoch)' 'forwarded projection date call remains in src_next/envelope_computation.bqn'
require_file_match "$ENVELOPE_COMPUTATION" 'proj[.]ResolveDayFromCycle' 'live ResolveDayFromCycle dependency disappeared from src_next/envelope_computation.bqn'

# P3o closes the remaining date compatibility shelf in mixed consumers.
for file in "$PLAN_ROWS" "$EVENT_LENS" "$JOURNAL_POSTING_IR" "$CONTEXT" "$JOURNAL_CURRENCY_CARRIER"; do
    require_file_match "$file" '•Import "([.][.]/)?date[.]bqn"' "direct date import is missing from ${file#$ROOT_DIR/}"
    require_file_match "$file" '•Import "([.][.]/)?projection[.]bqn"' "live non-date projection dependency disappeared from ${file#$ROOT_DIR/}"
    reject_file_match "$file" 'proj[.](IsValidDateText|DaysFromEpoch)' "forwarded projection date call remains in ${file#$ROOT_DIR/}"
done
require_file_match "$PLAN_ROWS" 'proj[.]ResolveDayFromCycle' 'live ResolveDayFromCycle dependency disappeared from src_next/plan_rows.bqn'
require_file_match "$EVENT_LENS" 'proj[.]FieldOrEmpty' 'live FieldOrEmpty dependency disappeared from src_next/event_lens.bqn'
require_file_match "$JOURNAL_POSTING_IR" 'proj[.]ResolveDayFromCycle' 'live ResolveDayFromCycle dependency disappeared from src_next/journal_posting_ir_stage2a.bqn'
require_file_match "$CONTEXT" 'proj[.]FieldOrEmpty' 'live FieldOrEmpty dependency disappeared from src_next/context.bqn'
require_file_match "$CONTEXT" 'proj[.]ResolveDayFromCycle' 'live ResolveDayFromCycle dependency disappeared from src_next/context.bqn'
require_file_match "$JOURNAL_CURRENCY_CARRIER" 'proj[.]ResolveDayFromCycle' 'live ResolveDayFromCycle dependency disappeared from src_next/journal_currency_proof_carrier_stage2a.bqn'

require_file_match "$ACCOUNT_KEY_TEST" '•Import "[.][.]/src_next/date[.]bqn"' 'direct date import is missing from tests/test_src_next_account_key.bqn'
require_file_match "$ACCOUNT_KEY_TEST" '•Import "[.][.]/src_next/projection[.]bqn"' 'live projection test dependency disappeared from tests/test_src_next_account_key.bqn'
reject_file_match "$ACCOUNT_KEY_TEST" 'proj[.](IsValidDateText|DaysFromEpoch)' 'projection date compatibility assertion remains in tests/test_src_next_account_key.bqn'
require_file_match "$ACCOUNT_KEY_TEST" 'proj[.]PostingId' 'live PostingId test dependency disappeared from tests/test_src_next_account_key.bqn'

for file in "$DAILY_TREND_EMPTY_TEST" "$DAILY_TREND_FRONTIER_TEST"; do
    require_file_match "$file" '•Import "[.][.]/src_next/date[.]bqn"' "direct date import is missing from ${file#$ROOT_DIR/}"
    reject_file_match "$file" '•Import "[.][.]/src_next/projection[.]bqn"' "date-only projection dependency returned in ${file#$ROOT_DIR/}"
    reject_file_match "$file" 'proj[.](IsValidDateText|DaysFromEpoch)' "forwarded projection date call remains in ${file#$ROOT_DIR/}"
done

# The date compatibility aliases are now removed and may not return.
reject_match '^[[:space:]]*IsValidDateText[[:space:]]*←' 'date validation compatibility definition returned'
reject_match '^[[:space:]]*IsValidDateText[[:space:]]*⇐' 'date validation compatibility export returned'
reject_match '^[[:space:]]*DaysFromEpoch[[:space:]]*←' 'absolute day-coordinate compatibility definition returned'
reject_match '^[[:space:]]*DaysFromEpoch[[:space:]]*⇐' 'absolute day-coordinate compatibility export returned'
if grep -REn 'proj[.](IsValidDateText|DaysFromEpoch)' "$ROOT_DIR/src_next" "$ROOT_DIR/tests"; then
    fail 'qualified caller of a removed projection date compatibility field remains'
fi

# P2 preserves these neighboring live boundaries.
require_match '^[[:space:]]*MetaValue[[:space:]]*←' 'local MetaValue helper is missing'
require_match '^[[:space:]]*MetaValue[[:space:]]+⟨"txn_id", sourceId, metas⟩' 'TxIdFromMeta no longer uses local MetaValue'
require_match '^[[:space:]]*ResolveDayFromCycle[[:space:]]*←' 'ResolveDayFromCycle definition is missing'
require_match '^[[:space:]]*ResolveDayFromCycle[[:space:]]*⇐' 'ResolveDayFromCycle export is missing'
require_match '^[[:space:]]*AuthorizeArithmeticCurrencyProof[[:space:]]*⇐' 'live proof predicate export is missing'
require_match '^[[:space:]]*ArithmeticCurrencyAuthorizationMessage[[:space:]]*⇐' 'live proof message export is missing'

echo "OK: projection P2, date-ownership P3a-P3o, and Layer owner P4b boundaries"
