#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
base="$tmp/household"
cp -R fixtures/canonical-household-v1 "$base"

cat >"$base/issues.tsv" <<'EOF'
issue_id	status	date	due	category	title	amount	currency	details
ISSUE-001	open	2026-01-20	2026-01-20	general	Synthetic reminder	100	JPY	Fixture-only evidence
EOF

cat >>"$base/report.toml" <<'EOF'

[presentation.calendar]
issue-due-marker = "?"
EOF

wrapper=''
wrapper_status=0
set +e
wrapper="$(tools/home-calendar "$base" 2026-01-20 2>&1)"
wrapper_status=$?
set -e
if [[ $wrapper_status -ne 0 ]]; then
  echo 'FAIL: Home calendar shell wrapper failed' >&2
  printf '%s\n' "$wrapper" >&2
  exit 1
fi

direct=''
direct_status=0
set +e
direct="$(bqn src/application/home_calendar_cli.bqn "$base" 2026-01-20 2>&1)"
direct_status=$?
set -e
if [[ $direct_status -ne 0 ]]; then
  echo 'FAIL: Home calendar BQN application failed' >&2
  printf '%s\n' "$direct" >&2
  exit 1
fi

[[ "$wrapper" == "$direct" ]] || {
  echo 'FAIL: Home calendar shell wrapper differs from BQN application output' >&2
  exit 1
}

[[ "$wrapper" == $'2026-01\n'* ]] || {
  echo 'FAIL: Home calendar did not render the requested month' >&2
  printf '%s\n' "$wrapper" >&2
  exit 1
}
grep -Fq 'Mo  Tu  We  Th  Fr  Sa  Su' <<<"$wrapper" || {
  echo 'FAIL: Home calendar weekday matrix header missing' >&2
  exit 1
}
grep -Fq '20?' <<<"$wrapper" || {
  echo 'FAIL: admitted Issue due marker did not reach Home calendar output' >&2
  printf '%s\n' "$wrapper" >&2
  exit 1
}

# A day with canonical Actual evidence exposes the admitted transaction and all
# postings rather than reparsing actual.journal in shell.
actual_detail="$(tools/home-calendar "$base" 2026-01-10 detail)"
for expected in \
  '2026-01-10' \
  'Actual' \
  'Groceries' \
  'Assets:Bank' \
  'Expenses:Groceries' \
  'Plans due' \
  'Issues due' \
  'Cycle'; do
  grep -Fq "$expected" <<<"$actual_detail" || {
    echo "FAIL: Home Actual detail missing: $expected" >&2
    printf '%s\n' "$actual_detail" >&2
    exit 1
  }
done

# A date with no Actual evidence says so explicitly while retaining independent
# Issue due meaning. This is observation, not a synthetic bookkeeping-complete flag.
issue_detail="$(tools/home-calendar "$base" 2026-01-20 detail)"
grep -Fq $'Actual\n  (none)' <<<"$issue_detail" || {
  echo 'FAIL: Home detail did not expose absence of Actual evidence' >&2
  printf '%s\n' "$issue_detail" >&2
  exit 1
}
for expected in 'ISSUE-001' 'Synthetic reminder' 'Fixture-only evidence'; do
  grep -Fq "$expected" <<<"$issue_detail" || {
    echo "FAIL: Home Issue detail missing: $expected" >&2
    printf '%s\n' "$issue_detail" >&2
    exit 1
  }
done

# Wrapper and BQN application remain identical in detail mode too.
direct_detail="$(bqn src/application/home_calendar_cli.bqn "$base" 2026-01-20 detail)"
[[ "$issue_detail" == "$direct_detail" ]] || {
  echo 'FAIL: Home detail shell wrapper differs from BQN application output' >&2
  exit 1
}

invalid_output=''
if invalid_output="$(tools/home-calendar "$base" 2026-02-30 2>&1)"; then
  echo 'FAIL: Home calendar accepted an invalid focus date' >&2
  exit 1
fi
grep -Fq $'ERROR\thome_focus_date_invalid\t' <<<"$invalid_output" || {
  echo 'FAIL: invalid Home focus date diagnostic missing' >&2
  printf '%s\n' "$invalid_output" >&2
  exit 1
}

invalid_mode=''
if invalid_mode="$(tools/home-calendar "$base" 2026-01-20 unknown 2>&1)"; then
  echo 'FAIL: Home calendar accepted an unknown detail mode' >&2
  exit 1
fi
grep -Fq $'ERROR\thome_mode_invalid\t' <<<"$invalid_mode" || {
  echo 'FAIL: invalid Home mode diagnostic missing' >&2
  printf '%s\n' "$invalid_mode" >&2
  exit 1
}

echo 'check-home-calendar: ok'
