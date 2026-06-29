#!/usr/bin/env bash
set -euo pipefail

# Lightweight Bash safety invariants that do not require shellcheck.
# This is intentionally narrow: catch regressions that bash -n accepts but
# crash at runtime, such as using `local` outside a function body.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

shell_files() {
  find tools checks -type f \
    ! -name '.repo-index-baseline.tsv' \
    ! -name '*.tsv' \
    ! -name '*.bqn' \
    ! -name '*.go' \
    -print0 |
  while IFS= read -r -d '' file; do
    if head -n 1 "$file" | grep -Eq '^#!.*\b(bash|sh)\b'; then
      printf '%s\n' "$file"
    fi
  done | sort
}

assert_no_top_level_local() {
  local script="$1"
  if awk '
    function count_char(s, c,    n, i) {
      n = 0
      for (i = 1; i <= length(s); i++) if (substr(s, i, 1) == c) n++
      return n
    }
    function stripped(line,    s) {
      s = line
      sub(/#.*/, "", s)
      return s
    }
    BEGIN { depth = 0; bad = 0 }
    {
      s = stripped($0)
      if (depth == 0 && s ~ /^[[:space:]]*local([[:space:]]|$)/) {
        printf "%s:%d: local used outside function: %s\n", FILENAME, FNR, $0 > "/dev/stderr"
        bad = 1
      }
      depth += count_char(s, "{")
      depth -= count_char(s, "}")
      if (depth < 0) depth = 0
    }
    END { exit bad ? 1 : 0 }
  ' "$script"; then
    pass "$script: no top-level local"
  else
    fail "$script: top-level local usage"
  fi
}

while IFS= read -r file; do
  if bash -n "$file"; then
    pass "$file: syntax ok"
  else
    fail "$file: syntax error"
  fi
  assert_no_top_level_local "$file"
done < <(shell_files)

if [[ "$failures" -eq 0 ]]; then
  echo "OK: bash safety checks passed" >&2
  exit 0
else
  echo "FAILED: $failures bash safety check(s) failed" >&2
  exit 1
fi
