#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-docs-lifecycle.sh
# Narrow docs lifecycle guard. This intentionally checks low-ambiguity rules only.

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
WARN=0

pass() { PASS=$((PASS + 1)); }
warn() { WARN=$((WARN + 1)); echo "  WARN: $1" >&2; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

has_status_header() {
  local file="$1"
  awk 'NR<=12 && /^Status:[[:space:]]*/ { found=1 } END { exit found ? 0 : 1 }' "$file"
}

# Rule 1: newly added docs should declare lifecycle status.
# This is a local working-tree guard; in CI there may be no added files to inspect.
added_docs=()
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r line; do
    status="${line:0:2}"
    file="${line:3}"
    case "$status" in
      A\ |AM|\?\?)
        if [[ "$file" == docs/*.md ]] && [[ "$file" != docs/archive/* ]] && [[ "$file" != docs/report-mocks/* ]] && [[ "$file" != docs/variable-catalog/* ]]; then
          added_docs+=("$file")
        fi
        ;;
    esac
  done < <(git status --porcelain --untracked-files=all -- '*.md')
fi

missing_status=0
for file in "${added_docs[@]}"; do
  [ -f "$file" ] || continue
  if ! has_status_header "$file"; then
    echo "missing lifecycle Status header in new doc: $file" >&2
    missing_status=$((missing_status + 1))
  fi
done

if [ "$missing_status" -eq 0 ]; then
  pass
else
  fail "new docs must include a lifecycle Status header near the top"
fi

# Rule 2: modified current docs without a Status header are warnings, not failures.
# Existing docs are adopted gradually per docs/DOCS_LIFECYCLE_CONTRACT.md.
modified_without_status=0
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r line; do
    status="${line:0:2}"
    file="${line:3}"
    case "$status" in
      \ M|M\ |MM)
        if [[ "$file" == docs/*.md ]] && [[ "$file" != docs/README.md ]] && [[ "$file" != docs/archive/* ]] && [[ "$file" != docs/report-mocks/* ]] && [[ "$file" != docs/variable-catalog/* ]] && [ -f "$file" ]; then
          if ! has_status_header "$file"; then
            warn "modified doc has no lifecycle Status header yet: $file"
            modified_without_status=$((modified_without_status + 1))
          fi
        fi
        ;;
    esac
  done < <(git status --porcelain -- '*.md')
fi
pass

# Rules 3-4 apply to changed archive docs only.
# Existing archive debt is handled by separate docs hygiene slices.
changed_archive_docs=()
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r line; do
    status="${line:0:2}"
    file="${line:3}"
    case "$status" in
      A\ |AM|\?\?|\ M|M\ |MM)
        if [[ "$file" == docs/archive/*.md || "$file" == docs/archive/**/*.md ]] && [ -f "$file" ]; then
          changed_archive_docs+=("$file")
        fi
        ;;
    esac
  done < <(git status --porcelain --untracked-files=all -- 'docs/archive/**/*.md' 'docs/archive/*.md')
fi

# Rule 3: changed archive docs must not claim current status.
archive_current=0
for file in "${changed_archive_docs[@]}"; do
  if awk 'NR<=12 && /^Status:[[:space:]]*current([[:space:]]|$)/ { found=1 } END { exit found ? 0 : 1 }' "$file"; then
    echo "archive doc claims current status: $file" >&2
    archive_current=$((archive_current + 1))
  fi
done

if [ "$archive_current" -eq 0 ]; then
  pass
else
  fail "archive docs must not use Status: current..."
fi

# Rule 4: changed archive current-path pointers that use docs/... should point to existing files.
missing_current_paths=0
for file in "${changed_archive_docs[@]}"; do
  while IFS= read -r target; do
    # Strip common punctuation around inline paths.
    target="${target//\`/}"
    target="${target%%[).,;:]*}"
    if [[ "$target" == docs/* ]] && [ ! -e "$target" ]; then
      echo "missing current path target in $file: $target" >&2
      missing_current_paths=$((missing_current_paths + 1))
    fi
  done < <(grep -Eio 'current path:[[:space:]]*`?docs/[^`) ,;:]+' "$file" 2>/dev/null | sed -E 's/^[Cc]urrent path:[[:space:]]*`?//')
done

if [ "$missing_current_paths" -eq 0 ]; then
  pass
else
  fail "archive current path pointer(s) point to missing files"
fi

echo "check-docs-lifecycle: $PASS passed, $WARN warnings, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
