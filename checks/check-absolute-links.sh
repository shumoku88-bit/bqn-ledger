#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-absolute-links.sh
# Check: absolute-links

# Resolve repo root
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# ── Test state ──
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

# ── Tests ──

# Find all tracked md files and specific root files
tracked_files=()
while IFS= read -r file; do
  if [[ "$file" == docs/*.md ]] || [[ "$file" == docs/**/*.md ]] || [[ "$file" == *.md ]]; then
    tracked_files+=("$file")
  fi
done < <(git ls-files 2>/dev/null || find docs TODO.md README.md AGENTS.md GEMINI.md -type f 2>/dev/null)

found_links=0
for file in "${tracked_files[@]}"; do
  if [ -f "$file" ]; then
    # Search for any file:// links
    if grep -q "file://" "$file"; then
      # Print matching lines
      echo "file:// link found in $file:" >&2
      grep -n "file://" "$file" >&2
      found_links=$((found_links + 1))
    fi
  fi
done

if [ "$found_links" -eq 0 ]; then
  pass
else
  fail "Found $found_links file(s) with file:// links"
fi

# ── Summary ──
echo "check-absolute-links: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
