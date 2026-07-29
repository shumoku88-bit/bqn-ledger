#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTION="$ROOT_DIR/src_next/projection.bqn"
ARITHMETIC_PROOF="$ROOT_DIR/src_next/arithmetic_currency_proof.bqn"
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
CURRENCY_DOMAIN_PROOF_TEST="$ROOT_DIR/tests/test_src_next_currency_domain_proof.bqn"
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
require_file_match "$CUBE" '^[[:space:]]*layer_count[[:space:]]*←[[:space:]]*layer[.]layer_count[[:space:]]*$' 'cube layer_count is not derived from the Layer owner'
reject_file_match "$CUBE" '^[[:space:]]*layer_names[[:space:]]*←[[:space:]]*⟨' 'cube independently defines Layer names'
reject_file_match "$CUBE" '^[[:space:]]*layer_count[[:space:]]*←[[:space:]]*[0-9]' 'cube independently defines Layer count'
require_file_match "$LAYER_TEST" '•Import "[.][.]/src_next/layer[.]bqn"' 'focused Layer owner test does not import the owner directly'

# P4c gives three mixed consumers direct ownership of the Layer constants they
# use while preserving their live projection and Cube helper dependencies.
for file in "$DAILY_TREND_PLAN" "$OUTLOOK_REMAINING_PLAN" "$CYCLE_SUMMARY"; do
    require_file_match "$file" '•Import "([.][.]/)?layer[.]bqn"' "direct Layer import is missing from ${file#$ROOT_DIR/}"
    reject_file_match "$file" 'proj[.]layer_(actual|plan|budget|forecast)' "projection Layer compatibility call remains in ${file#$ROOT_DIR/}"
done
require_file_match "$DAILY_TREND_PLAN" 'layer[.]layer_plan' 'daily trend plan no longer uses the direct plan Layer owner'
require_file_match "$OUTLOOK_REMAINING_PLAN" 'layer[.]layer_actual' 'remaining plan no longer uses the direct actual Layer owner'
require_file_match "$CYCLE_SUMMARY" 'layer[.]layer_plan' 'cycle summary no longer uses the direct plan Layer owner'
require_file_match "$CYCLE_SUMMARY" 'layer[.]layer_actual' 'cycle summary no longer uses the direct actual Layer owner'
reject_file_match "$CYCLE_SUMMARY" 'cube[.]layer_actual' 'cycle summary returned to the Cube Layer compatibility surface'
require_file_match "$CYCLE_SUMMARY" 'cube[.]Sum0' 'live Cube Sum0 dependency disappeared from cycle summary'

# P5c keeps arithmetic-currency proof policy at its direct owner and removes
# the temporary projection compatibility surface after all callers migrated.
require_file_match "$ARITHMETIC_PROOF" '^[[:space:]]*setup[[:space:]]*←[[:space:]]*•Import "currency_setup[.]bqn"' 'arithmetic proof owner does not import currency policy directly'
reject_file_match "$ARITHMETIC_PROOF" '•Import "(projection|context)[.]bqn"' 'arithmetic proof owner acquired a projection/context dependency'
require_file_match "$ARITHMETIC_PROOF" '^[[:space:]]*AuthorizeArithmeticCurrencyProof[[:space:]]*←[[:space:]]*\{' 'arithmetic proof owner predicate definition is missing'
require_file_match "$ARITHMETIC_PROOF" '^[[:space:]]*ArithmeticCurrencyAuthorizationMessage[[:space:]]*←[[:space:]]*\{' 'arithmetic proof owner message definition is missing'
require_file_match "$ARITHMETIC_PROOF" '^[[:space:]]*AuthorizeArithmeticCurrencyProof[[:space:]]*⇐' 'arithmetic proof owner predicate export is missing'
require_file_match "$ARITHMETIC_PROOF" '^[[:space:]]*ArithmeticCurrencyAuthorizationMessage[[:space:]]*⇐' 'arithmetic proof owner message export is missing'

require_file_match "$CONTEXT" '^[[:space:]]*proof_policy[[:space:]]*←[[:space:]]*•Import "arithmetic_currency_proof[.]bqn"' 'context does not import the arithmetic proof owner directly'
require_file_match "$CONTEXT" 'proof_policy[.]AuthorizeArithmeticCurrencyProof' 'context does not call the direct proof predicate owner'
require_file_match "$CONTEXT" 'proof_policy[.]ArithmeticCurrencyAuthorizationMessage' 'context does not call the direct proof message owner'
reject_file_match "$CONTEXT" 'proj[.](AuthorizeArithmeticCurrencyProof|ArithmeticCurrencyAuthorizationMessage)' 'context returned to projection proof compatibility calls'
require_file_match "$CONTEXT" '•Import "projection[.]bqn"' 'live non-proof projection dependency disappeared from context'

reject_file_match "$PROJECTION" '•Import "(arithmetic_currency_proof|currency_setup)[.]bqn"' 'projection regained arithmetic proof policy dependencies'
reject_match '^[[:space:]]*AuthorizeArithmeticCurrencyProof[[:space:]]*[←⇐]' 'projection proof predicate compatibility field returned'
reject_match '^[[:space:]]*ArithmeticCurrencyAuthorizationMessage[[:space:]]*[←⇐]' 'projection proof message compatibility field returned'
reject_file_match "$PROJECTION" '^[[:space:]]*(allowed_proof_basis|IsAllowedProofBasis|IsAllowedProofDomainBasis|ProofState|ProofDomain|ProofBasis|ProofScale|ProofMessage|IsNonNegativeInteger)[[:space:]]*←' 'projection independently retains arithmetic proof policy internals'

require_file_match "$CURRENCY_DOMAIN_PROOF_TEST" '•Import "[.][.]/src_next/arithmetic_currency_proof[.]bqn"' 'focused proof test does not import the owner directly'
reject_file_match "$CURRENCY_DOMAIN_PROOF_TEST" '•Import "[.][.]/src_next/projection[.]bqn"' 'focused proof test still imports projection as the proof contract'
reject_file_match "$CURRENCY_DOMAIN_PROOF_TEST" 'proj[.](AuthorizeArithmeticCurrencyProof|ArithmeticCurrencyAuthorizationMessage)' 'focused proof test retains projection-qualified proof calls'
require_file_match "$CURRENCY_DOMAIN_PROOF_TEST" 'proof_policy[.]AuthorizeArithmeticCurrencyProof' 'focused proof predicate assertions disappeared'
require_file_match "$CURRENCY_DOMAIN_PROOF_TEST" 'proof_policy[.]ArithmeticCurrencyAuthorizationMessage' 'focused proof message assertions disappeared'

if grep -REn 'proj[.](AuthorizeArithmeticCurrencyProof|ArithmeticCurrencyAuthorizationMessage)' \
    "$ROOT_DIR/src_next" "$ROOT_DIR/tests"; then
    fail 'qualified caller of a removed projection proof compatibility field remains'
fi

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
for file in "$CYCLE" "$ACTUAL_SNAPSHOT" "$ACTUAL_COMPARISON" "$YTD_SUMMARY" "$ACTUAL_SOURCE" "$TBDS" "$DAILY_FLOW" "$DAILY_TREND" "$SNAPSHOT" "$CALC_MAIN" "$OUTLOOK"; do
    require_file_match "$file" '•Import "([.][.]/)?date[.]bqn"' "direct date import is missing from ${file#$ROOT_DIR/}"
    reject_file_match "$file" '•Import "([.][.]/)?projection[.]bqn"' "date-only projection dependency returned in ${file#$ROOT_DIR/}"
    reject_file_match "$file" 'proj[.](IsValidDateText|DaysFromEpoch)' "forwarded projection date call remains in ${file#$ROOT_DIR/}"
done
reject_file_match "$DATE_TEST" '•Import "[.][.]/src_next/projection[.]bqn"' 'focused date test imports projection again'
reject_file_match "$DATE_TEST" 'proj[.](IsValidDateText|DaysFromEpoch)' 'focused date test treats projection aliases as contract again'

# Planned Payments no longer interprets dates directly; its exact shared
# observation policy is owned by actual_observation.bqn.
require_file_match "$PLANNED_PAYMENTS" '•Import "actual_observation[.]bqn"' 'prepared observation owner is missing from src_next/planned_payments.bqn'
reject_file_match "$PLANNED_PAYMENTS" '•Import "date[.]bqn"' 'obsolete direct date ownership returned in src_next/planned_payments.bqn'
reject_file_match "$PLANNED_PAYMENTS" '•Import "([.][.]/)?projection[.]bqn"' 'date-only projection dependency returned in src_next/planned_payments.bqn'

# P3k restores direct date ownership; P6c removes the final non-date projection dependency.
require_file_match "$DAILY_TREND_PLAN" '•Import "([.][.]/)?date[.]bqn"' 'direct date import is missing from src_next/daily_trend_plan.bqn'
reject_file_match "$DAILY_TREND_PLAN" '•Import "([.][.]/)?projection[.]bqn"' 'projection dependency returned in src_next/daily_trend_plan.bqn'
reject_file_match "$DAILY_TREND_PLAN" 'proj[.](IsValidDateText|DaysFromEpoch|FieldOrEmpty)' 'projection-qualified helper call remains in src_next/daily_trend_plan.bqn'

# P3l restores direct date ownership; P6d removes the final non-date projection dependency.
require_file_match "$OUTLOOK_REMAINING_PLAN" '•Import "([.][.]/)?date[.]bqn"' 'direct date import is missing from src_next/outlook_remaining_plan.bqn'
reject_file_match "$OUTLOOK_REMAINING_PLAN" '•Import "([.][.]/)?projection[.]bqn"' 'projection dependency returned in src_next/outlook_remaining_plan.bqn'
reject_file_match "$OUTLOOK_REMAINING_PLAN" 'proj[.](IsValidDateText|DaysFromEpoch|FieldOrEmpty)' 'projection-qualified helper call remains in src_next/outlook_remaining_plan.bqn'

# P3m restores direct date ownership; P6e removes the final non-date projection dependency.
require_file_match "$CYCLE_SUMMARY" '•Import "([.][.]/)?date[.]bqn"' 'direct date import is missing from src_next/cycle_summary.bqn'
reject_file_match "$CYCLE_SUMMARY" '•Import "([.][.]/)?projection[.]bqn"' 'projection dependency returned in src_next/cycle_summary.bqn'
reject_file_match "$CYCLE_SUMMARY" 'proj[.](IsValidDateText|DaysFromEpoch|FieldOrEmpty)' 'projection-qualified helper call remains in src_next/cycle_summary.bqn'

# P3n restores direct date ownership while preserving the live cycle-relative helper.
require_file_match "$ENVELOPE_COMPUTATION" '•Import "([.][.]/)?date[.]bqn"' 'direct date import is missing from src_next/envelope_computation.bqn'
require_file_match "$ENVELOPE_COMPUTATION" '•Import "([.][.]/)?projection[.]bqn"' 'live cycle-relative projection dependency disappeared from src_next/envelope_computation.bqn'
reject_file_match "$ENVELOPE_COMPUTATION" 'proj[.](IsValidDateText|DaysFromEpoch)' 'forwarded projection date call remains in src_next/envelope_computation.bqn'
require_file_match "$ENVELOPE_COMPUTATION" 'proj[.]ResolveDayFromCycle' 'live ResolveDayFromCycle dependency disappeared from src_next/envelope_computation.bqn'

# P3o closes the remaining date compatibility shelf in mixed consumers.
for file in "$PLAN_ROWS" "$JOURNAL_POSTING_IR" "$CONTEXT" "$JOURNAL_CURRENCY_CARRIER"; do
    require_file_match "$file" '•Import "([.][.]/)?date[.]bqn"' "direct date import is missing from ${file#$ROOT_DIR/}"
    require_file_match "$file" '•Import "([.][.]/)?projection[.]bqn"' "live non-date projection dependency disappeared from ${file#$ROOT_DIR/}"
    reject_file_match "$file" 'proj[.](IsValidDateText|DaysFromEpoch)' "forwarded projection date call remains in ${file#$ROOT_DIR/}"
done
require_file_match "$PLAN_ROWS" 'proj[.]ResolveDayFromCycle' 'live ResolveDayFromCycle dependency disappeared from src_next/plan_rows.bqn'
require_file_match "$JOURNAL_POSTING_IR" 'proj[.]ResolveDayFromCycle' 'live ResolveDayFromCycle dependency disappeared from src_next/journal_posting_ir_stage2a.bqn'
reject_file_match "$CONTEXT" 'proj[.]FieldOrEmpty' 'Context returned to the projection source-field compatibility seam'
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
echo "OK: projection P2, date ownership P3a-P3o, Layer ownership P4b-P4c, and arithmetic proof ownership P5c boundaries"
