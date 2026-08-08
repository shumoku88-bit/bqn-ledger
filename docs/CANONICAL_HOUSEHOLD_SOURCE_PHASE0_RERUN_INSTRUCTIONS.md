# Canonical Household source recovery Phase 0 — rerun instructions

Status: updated-head verification only

Repository: `shumoku88-bit/bqn-ledger`

Target branch: `feat/canonical-household-phase0-topology`

## Purpose

Verify the updated Phase 0 branch after the redundant BQN assertions were removed and the canonical topology guard was added to `tools/check.sh`.

This is verification only. Do not edit, commit, push, merge, or touch private Household data.

## Run

From the local `bqn-ledger` repository:

```sh
git fetch origin
phase0_sha=$(git rev-parse origin/feat/canonical-household-phase0-topology)
printf 'phase0=%s\n' "$phase0_sha"

work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-phase0-rerun.XXXXXX")
git worktree add --detach "$work/phase0" "$phase0_sha"
cd "$work/phase0"

set +e
bqn tests/test_application_canonical_household_sources.bqn
bqn_rc=$?

bash checks/check-canonical-household-source-topology.sh
topology_rc=$?

NO_COLOR=1 tools/check.sh
check_rc=$?

git diff --check
diff_rc=$?
set -e

printf 'bqn_test=%s\ntopology=%s\ntools_check=%s\ndiff_check=%s\n' \
  "$bqn_rc" "$topology_rc" "$check_rc" "$diff_rc"
```

If any command fails, return its complete diagnostic. Do not fix it.

## Cleanup

```sh
git status --short
git worktree remove "$work/phase0"
rmdir "$work" 2>/dev/null || true
```

The status output must be empty.

## Return

Return only:

1. Phase 0 SHA;
2. PASS/FAIL and exit code for the four checks;
3. complete diagnostic for any failure;
4. confirmation that final `git status --short` was empty.

Do not repeat the legacy-source inventory or tools inventory. Those results are already recorded in the repository.
