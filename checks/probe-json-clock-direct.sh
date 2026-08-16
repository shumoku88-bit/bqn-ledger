#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-clock-direct.XXXXXX")"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"
cat >"$work/bin/date" <<'EOF'
#!/usr/bin/env bash
echo 'ERROR: direct JSON report path called system clock' >&2
exit 99
EOF
chmod +x "$work/bin/date"
PATH="$work/bin:$PATH" bqn src/application/report_destination_cli.bqn \
  fixtures/ledger-facts-phase1-proof JPY json profit-and-loss range 2026-01-01 2026-01-11 \
  >"$work/out"
grep -Fq '"report_key":"profit-and-loss"' "$work/out"
