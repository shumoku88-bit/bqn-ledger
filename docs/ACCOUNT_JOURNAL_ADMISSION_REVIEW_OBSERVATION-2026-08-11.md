# Canonical Account Journal admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review started from main `e29ceb190e60401108321d61ce4af7338198fe05`
- active owner: `src/ledger/account_journal_admission.bqn`
- canonical application reader: `src/application/account_source_adapter.bqn`
- predecessor `src/ledger/account_admission.bqn` was classified separately as a legacy `accounts.tsv` retirement seam in PR #644

## Ownership

This owner is the canonical Account source grammar for `accounts.journal`.

It owns only:

- Account identity;
- accounting type, with `role` as an accepted source synonym;
- optional default Commodity;
- declaration order;
- source row;
- strict rejection of unsupported Account Journal source structure.

Household policy classifications stay outside this owner. PR #590 already removed obsolete Household policy Account carriers from the canonical Account result.

## Existing grammar

The source is sequential and block-structured:

- `account ...` starts an Account declaration;
- indented lines belong to the active Account;
- indented comments may carry admitted metadata such as `; ROLE: expense`;
- a top-level comment does not terminate the active Account;
- a blank line terminates the active Account;
- the next top-level non-comment line also terminates the active Account before that line is interpreted;
- indented non-comment source outside an Account is rejected;
- only Account declarations and comments are admitted at top level.

The prior implementation represented this grammar by carrying one mutable active state across every physical line: active flags, current Account fields, metadata counts, error state, and an explicit `Finalize` transition.

## Characterization before refactor

Focused laws were added before production change to make block lifetime explicit:

1. a top-level comment bridges an Account header to later indented metadata;
2. adjacent Account directives close/open blocks without requiring a blank line;
3. a blank finalizes the prior Account and makes later indented metadata outside-block source;
4. an unsupported top-level block first finalizes the prior Account, preserving diagnostic order.

These laws passed full repository check and coverage in CI #2581 on the characterization-only head before the production refactor.

## BQN-native model

The file-wide active state is not required to express block ownership. Physical lines can first become aligned classification arrays:

```text
line
  -> blank / indented / comment / top-level
```

Blank lines and top-level non-comment lines define segment starts. A prefix Scan gives each line one segment coordinate, and Group gathers physical line indices into ordered source segments:

```text
blank ∨ top-level-noncomment
  -> Scan
  -> segment id per physical line
  -> Group
  -> ordered source segments
```

Each segment is then independently classified as:

- canonical Account block, parsed by a local Account admission state; or
- outside-Account source, producing unsupported-block and/or unexpected-indentation diagnostics.

This keeps the source grammar sequential while moving the sequence coordinate into an explicit array.

## Why local state remains

Within one Account block, metadata meaning is genuinely order-sensitive enough to retain small named state:

- first type/role owns the admitted type;
- later type/role occurrences are duplicate diagnostics;
- first valid Commodity owns the optional default Commodity;
- later Commodity occurrences are duplicate diagnostics;
- diagnostics remain in physical source order.

Replacing these local counters and fields with compressed tacit expressions would not improve the semantic model. The target is not mutation elimination as a slogan. The useful subtraction is removal of the file-wide active-block lifecycle.

## Whole-array evaluation lesson

The first production implementation exposed one important difference between branch-local and whole-array evaluation.

`StartsDirective` previously used `n↑text` only when control flow had already established a plausible top-level directive. After source classification became a whole-array operation, the helper was evaluated for every physical line, including short lines whose arrays did not necessarily carry a fill element. The canonical Account append writer exposed this as:

```text
𝕨↑𝕩: Fill element of 𝕩 needed for overtaking
```

The failure was not a source-grammar disagreement. The helper itself was partial over inputs that the new array model legitimately supplies.

The final form pads the candidate text explicitly before taking the fixed-width prefix:

```text
prefix ← n↑text∾n⥊space
```

and still masks the result with the original `enough` and token-boundary laws. This makes directive classification total without changing which source lines count as Account directives.

A focused writer round-trip law now constructs the exact complete-source candidate produced by `src_edit/account_add_cmd.bqn` and proves that the seventh appended Account is admitted with its intended key, role, type, and Commodity.

## Failed-run record

The failed runs are retained as design evidence rather than hidden:

- CI #2582: the first segmented production owner passed focused BQN characterization but failed the canonical Account mutation shell qualification;
- CI #2584: temporary shell instrumentation localized the failure to Account Add dry-run;
- CI #2585, #2588, #2589, and #2590: temporary writer-candidate probes narrowed the problem while some probe/output forms themselves were intentionally discarded rather than retained as evidence;
- CI #2592: exact writer output exposed the partial `StartsDirective` prefix take and its missing-fill error;
- CI #2593: after making directive classification total, full `tools/check.sh` and coverage succeeded, including canonical Account add/write qualification;
- CI #2595: after removing all temporary instrumentation and retaining the clean writer round-trip law, full `tools/check.sh` and coverage succeeded again.

No temporary debug test or shell instrumentation remains in the final branch diff.

## Protected contracts

The refactor preserves:

- canonical Account order and source rows;
- `type` / `role` synonym behavior and canonical type casing;
- optional Commodity without implicit fallback;
- indented comment metadata;
- unsupported top-level block rejection;
- unsupported metadata rejection;
- missing, duplicate, and invalid type diagnostics;
- duplicate and invalid Commodity diagnostics;
- duplicate Account identity rejection;
- diagnostic ordering at block boundaries;
- fail-closed Account publication;
- public Account carrier shape and canonical application consumers;
- canonical Account writer complete-source admission and round-trip semantics.

## Review decision

Retain `account_journal_admission.bqn` as the canonical grammar owner. Replace the global active/Finalize state machine with whole-source line classification plus Scan/Group segmentation, while retaining small local block state where it directly expresses Account metadata laws.

The useful BQN lesson is not merely “use Group”. Moving a sequential source grammar into a whole-array model also requires helpers used across that array to be total over the expanded evaluation domain.
