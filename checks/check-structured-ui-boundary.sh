#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-structured-ui-boundary.sh
# Guard that UI tools do not scrape human report prose for section/menu meaning.

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

PASS=0
FAIL=0
matches_file="$(mktemp)"
trap 'rm -f "$matches_file"' EXIT

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

# UI may pipe human report to color-filter/pager for display. It must not pipe
# human report output into grep/sed/awk/cut to recover section or semantic data.
if rg -n 'tools/report("|[[:space:]])[^|]*\|[^#]*(grep|sed|awk|cut)' tools/main-ui.sh tools/bl >"$matches_file" 2>/dev/null; then
  cat "$matches_file" >&2
  fail "UI appears to parse tools/report human output"
else
  pass
fi

# Section menu labels should come from the structured metadata export, not from
# human report headings.
if rg -q 'tools/report-section-metadata' tools/main-ui.sh; then
  pass
else
  fail "tools/main-ui.sh must use tools/report-section-metadata for section menu metadata"
fi

# Direct section display should address sections by stable section key.
if rg -q -- '--section "\$key"' tools/main-ui.sh; then
  pass
else
  fail "tools/main-ui.sh direct section display should call tools/report --section by key"
fi

# Selector previews may use a cache produced by BQN/report using section keys.
if rg -q -- '--write-section-cache' tools/main-ui.sh; then
  pass
else
  fail "tools/main-ui.sh selector should use report-owned section cache instead of parsing report text"
fi

# Keep old marker/list-section scraping from returning as a UI dependency.
if rg -n -- '--list-sections|marker mapping|section header parsing|section headers' tools/main-ui.sh tools/bl; then
  fail "UI should not depend on human section headers or marker mapping"
else
  pass
fi

echo "check-structured-ui-boundary: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
