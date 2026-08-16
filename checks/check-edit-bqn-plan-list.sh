#!/usr/bin/env bash
set -euo pipefail

# Verify read-only `tools/edit-bqn plan list` over the canonical Household root.
# The stable TSV UI contract remains nine fields, but Plan identity now comes from
# canonical plan.journal admission rather than legacy plan.tsv row metadata.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
base="$tmp_root/canonical"
cp -R fixtures/canonical-household-v1 "$base"

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
plan_before="$(sha_file "$base/plan.journal")"
actual_before="$(sha_file "$base/actual.journal")"
accounts_before="$(sha_file "$base/accounts.journal")"

./tools/edit-bqn --base "$base" plan list --format tsv >"$tmp_root/default.tsv"
./tools/edit-bqn --base "$base" plan list --all --format tsv >"$tmp_root/all.tsv"

awk -F '\t' 'NF != 9 { print "bad field count on line " NR ": " $0 > "/dev/stderr"; exit 1 }' "$tmp_root/default.tsv"
awk -F '\t' '$8 != "" && $8 != "CLOSED" { print "bad status on line " NR ": " $8 > "/dev/stderr"; exit 1 }' "$tmp_root/all.tsv"

# The completed groceries Plan is hidden by default; salary remains open.
[[ $(wc -l <"$tmp_root/default.tsv" | tr -d ' ') -eq 1 ]]
awk -F '\t' '$1=="1" && $2=="plan-salary" && $3=="2026-02-05" && $4=="Planned salary" && $5=="Income:Salary" && $6=="Assets:Bank" && $7=="50000" && $8=="" && $9 ~ /50000 JPY$/ {found=1} END {exit found?0:1}' "$tmp_root/default.tsv"

# --all exposes completion derived from canonical Actual plan-id linkage.
awk -F '\t' '$2=="plan-groceries" && $3=="2026-01-15" && $8=="CLOSED" && $9 ~ / JPY \[CLOSED\]$/ {found=1} END {exit found?0:1}' "$tmp_root/all.tsv"
awk -F '\t' '$2=="plan-salary" && $8=="" {found=1} END {exit found?0:1}' "$tmp_root/all.tsv"

# A legacy Plan TSV is not an editor read authority anymore.
printf 'not\ta\tcanonical\tplan\trow\n' >"$base/plan.tsv"
./tools/edit-bqn --base "$base" plan list --format tsv >"$tmp_root/with-legacy.tsv"
cmp "$tmp_root/default.tsv" "$tmp_root/with-legacy.tsv"

# Temporal filtering is applied after canonical projection and excludes completed Plans.
cat >>"$base/plan.journal" <<'EOF'

2026-01-18 * Open overdue groceries
  ; plan-id: plan-overdue
  Assets:Bank  -700 JPY
  Expenses:Groceries  700 JPY

2026-02-10 * Open future groceries
  ; plan-id: plan-upcoming
  Assets:Bank  -800 JPY
  Expenses:Groceries  800 JPY
EOF
./tools/edit-bqn --base "$base" plan list --format tsv --temporal overdue --as-of 2026-01-24 >"$tmp_root/overdue.tsv"
./tools/edit-bqn --base "$base" plan list --format tsv --temporal upcoming --as-of 2026-01-24 >"$tmp_root/upcoming.tsv"
[[ $(wc -l <"$tmp_root/overdue.tsv" | tr -d ' ') -eq 1 ]]
awk -F '\t' '$2!="plan-overdue" || $3!="2026-01-18" {exit 1}' "$tmp_root/overdue.tsv"
[[ $(wc -l <"$tmp_root/upcoming.tsv" | tr -d ' ') -eq 2 ]]
awk -F '\t' '$3 < "2026-01-24" {exit 1}' "$tmp_root/upcoming.tsv"

# Read-only commands never rewrite canonical sources or create editor backups.
# plan.journal was intentionally extended above, so compare Actual/Accounts only here.
[[ "$actual_before" == "$(sha_file "$base/actual.journal")" ]]
[[ "$accounts_before" == "$(sha_file "$base/accounts.journal")" ]]
if [ -e "$base/.backup" ] && find "$base/.backup" -type f | grep -q .; then
  echo 'FAIL: plan list created a backup' >&2
  exit 1
fi

# Invalid CLI combinations fail before source mutation.
invalid_plan_sha="$(sha_file "$base/plan.journal")"
for bad_args in \
  '--format json' \
  '--format tsv --temporal overdue' \
  '--format tsv --temporal invalid --as-of 2026-01-24' \
  '--format tsv --temporal upcoming --as-of invalid' \
  '--all --format tsv --temporal overdue --as-of 2026-01-24'; do
  set +e
  # shellcheck disable=SC2086
  ./tools/edit-bqn --base "$base" plan list $bad_args >"$tmp_root/invalid.out" 2>&1
  rc=$?
  set -e
  [[ $rc -ne 0 ]] || { echo "FAIL: invalid plan list args succeeded: $bad_args" >&2; exit 1; }
done
[[ "$invalid_plan_sha" == "$(sha_file "$base/plan.journal")" ]]

printf 'OK: canonical tools/edit-bqn plan list checks passed\n'