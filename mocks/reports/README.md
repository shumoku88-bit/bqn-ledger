# Report mocks

This directory contains public mock terminal outputs for BQN Ledger reports.

The files here are not real household data. They are design specimens used to review report layout, section order, labels, and terminal readability before or during implementation.

## Rules

- Do not commit real source TSV.
- Do not commit raw real report output.
- Do not commit intermediate unsanitized output.
- Public mocks must follow [`docs/REPORT_MOCK_SANITIZATION.md`](../../docs/REPORT_MOCK_SANITIZATION.md).
- Prefer synthetic values when the exact value is not needed for the report design.

## Naming

Use names that describe the report surface:

```text
sanitized-ledger-report.mock.txt
command-hub.mock.txt
report-selection.mock.txt
account-matrix.mock.txt
daily-flow.mock.txt
envelope-status.mock.txt
```

## Intent

These mocks help keep the report design concrete without exposing private data.

They should answer questions like:

- What does the user see first?
- Which sections exist?
- Are columns aligned?
- Are account roles readable?
- Does the report preserve accounting direction and daily flow?
- Which parts are still undecided?
