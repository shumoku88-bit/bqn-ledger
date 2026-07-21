# Next session

Status: finite slice selected
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: complete the focused implementation and return routing to no selected finite Journal slice

## Selected slice

Journal resolved-account registry mismatch rejection — test-only.

Canonical finite contract:

- `docs/JOURNAL_RESOLVED_ACCOUNT_REGISTRY_MISMATCH_REJECTION_PLAN.md`

## Finite question

When Stage 1 successfully admits a balanced Journal transaction whose declared posting account is absent from the supplied resolved account registry, can the Stage 2A / read-only carrier boundary return a structured error with no partial Posting IR rows, while preserving all existing success-path contracts and remaining disconnected from production routing?

## Required boundary

1. Stage 1 remains `ok` because both posting accounts are validly declared inside the public synthetic Journal.
2. Stage 2A owns mapping admitted posting accounts onto `resolved.accounts`.
3. If any posting account is absent from that registry, Stage 2A returns `error`, zero `posting_rows`, and a `journal_posting_ir_stage2a` diagnostic with code `posting_account_unresolved`.
4. Rejection is all-or-nothing. The valid counterpart posting must not leak as a successful row.
5. The read-only source carrier propagates the adapter error and diagnostic while retaining its result-level `source_file`.
6. Existing successful 16-field Posting IR rows and all current success-path tests remain unchanged.

## Expected implementation scope

- `src_next/journal_posting_ir_stage2a.bqn`
- `tests/test_journal_resolved_account_registry_mismatch_rejection.bqn`
- optional dedicated public synthetic fixture only when it improves clarity
- required routing and completion documentation

Prefer the smallest pure validation at the Stage 2A boundary. Do not duplicate account-resolution policy in the carrier.

## Still unselected

- broader parser or adapter red-path coverage;
- automatic account creation, synchronization, aliases, or fuzzy matching;
- malformed resolved-registry campaigns beyond the selected absent-account case;
- production Journal loader or routing;
- writer/editor work;
- TSV-to-Journal conversion;
- shadow read or private-data comparison;
- source-of-truth cutover;
- `BuildContext`, report, Cube, or TBDS production changes;
- `source_row` consumer migration;
- reverse synchronization or conflict resolution;
- any later Journal stage.

## Validation

Run the focused test, affected Journal/read-path tests, documentation checks, `git diff --check`, and `bash tools/check.sh`. Preserve production source TSV and private data unchanged.
