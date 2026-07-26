#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FIELDS="$ROOT_DIR/src_next/source_fields.bqn"
PROJECTION="$ROOT_DIR/src_next/projection.bqn"
EVENT_LENS="$ROOT_DIR/src_next/event_lens.bqn"
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

require_match "$SOURCE_FIELDS_TEST" '•Import "[.][.]/src_next/source_fields[.]bqn"' 'focused source field test does not import the owner directly'
require_match "$SOURCE_FIELDS_TEST" 'source_fields[.]FieldOrEmpty' 'focused source field assertions disappeared'

printf '%s\n' 'OK: source field ownership P6a boundaries'
