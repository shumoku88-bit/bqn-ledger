# Canonical Household Source Recovery Closeout

Status: closeout tracking

Baseline reviewed: `bqn-ledger` main `2a1ad39a9c70f4c228b27a4bb4abc22df695b19e`

## 1. Canonical authority

The only Household runtime authority is:

```text
accounts.journal
actual.journal
plan.journal
budget.journal
budget.toml
household.toml
report.toml
issues.tsv
```

Repository `config/currencies.tsv` is application configuration, not a ninth Household source. Legacy TSV files may remain temporarily as migration evidence, but they are not runtime fallback inputs.

## 2. Recovery already completed

The original recovery roadmap has been substantially executed on `main`.

- #551 established the eight-file topology, synthetic canonical fixture, and topology guard.
- #552 established canonical Account admission.
- #553–#554 established canonical Actual Facts and Actual report reads.
- #555–#557 established canonical Plan Facts and Plan read consumers/editor views.
- #558 established canonical Budget evidence for reports.
- #559 moved Household policy, Cycle, Daily Target, and related report ownership to canonical sources.
- #560 moved Report policy/routing to `report.toml` and retired report-manifest execution routing.
- #561–#562 made doctor, ledger-check, and ledger-inspect canonical-root operations.
- #563–#570 qualified canonical Actual, Account, Plan, and Budget publication paths.
- #571–#574 restored daily workflows and the canonical Command Hub/report browser surface.
- #575 corrected Planned Payments to an open-only obligation projection.
- #576 restored theme-native negative presentation and notation-safe report layout.

`docs/CANONICAL_CAPABILITY_MATRIX.md` is the current daily-use capability inventory. The twelve retained reports and the normal Record / Plans / Budget / Accounts / Issues / Reports / Operations surfaces now run from the canonical Household contract.

The recovery is therefore no longer an implementation roadmap for readers and writers. The remaining work is cleanup and retirement evidence.

## 3. Remaining closeout work

### A. Retire or quarantine legacy repository residue

Run a repository-wide audit of these legacy basenames:

```text
accounts.tsv
plan.tsv
budget_alloc.tsv
cycle.tsv
daily_target_scope.tsv
config.tsv
report_manifests.tsv
report_all_human.tsv
report_all_compact.tsv
```

For every remaining reference, classify it as one of:

1. active production dependency — must be removed;
2. active test/check for a still-supported legacy owner — retire or replace;
3. historical fixture/evidence — retain only when clearly isolated from runtime authority;
4. current documentation — update or archive;
5. negative guard text proving that legacy authority is rejected — retain when it protects the canonical boundary.

Known residue that requires explicit disposition includes `src/ledger/plan_snapshot.bqn`, which still names `plan.tsv` but appears to be exercised only by legacy-focused tests/checks. Do not leave such owners under active `src/` merely because normal Command Hub paths no longer import them. Either prove a current non-production purpose and quarantine it clearly, or retire it with its tests.

Current non-archive documentation still contains legacy-era examples in places such as `docs/CONVENTIONS.md`, `docs/JOURNAL_META.md`, `docs/CONFIG_CYCLE_ADMISSION.md`, and `docs/FIXTURE_DEMO.md`. Audit each occurrence rather than blindly replacing historical terminology.

Exit gate:

- no active reader, writer, UI, report route, operation, default, or current usage document depends on a legacy Household basename;
- retained legacy fixtures/checks are explicitly historical or negative-boundary evidence;
- a grep gate distinguishes permitted evidence from forbidden runtime dependencies.

### B. Retire legacy physical files from the private canonical repository

At the reviewed private `shumoku88-bit/household-ledger-data` main, these legacy files still physically exist alongside the canonical owners:

```text
accounts.tsv
plan.tsv
budget_alloc.tsv
cycle.tsv
daily_target_scope.tsv
config.tsv
report_manifests.tsv
report_all_human.tsv
report_all_compact.tsv
```

Their presence does not make them authoritative, but canonical recovery is not fully closed while live duplicate physical sources remain in the canonical data repository.

Delete them in small source-owner-specific changes only after the corresponding gate is re-proven against both engines where relevant:

1. both `bqn-ledger` and `h-kernel` read the canonical owner;
2. retained BQN reports and operations pass without the legacy file present;
3. every retained writer targets the canonical owner or is explicitly retired;
4. source identity, exact arithmetic, provenance, and writer authority are unchanged;
5. private smoke passes with the legacy file hidden/removed;
6. rollback remains available through Git history rather than a live duplicate source.

Do not delete all legacy data files in one opaque batch.

### C. Final documentation cleanup

After runtime and private-file retirement, leave one current operational story:

- one eight-file canonical source diagram;
- one setup path;
- one writer-authority explanation;
- current Journal / Plan / Budget / Account / Cycle / Daily Target / Report docs that name only canonical owners;
- historical TSV-era documents clearly moved under archive/history when still worth keeping.

README, architecture, AI/contributor guidance, examples, and doctor/setup text must agree.

## 4. Explicitly separate work

The following are not blockers for canonical Household recovery closeout:

- the BQN owner-by-owner array-native review queue in `TODO.md`;
- debt/loan versus temporary-payable product semantics;
- dedicated travel friend/exchange TSV experiments.

The travel experiments are outside the eight-file Household authority. Do not add a ninth source merely to preserve them. If they are revisited, make a separate explicit product decision to map them onto canonical owners or retire them.

Debt semantics are also separate product work. They must not be smuggled into Account identity or canonical-source cleanup.

## 5. Closeout sequence

Prefer these finite slices:

1. `bqn-ledger` legacy-reference audit and active runtime/check cleanup;
2. private legacy-file retirement, split by semantic owner and re-verified against both engines;
3. final current-documentation and fixture cleanup;
4. final eight-file-only smoke and repository grep gate.

Do not mix debt semantics, travel redesign, accounting-kernel refactors, or UI redesign into these cleanup slices.

## 6. Definition of done

Close this recovery project when all of the following are true:

- the eight canonical files are the only live Household source topology;
- all retained BQN daily capabilities and twelve reports continue to work;
- all retained writers publish only to canonical owners with qualified safety fences;
- no production code converts canonical sources back into legacy TSV authority;
- no active production/check/default path requires a retired legacy Household file;
- legacy Household files are removed from the private canonical repository after individual proof;
- current docs describe only the canonical topology;
- historical material is clearly separated;
- `tools/check.sh`, coverage, canonical source gates, and private smoke evidence pass;
- `h-kernel` and `bqn-ledger` continue to share the same canonical Household without dual-source authority.
