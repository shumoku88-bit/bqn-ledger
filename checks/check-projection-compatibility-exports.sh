#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTION="$ROOT_DIR/src_next/projection.bqn"

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

# P2 preserves these neighboring live boundaries.
require_match '^[[:space:]]*MetaValue[[:space:]]*←' 'local MetaValue helper is missing'
require_match '^[[:space:]]*MetaValue[[:space:]]+⟨"txn_id", sourceId, metas⟩' 'TxIdFromMeta no longer uses local MetaValue'
require_match '^[[:space:]]*ResolveDayFromCycle[[:space:]]*←' 'ResolveDayFromCycle definition is missing'
require_match '^[[:space:]]*ResolveDayFromCycle[[:space:]]*⇐' 'ResolveDayFromCycle export is missing'
require_match '^[[:space:]]*AuthorizeArithmeticCurrencyProof[[:space:]]*⇐' 'live proof predicate export is missing'
require_match '^[[:space:]]*ArithmeticCurrencyAuthorizationMessage[[:space:]]*⇐' 'live proof message export is missing'

echo "OK: projection P2 compatibility-export boundary"
