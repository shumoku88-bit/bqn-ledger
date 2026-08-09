#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
export NO_COLOR=1
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-command-hub.XXXXXX")"
trap 'rm -rf "$work"' EXIT
cp -R fixtures/ledger-facts-phase1-proof "$work/base"
base="$work/base"

# Give current report composition the prior/current anchors used by its focused
# proof. This is public synthetic evidence only.
cat >>"$base/actual.journal" <<'EOF'

2025-12-01 prior income anchor
    ; event-id: hub-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 prior income neutralization
    ; event-id: hub-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY

2026-01-13 current hub observation
    ; event-id: hub-current-observation
    ; layer: actual
    ; currency: JPY
    expenses:transport 7 JPY
    assets:cash -7 JPY
EOF
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 historical next income
    ; plan-id: hub-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY

2098-09-10 selected related boundary
    ; plan-id: plan-2098-09-10-hub-related-proof
    ; series: hub-related-proof
    expenses:food 31 JPY
    assets:cash -31 JPY

2098-10-10 future related result
    ; plan-id: plan-2098-10-10-hub-related-proof
    ; series: hub-related-proof
    expenses:food 31 JPY
    assets:cash -31 JPY
EOF

bash -n tools/bl
tools/bl --help | grep -F 'operations    Household check, inspect, doctor, hledger export, source edit' >/dev/null
for selector in fzf gum; do rg -F "selector == $selector" tools/bl >/dev/null; done
grep -F 'selector=plain' tools/bl >/dev/null
grep -F 'BL_UI_MODE:-' tools/bl | grep -F minimal >/dev/null

# Non-interactive browse routes delegate to the existing read owners.
tools/bl --base "$base" journal list >"$work/hub-journal"
tools/edit --base "$base" journal list >"$work/owner-journal"
cmp "$work/hub-journal" "$work/owner-journal"
tools/bl --base "$base" transactions >"$work/transactions-alias"
cmp "$work/hub-journal" "$work/transactions-alias"
tools/bl --base "$base" browse transactions >"$work/browse-transactions"
cmp "$work/hub-journal" "$work/browse-transactions"

tools/bl --base "$base" plans list --format tsv >"$work/hub-plans"
tools/edit --base "$base" plan list --format tsv >"$work/owner-plans"
cmp "$work/hub-plans" "$work/owner-plans"
for temporal in overdue upcoming; do
  tools/bl --base "$base" plans "$temporal" --format tsv >"$work/hub-$temporal"
  tools/edit --base "$base" plan list --temporal "$temporal" --as-of "$(date +%Y-%m-%d)" --format tsv >"$work/owner-$temporal"
  cmp "$work/hub-$temporal" "$work/owner-$temporal"
done

# Interactive Plans → Related passes the selected Plan date—not today's date—to
# the BQN relation owner. Thus the selected future Plan is excluded while a
# later Plan with the same canonical series remains visible.
selected_plan_index="$(awk -F'\t' '$2=="plan-2098-09-10-hub-related-proof" {print $1}' "$work/hub-plans")"
[[ -n $selected_plan_index ]]
tools/edit --base "$base" plan related --index "$selected_plan_index" \
  --actual-date 2098-09-10 --format tsv >"$work/owner-related"
printf '%s\n' "$selected_plan_index" | BL_SELECTOR=plain \
  tools/bl --base "$base" plans related >"$work/hub-related" 2>"$work/hub-related-menu"
cmp "$work/owner-related" "$work/hub-related"
grep -q $'^ROW\t2098-10-10\tfuture related result\t' "$work/hub-related"
if grep -q $'^ROW\t2098-09-10\tselected related boundary\t' "$work/hub-related"; then
  echo 'FAIL: interactive related browse included the selected Plan itself' >&2
  exit 1
fi

tools/bl --base "$base" accounts list >"$work/hub-accounts"
tools/edit --base "$base" account list >"$work/owner-accounts"
cmp "$work/hub-accounts" "$work/owner-accounts"
tools/bl --base "$base" accounts >"$work/accounts-alias"
cmp "$work/hub-accounts" "$work/accounts-alias"
tools/bl --base "$base" issues list >"$work/hub-issues"
tools/edit --base "$base" issue list >"$work/owner-issues"
cmp "$work/hub-issues" "$work/owner-issues"
tools/bl --base "$base" issue-list >"$work/issues-alias"
cmp "$work/hub-issues" "$work/issues-alias"

# `bl check` is Household admission, never the repository development suite.
tools/bl --base "$base" check >"$work/check"
grep -F $'ledger_check\tstate\tok' "$work/check" >/dev/null
grep -F 'dev-check' tools/bl >/dev/null
grep -F '"$ROOT_DIR/tools/check.sh"' tools/bl >/dev/null

tools/bl --base "$base" inspect >"$work/inspect"
grep -F $'ledger_inspect\tstate\tok' "$work/inspect" >/dev/null
LEDGER_DATA_DIR=/definitely/not/the/selected/root \
  tools/bl --base "$base" doctor >"$work/doctor"
grep -F 'canonical Household source admission succeeded' "$work/doctor" >/dev/null

mkdir "$work/hledger"
HLEDGER_DATA_DIR="$work/hledger" tools/bl --base "$base" export >"$work/export"
for name in accounts.journal actual.journal plan.journal hledger.journal; do
  [[ -f "$work/hledger/$name" ]]
done
EDITOR=true tools/bl --base "$base" edit actual.journal >"$work/edit"
grep -F "Opening $base/actual.journal" "$work/edit" >/dev/null
if EDITOR=true tools/bl --base "$base" edit accounts.tsv >"$work/legacy-edit.out" 2>"$work/legacy-edit.err"; then
  echo 'FAIL: Hub source editor accepted a legacy basename' >&2
  exit 1
fi
grep -F 'source edit is limited to the canonical eight files' "$work/legacy-edit.err" >/dev/null

# The static catalog remains the one report key/label owner. Every retained key
# must execute through the Hub, and full output must contain twelve reports.
mapfile -t report_keys < <(tools/report-section-metadata | awk -F'\t' 'NR>1 {print $1}')
[[ ${#report_keys[@]} -eq 12 ]]
for key in "${report_keys[@]}"; do
  tools/bl --base "$base" --domain JPY --latest 2026-01-13 reports "$key" >"$work/report-$key"
  [[ -s "$work/report-$key" ]]
done
tools/bl --base "$base" --domain JPY --latest 2026-01-13 report >"$work/report-all"
[[ $(grep -c '^== ' "$work/report-all") -eq 12 ]]

# Behavioral qualification 1 & 2: Reports menu contains only report catalog items.
printf '0\n' | BL_SELECTOR=plain tools/main-ui.sh --base "$base" >"$work/main-ui-menu.out" 2>"$work/main-ui-menu.err" || true
for key in "${report_keys[@]}"; do
  grep -F "($key)" "$work/main-ui-menu.err" >/dev/null
done
for forbidden in 'action-' 'actions' '今日の記帳' '複数 Posting' '予定を実績化' '予定を追加' '予定を編集' 'Budget movement を追加' 'Account を追加'; do
  if grep -F "$forbidden" "$work/main-ui-menu.err"; then
    echo "FAIL: main-ui selector output contained forbidden action text: $forbidden" >&2
    exit 1
  fi
done

printf '0\n' | BL_SELECTOR=plain tools/bl --base "$base" reports >"$work/bl-reports-menu.out" 2>"$work/bl-reports-menu.err" || true
mapfile -t report_labels < <(tools/report-section-metadata | awk -F'\t' 'NR>1 {print $2}')
for label in "${report_labels[@]}"; do
  grep -F "$label" "$work/bl-reports-menu.err" >/dev/null
done
for forbidden in 'Expense' 'Income' 'Transfer' 'Multi-posting' 'Reverse' 'Plan Add' 'Plan Edit' 'Plan Finish' 'Budget Add' 'Account Add' 'Issue Add' 'action-' 'actions'; do
  if grep -F "$forbidden" "$work/bl-reports-menu.err"; then
    echo "FAIL: bl reports menu contained forbidden action text: $forbidden" >&2
    exit 1
  fi
done

# Behavioral qualification 4 & 5: main-ui.sh has no action runners, mutation paths, or exec-loops.
! grep -n 'run_action' tools/main-ui.sh >/dev/null
! grep -n 'Command Hubへ戻ります' tools/main-ui.sh >/dev/null
! grep -n 'exec .*main-ui\.sh.*select' tools/main-ui.sh >/dev/null

tools/bl --base "$base" operations summary JPY 2026-01-13 >"$work/summary"
[[ -s "$work/summary" ]]
tools/bl --base "$base" operations query JPY --keys 2026-01-13 >"$work/query"
[[ -s "$work/query" ]]

# Direct commands are explicit in non-TTY use; an interactive-only selector
# must fail visibly instead of consuming an accidental numeric/index input.
if tools/bl --base "$base" reports </dev/null >"$work/non-tty.out" 2>"$work/non-tty.err"; then
  echo 'FAIL: non-TTY reports selector unexpectedly succeeded' >&2
  exit 1
fi
grep -F 'reports requires KEY outside an interactive terminal' "$work/non-tty.err" >/dev/null
if tools/bl --base "$base" </dev/null >"$work/no-command.out" 2>"$work/no-command.err"; then
  echo 'FAIL: non-TTY empty Hub unexpectedly succeeded' >&2
  exit 1
fi
grep -F 'no command and no interactive terminal' "$work/no-command.err" >/dev/null

# Mutation choices remain routes to the established selection UI/writers. The
# Hub itself must not acquire source-write helpers or accounting interpretation.
rg -F 'expense|income|move|multi|reverse) run_action "$1"' tools/bl >/dev/null
for route in 'run_action plan-add' 'run_action plan-edit' 'run_action plan-finish' \
  'run_action budget' 'run_action account-add' 'run_action issue' 'run_action issue-close' 'show_plan_budget_sync_interactive'; do
  rg -F "$route" tools/bl >/dev/null
done
! rg -n 'safe_(append|replace|rewrite)|APPEND_BLOCK|posting.*coefficient|accounts\.tsv|plan\.tsv|budget_alloc\.tsv|cycle\.tsv|daily_target_scope\.tsv|config\.tsv' tools/bl >/dev/null
! rg -n 'choose_asset_type|--type.*account_type' tools/add-ui.sh >/dev/null

# Legacy files can coexist as poison sentinels but cannot affect any route.
cp -R "$base" "$work/with-legacy"
for name in accounts.tsv plan.tsv budget_alloc.tsv cycle.tsv daily_target_scope.tsv config.tsv report_manifests.tsv; do
  printf 'POISON_LEGACY_RUNTIME_SENTINEL\n' >"$work/with-legacy/$name"
done
tools/bl --base "$work/with-legacy" journal list >"$work/legacy-journal"
cmp "$work/hub-journal" "$work/legacy-journal"
tools/bl --base "$work/with-legacy" plans list --format tsv >"$work/legacy-plans"
cmp "$work/hub-plans" "$work/legacy-plans"
tools/bl --base "$work/with-legacy" accounts list >"$work/legacy-accounts"
cmp "$work/hub-accounts" "$work/legacy-accounts"
tools/bl --base "$work/with-legacy" issues list >"$work/legacy-issues"
cmp "$work/hub-issues" "$work/legacy-issues"
tools/bl --base "$work/with-legacy" --domain JPY --latest 2026-01-13 report >"$work/legacy-report-all"
cmp "$work/report-all" "$work/legacy-report-all"
! rg -F 'POISON_LEGACY_RUNTIME_SENTINEL' "$work"/hub-* "$work"/legacy-* "$work"/report-all >/dev/null

echo 'check-command-hub-recovery: OK'
