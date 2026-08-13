# `src_edit/account_validate_cmd.bqn` Phase 6 observation — 2026-08-13

## Scope

Owner under review:

- `src_edit/account_validate_cmd.bqn`

This is the mandatory post-write validator invoked by the safe Account append path in `tools/lib/edit-bqn-common.sh`.

## Observation

No production rewrite is justified.

The command has one narrow responsibility:

1. admit exactly one base-directory argument;
2. load canonical Accounts through `src/application/account_source_adapter.bqn`;
3. on rejection, preserve the admitted diagnostic stage/code/message sequence;
4. on success, publish only `OK\tACCOUNTS_JOURNAL\t<count>`.

It does not reparse `accounts.journal`, duplicate Account schema knowledge, inspect legacy `accounts.tsv`, infer Household classification, or perform shell-owned validation.

The safe-write layer uses this command after an Account append as mandatory canonical post-admission. That ownership is appropriate: the shell controls physical publication/rollback while BQN re-observes the canonical semantic source.

## Why not generalize it

The file is small because its effect boundary is real, not because an abstraction is missing. Folding it into a generic editor validator would hide the important fact that Account writes have mandatory post-publication canonical admission and would couple unrelated writer families.

Likewise, moving the `OK` protocol into Account admission would mix reusable semantic admission with one command-line publication protocol.

## Evidence

Existing Account writer checks already exercise:

- successful mandatory Account validation after write;
- forced post-admission failure;
- rollback to exact original bytes;
- refusal to overwrite a later concurrent writer;
- invalid canonical Account source failure before publication.

No new characterization is needed solely to preserve this thin leaf.

## Decision

`src_edit/account_validate_cmd.bqn` is reviewed; production remains unchanged.

The normal Phase 6 cursor can advance to:

`src_edit/actual_journal_file_cmd.bqn`
