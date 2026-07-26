#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTION="$ROOT_DIR/src_next/projection.bqn"
CYCLE="$ROOT_DIR/src_next/cycle.bqn"
ACTUAL_SNAPSHOT="$ROOT_DIR/src_next/actual_snapshot.bqn"
DATE_TEST="$ROOT_DIR/tests/test_src_next_date.bqn"

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

# P3a restores direct date ownership in the first already-importing callers.
for file in "$CYCLE" "$ACTUAL_SNAPSHOT"; do
    require_file_match "$file" '•Import "date[.]bqn"' "direct date import is missing from ${file#$ROOT_DIR/}"
    reject_file_match "$file" '•Import "projection[.]bqn"' "date-only projection dependency returned in ${file#$ROOT_DIR/}"
    reject_file_match "$file" 'proj[.](IsValidDateText|DaysFromEpoch)' "forwarded projection date call remains in ${file#$ROOT_DIR/}"
done
reject_file_match "$DATE_TEST" '•Import "[.][.]/src_next/projection[.]bqn"' 'focused date test imports projection again'
reject_file_match "$DATE_TEST" 'proj[.](IsValidDateText|DaysFromEpoch)' 'focused date test treats projection aliases as contract again'

# P2 preserves these neighboring live boundaries until later P3 groups finish.
require_match '^[[:space:]]*MetaValue[[:space:]]*←' 'local MetaValue helper is missing'
require_match '^[[:space:]]*MetaValue[[:space:]]+⟨"txn_id", sourceId, metas⟩' 'TxIdFromMeta no longer uses local MetaValue'
require_match '^[[:space:]]*ResolveDayFromCycle[[:space:]]*←' 'ResolveDayFromCycle definition is missing'
require_match '^[[:space:]]*ResolveDayFromCycle[[:space:]]*⇐' 'ResolveDayFromCycle export is missing'
require_match '^[[:space:]]*AuthorizeArithmeticCurrencyProof[[:space:]]*⇐' 'live proof predicate export is missing'
require_match '^[[:space:]]*ArithmeticCurrencyAuthorizationMessage[[:space:]]*⇐' 'live proof message export is missing'

# Date aliases remain temporarily exported while later P3 caller groups migrate.
require_match '^[[:space:]]*IsValidDateText[[:space:]]*⇐' 'temporary date validation compatibility export disappeared before P3 completion'
require_match '^[[:space:]]*DaysFromEpoch[[:space:]]*⇐' 'temporary day-coordinate compatibility export disappeared before P3 completion'

echo "OK: projection P2 and date-ownership P3a boundaries"
