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

These laws passed the full repository check and coverage on the characterization-only head before the production refactor.

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

## Protected contracts

The refactor must preserve:

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
- public Account carrier shape and canonical application consumers.

## Review decision

Retain `account_journal_admission.bqn` as the canonical grammar owner. Replace the global active/Finalize state machine with whole-source line classification plus Scan/Group segmentation, while retaining small local block state where it directly expresses Account metadata laws.
