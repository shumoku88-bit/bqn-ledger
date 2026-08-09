# Canonical Household source recovery Phase 0 — terminal verification instructions

Status: execution handoff for local-only evidence

Repository: `shumoku88-bit/bqn-ledger`

Target branch: `feat/canonical-household-phase0-topology`

## Purpose

Collect the evidence that is easier and safer to obtain from the real local CBQN/shell environment than through the GitHub API.

This task is observation and verification only. Do not edit, commit, push, merge, or rewrite any file. Do not touch the private canonical Household data contents.

The result will be used to finish Phase 0 inventory and decide whether the current full-suite baseline needs a separate repair PR before canonical source adapters begin.

## Safety rules

- Do not modify `main` or the Phase 0 branch.
- Do not run any BQN or shell editor command against the private canonical Household root.
- Do not print transaction, amount, Account, Plan, policy, or Issue contents from the private data repository.
- For the private root, inspect filenames/existence only.
- If `origin/main` moved from the expected baseline, report the new SHA and continue using that actual remote SHA for comparison. Do not reset any user branch.
- Use detached temporary worktrees so existing local work is not disturbed.

## 1. Fetch and create isolated worktrees

From the local `bqn-ledger` repository:

```sh
git fetch origin
main_sha=$(git rev-parse origin/main)
phase0_sha=$(git rev-parse origin/feat/canonical-household-phase0-topology)
printf 'origin/main=%s\nphase0=%s\n' "$main_sha" "$phase0_sha"

work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-phase0.XXXXXX")
git worktree add --detach "$work/main" "$main_sha"
git worktree add --detach "$work/phase0" "$phase0_sha"
```

Record both SHAs in the final report.

## 2. Run the new focused Phase 0 evidence

```sh
cd "$work/phase0"
bqn tests/test_application_canonical_household_sources.bqn
bash checks/check-canonical-household-source-topology.sh
git diff --check
```

Report each command as `PASS` or `FAIL` with its exit code. If a command fails, include the complete diagnostic produced by that command.

## 3. Compare the existing full-suite baseline

Run the same suite on current remote main and the Phase 0 branch. Capture output without changing files.

```sh
cd "$work/main"
set +e
NO_COLOR=1 tools/check.sh >"$work/main-check.log" 2>&1
main_check_rc=$?
set -e
printf 'main tools/check.sh exit=%s\n' "$main_check_rc"
tail -n 120 "$work/main-check.log"

cd "$work/phase0"
set +e
NO_COLOR=1 tools/check.sh >"$work/phase0-check.log" 2>&1
phase0_check_rc=$?
set -e
printf 'phase0 tools/check.sh exit=%s\n' "$phase0_check_rc"
tail -n 120 "$work/phase0-check.log"
```

Answer these questions explicitly:

1. Does `main` pass `tools/check.sh`?
2. Does the Phase 0 branch pass `tools/check.sh`?
3. If either fails, what is the first failing check?
4. Is the first failure identical on both revisions?
5. Did the new Phase 0 files introduce any earlier failure?

## 4. Diagnose `check-current-report-profile.sh`

Whether or not it is still the first failure, run this check directly on both revisions with shell tracing.

```sh
cd "$work/main"
set +e
bash -x checks/check-current-report-profile.sh >"$work/main-current-profile.log" 2>&1
main_profile_rc=$?
set -e
printf 'main current-profile exit=%s\n' "$main_profile_rc"
tail -n 160 "$work/main-current-profile.log"

cd "$work/phase0"
set +e
bash -x checks/check-current-report-profile.sh >"$work/phase0-current-profile.log" 2>&1
phase0_profile_rc=$?
set -e
printf 'phase0 current-profile exit=%s\n' "$phase0_profile_rc"
tail -n 160 "$work/phase0-current-profile.log"
```

Identify the exact command that first returns nonzero and the immediately preceding output/diagnostic. Do not repair it in this task.

## 5. Inventory legacy source references

From the Phase 0 worktree:

```sh
cd "$work/phase0"
pattern='accounts\.tsv|plan\.tsv|budget_alloc\.tsv|cycle\.tsv|daily_target_scope\.tsv|config\.tsv|report_manifests\.tsv|report_all_human\.tsv|report_all_compact\.tsv'
rg -n "$pattern" \
  src src_edit tools checks tests fixtures config docs README.md TODO.md \
  >"$work/legacy-source-references.txt"
wc -l "$work/legacy-source-references.txt"
```

Read the matching files as needed and classify every production-relevant match into one of these buckets:

- reader/admission
- writer/editor
- report/application routing
- UI/cache/query/operational tool
- check/test
- fixture
- current documentation/default
- migration-only or historical documentation

For the final response, provide a table with:

```text
legacy basename | file/path | classification | current reason | expected retirement phase
```

Do not silently omit duplicate-looking references. If several references have exactly the same owner/reason, they may be grouped only when every path is still listed.

Expected retirement phases from the roadmap:

- `accounts.tsv` -> after Account/downstream canonical cutovers prove it unused
- `plan.tsv` -> Phase 3+
- legacy Budget allocation TSV -> retired after canonical Budget writer migration
- `cycle.tsv` -> Phase 5+
- `daily_target_scope.tsv` -> Phase 5+
- `config.tsv` -> after canonical root/policy/application discovery no longer needs it
- legacy report manifest files -> Phase 6+

## 6. Inventory the executable `tools/` surface

```sh
cd "$work/phase0"
find tools -maxdepth 1 -type f -perm -111 -print | LC_ALL=C sort >"$work/tools-executables.txt"
cat "$work/tools-executables.txt"
```

Classify every executable as one of:

- supported user/application surface
- supported operational/development surface
- internal helper called by a supported surface
- candidate for retirement / unclear

For any `candidate for retirement / unclear`, explain why rather than deciding to delete it.

## 7. Check the private canonical root by filename only

Only if `HKERNEL_LEDGER_DATA_DIR` is already set and points to the private canonical Household root. Do not open any file.

```sh
if [[ -n ${HKERNEL_LEDGER_DATA_DIR:-} ]]; then
  canonical=(
    accounts.journal actual.journal plan.journal budget.journal
    budget.toml household.toml report.toml issues.tsv
  )
  legacy=(
    accounts.tsv plan.tsv cycle.tsv daily_target_scope.tsv
    config.tsv report_manifests.tsv report_all_human.tsv report_all_compact.tsv
  )

  echo 'canonical filename presence:'
  for name in "${canonical[@]}"; do
    if [[ -f "$HKERNEL_LEDGER_DATA_DIR/$name" ]]; then
      printf 'PRESENT %s\n' "$name"
    else
      printf 'MISSING %s\n' "$name"
    fi
  done

  echo 'legacy filename presence:'
  for name in "${legacy[@]}"; do
    if [[ -f "$HKERNEL_LEDGER_DATA_DIR/$name" ]]; then
      printf 'PRESENT %s\n' "$name"
    else
      printf 'ABSENT %s\n' "$name"
    fi
  done
else
  echo 'HKERNEL_LEDGER_DATA_DIR is not set; private filename check skipped.'
fi
```

Return only the `PRESENT/MISSING/ABSENT` lines. Do not include file sizes, hashes, contents, or Git history from the private data repository.

## 8. Final report

Return one report containing:

1. remote main SHA and Phase 0 SHA;
2. focused Phase 0 test results;
3. `tools/check.sh` result on main and Phase 0;
4. exact first failure of `check-current-report-profile.sh`, if any;
5. complete legacy-source reference classification table;
6. complete `tools/` executable classification table;
7. private canonical/legacy filename presence only, if available;
8. any evidence that the Phase 0 branch changed writer authority or production source selection. Expected answer: none.

Do not make fixes. The next GitHub PR will use this report to finish Phase 0 cleanly.

## 9. Cleanup

After the report is captured:

```sh
git -C "$work/main" status --short
git -C "$work/phase0" status --short
git worktree remove "$work/main"
git worktree remove "$work/phase0"
rmdir "$work" 2>/dev/null || true
```

Both status outputs must be empty before worktree removal.
