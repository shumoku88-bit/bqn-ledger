# Next session

Status: selected finite-slice pointer
Owner: repository routing
Canonical: no; canonical contract: `docs/JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN.md`; program routing: `TODO.md`
Exit: replace after the selected focused test lands; archive the plan and return routing to no finite slice selected unless a separate decision explicitly selects follow-up work

## Selected finite slice

Implement only **Journal read-path trial-balance rehearsal — test-only**:

- current contract: `docs/JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN.md`;
- reuse the existing public `fixtures/journal-native-three-posting-parity/` Journal and account fixture;
- read `profile.journal` directly;
- use the existing `journal_profile_stage1.Parse` and `journal_posting_ir_stage2a.Build` paths;
- pass the resulting three successful Journal-derived Posting IR rows through `context.BuildPeriodView`;
- construct only the minimal test-local context carrier required by `trial_balance.Build`;
- prove the expected three-account actual-layer movements and zero-sum Trial Balance;
- do not use the legacy TSV projection in the selected read path.

Stage 2A, Stage 2B, Stage 2C, and native three-posting semantic-coordinate parity remain completed. This rehearsal is selected but not implemented.

## Non-goals

Do not add or begin:

- changes to `context.BuildContext` or `LoadPostingSourceSnapshot`;
- production Journal loader or routing;
- Journal and TSV mixing in a production context;
- a new `src_next` helper, export, normalizer, or production carrier;
- Posting IR, Cube, TBDS, Trial Balance, report, parser, or Stage 2A contract changes;
- full summary or human-report execution from Journal;
- shadow read, private-data comparison, writer/editor work, conversion, cutover, or source-of-truth changes;
- `source_row` consumer migration;
- broader parser red-path/rejection parity;
- TSV cleanup or production source changes;
- any automatically selected later Journal stage.

If the rehearsal requires production access, private data, a production route, a contract change, fixture semantic changes, or flattening native postings into legacy rows, stop and request a separate design decision.

After implementation completes, archive the current contract and return routing to “no next finite slice selected.” Do not choose a follow-up automatically.
