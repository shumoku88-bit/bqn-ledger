#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FIELDS="$ROOT_DIR/src_next/source_fields.bqn"
PROJECTION="$ROOT_DIR/src_next/projection.bqn"
EVENT_LENS="$ROOT_DIR/src_next/event_lens.bqn"
SELECTED_DOMAIN_CONTEXT="$ROOT_DIR/src_next/selected_domain_context.bqn"
DAILY_TREND_PLAN="$ROOT_DIR/src_next/daily_trend_plan.bqn"
SOURCE_FIELDS_TEST="$ROOT_DIR/tests/test_src_next_source_fields.bqn"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

require_match() {
    local file="$1" pattern="$2" description="$3"
    grep -Eq "$pattern" "$file" || fail "$description"
}

reject_match() {
    local file="$1" pattern="$2" description="$3"
    if grep -Eq "$pattern" "$file"; then
        fail "$description"
    fi
}

# P6a establishes one low-dependency owner for bounded access to already-split
# source fields. It must not acquire file, parser, Posting IR, or policy imports.
reject_match "$SOURCE_FIELDS" '•Import' 'source field owner acquired a dependency'
require_match "$SOURCE_FIELDS" '^[[:space:]]*FieldOrEmpty[[:space:]]*←[[:space:]]*\{' 'source field owner definition is missing'
require_match "$SOURCE_FIELDS" '^[[:space:]]*FieldOrEmpty[[:space:]]*⇐[[:space:]]*FieldOrEmpty' 'source field owner export is missing'

# projection.bqn remains a compatibility surface, not a second definition.
require_match "$PROJECTION" '^[[:space:]]*source_fields[[:space:]]*←[[:space:]]*•Import "source_fields[.]bqn"' 'projection does not import the source field owner'
require_match "$PROJECTION" '^[[:space:]]*FieldOrEmpty[[:space:]]*←[[:space:]]*source_fields[.]FieldOrEmpty[[:space:]]*$' 'projection source field compatibility delegate is missing'
reject_match "$PROJECTION" '^[[:space:]]*FieldOrEmpty[[:space:]]*←[[:space:]]*\{' 'projection independently defines FieldOrEmpty'

# Event Lens is the first independent projection consumer to import the owner
# directly. Its only former projection dependency must not return.
require_match "$EVENT_LENS" '^[[:space:]]*source_fields[[:space:]]*←[[:space:]]*•Import "source_fields[.]bqn"' 'Event Lens does not import the source field owner directly'
require_match "$EVENT_LENS" 'source_fields[.]FieldOrEmpty' 'Event Lens does not call the direct source field owner'
reject_match "$EVENT_LENS" '•Import "projection[.]bqn"' 'Event Lens returned to the projection compatibility shelf'
reject_match "$EVENT_LENS" 'proj[.]FieldOrEmpty' 'Event Lens retains a projection-qualified field access call'

# P6b gives selected-domain non-Actual evidence validation the same direct owner
# without changing its currency-stage composition or checked Posting IR output.
require_match "$SELECTED_DOMAIN_CONTEXT" '^[[:space:]]*source_fields[[:space:]]*←[[:space:]]*•Import "source_fields[.]bqn"' 'selected domain context does not import the source field owner directly'
require_match "$SELECTED_DOMAIN_CONTEXT" 'source_fields[.]FieldOrEmpty' 'selected domain context does not call the direct source field owner'
reject_match "$SELECTED_DOMAIN_CONTEXT" '•Import "projection[.]bqn"' 'selected domain context returned to the projection compatibility shelf'
reject_match "$SELECTED_DOMAIN_CONTEXT" 'proj[.]FieldOrEmpty' 'selected domain context retains a projection-qualified field access call'

# P6c moves Daily Trend plan evidence reads to the direct source-field owner.
# Date, Layer, Cube, completion, diagnostic, and reserve semantics stay local.
require_match "$DAILY_TREND_PLAN" '^[[:space:]]*source_fields[[:space:]]*←[[:space:]]*•Import "source_fields[.]bqn"' 'daily trend plan does not import the source field owner directly'
require_match "$DAILY_TREND_PLAN" 'source_fields[.]FieldOrEmpty' 'daily trend plan does not call the direct source field owner'
reject_match "$DAILY_TREND_PLAN" '•Import "projection[.]bqn"' 'daily trend plan returned to the projection compatibility shelf'
reject_match "$DAILY_TREND_PLAN" 'proj[.]FieldOrEmpty' 'daily trend plan retains a projection-qualified field access call'

require_match "$SOURCE_FIELDS_TEST" '•Import "[.][.]/src_next/source_fields[.]bqn"' 'focused source field test does not import the owner directly'
require_match "$SOURCE_FIELDS_TEST" 'source_fields[.]FieldOrEmpty' 'focused source field assertions disappeared'

printf '%s\n' 'OK: source field ownership P6a-P6c boundaries'
