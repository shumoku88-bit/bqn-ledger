# Next session

Status: selected finite-slice pointer
Owner: repository routing
Canonical: no; canonical routing: `TODO.md` and `docs/JOURNAL_POSTING_IR_COMPARABLE_REJECTION_PARITY_STAGE2C_PLAN.md`
Exit: replace after Stage 2C implementation is completed or explicitly deselected; do not infer a later stage

## Selected finite slice

Implement only Journal Posting IR comparable rejection parity Stage 2C from:

- `docs/JOURNAL_POSTING_IR_COMPARABLE_REJECTION_PARITY_STAGE2C_PLAN.md`

Stage 2A success parity and Stage 2B identity/provenance parity remain completed. Stage 2C implementation is not completed.

The selected test-only slice contains exactly three public synthetic cases representable by both source paths:

1. invalid date;
2. invalid exact-integer amount;
3. unknown account.

Use the existing Stage 1 parser, Stage 2A adapter, checked TSV snapshot adapter, and legacy Cube acceptance boundary directly. Keep any comparison carrier inside the focused test. Add no `src_next` helper and require structural rejection parity, not diagnostic-code equality.

## Still unselected

- unbalanced explicit Journal postings and the broader parser red path;
- native Journal parity for three or more postings;
- Stage 2D or any later Journal stage;
- production Journal loader or routing;
- writer/editor work;
- TSV-to-Journal conversion;
- shadow read or private-data comparison;
- source-of-truth cutover;
- report, Cube, or TBDS changes;
- `source_row` consumer migration;
- bidirectional/reverse sync or conflict resolution;
- TSV cleanup or production source TSV changes.

Complete only the finite contract above, then update routing without automatically selecting a follow-up.
