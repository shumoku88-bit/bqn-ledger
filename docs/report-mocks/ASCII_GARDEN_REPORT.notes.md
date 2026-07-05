# ASCII Garden Report mock notes

Status: mock / non-canonical
Owner: docs / report-mocks
Canonical: no; related path: `docs/ASCII_GARDEN_REPORT.md`
Exit: revise or discard after visual review; do not treat as production output

## Purpose

Static review mock for the ASCII garden report idea from `docs/ASCII_GARDEN_REPORT.md`.

This mock explores whether a fixed-width, peaceful, garden-like report can present ledger facts without turning the AI renderer into a calculator.

## Scope

- One static terminal mock only.
- Uses invented values.
- Exercises the scene vocabulary from `docs/templates/ASCII_GARDEN_LAYOUT.txt`.
- Keeps unknown/unavailable material as `?`.
- Keeps weather as scene context only.

## Non-goals

- No real household data.
- No source TSV reads or writes.
- No new `tools/` command.
- No BQN rendering implementation.
- No claim that the exact layout is final.

## Review questions

1. Does the scene feel calm rather than dashboard-like?
2. Are WARN / unknown values still visible enough?
3. Is the distinction between accounting facts and weather clear?
4. Is 100-column fixed-width acceptable, or should the scene be wider?
5. Should the factual legend be more compact or more explicit?

## Safety notes

The numbers in `ASCII_GARDEN_REPORT.mock.txt` are deliberately fake. Do not copy real `LEDGER_DATA_DIR` output into this mock.

If a real materials bundle is introduced later, it should be private by default when weather or household data is included.
