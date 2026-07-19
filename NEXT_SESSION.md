# Next session

Status: selected finite-slice pointer
Owner: repository routing
Canonical: no; canonical contract: `docs/JOURNAL_NATIVE_THREE_POSTING_SEMANTIC_COORDINATE_PARITY_PLAN.md`; program routing: `TODO.md`
Exit: replace after the selected fixture and focused test land; archive the plan and return routing to no finite slice selected unless a separate decision explicitly selects follow-up work

## Selected finite slice

Implement only **Journal native three-posting semantic-coordinate parity — test-only**:

- current contract: `docs/JOURNAL_NATIVE_THREE_POSTING_SEMANTIC_COORDINATE_PARITY_PLAN.md`;
- one dedicated public synthetic fixture derived from the Stage 0 split receipt;
- exactly one native actual Journal transaction with three ordered postings;
- exactly two legacy TSV rows producing four Posting IR rows and sharing one nonempty `txn_id`;
- primary parity boundary: `(date, account_key, layer_name) -> sum(delta)`;
- secondary parity boundary: numeric Cube equality on the same explicit axes;
- preserve, rather than normalize away, Journal three-row versus legacy four-row topology;
- keep any comparison/reduction carrier inside the focused test.

Stage 2A, Stage 2B, and Stage 2C remain completed. This slice is selected but not implemented.

## Non-goals

Do not add or begin:

- broader rejection/red-path parity;
- Stage 1 parser or Stage 2A adapter specification changes;
- a production helper, normalizer, Journal loader, or runtime route;
- `BuildContext`, TBDS, or report connection;
- `source_row` consumer migration or identity/provenance contract changes;
- writer/editor work, shadow read, conversion, cutover, or source-of-truth changes;
- TSV cleanup, private-data access, or production source changes;
- a numbered follow-up label or any automatically selected later stage.

If the selected comparison requires a production normalizer, contract change, production route, cross-source identity unification, parser/adapter specification change, or private data, stop and request a separate design decision.

After implementation completes, archive the current contract and return routing to “no next finite slice selected.” Do not choose a follow-up automatically.
