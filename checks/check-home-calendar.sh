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

echo 'check-home-calendar: ok'
