# Retained Issues report

Status: Portfolio P9 destination proof

Owners:

- `src/ledger/issue_admission.bqn` — strict non-accounting source admission;
- `src/sections/issues.bqn` — retained source-ordered open List and human renderer.

## Strict source

The current schema is exactly:

```text
issue_id  status  date  due  category  title  amount  currency  details
```

with tab separators and this exact header. During the bounded shared-source migration window, the exact legacy header without `due` is also admitted. A legacy row has no due evidence and therefore normalizes to `undetermined`, never `none`. Rules:

- `issue_id` is required and unique;
- status is `open | resolved | dropped`;
- recorded `date` is empty or strict Gregorian `YYYY-MM-DD` and is never repurposed as due;
- `due` is `none`, `undetermined`, or a strict Gregorian `YYYY-MM-DD`;
- category and title are required;
- amount and currency are both absent or both present;
- present amount is an exact unsigned decimal within registry currency precision;
- details may be empty;
- extra/missing columns are rejected;
- physical source row and `issues.tsv:row:N` reference are retained;
- any invalid row rejects the whole source and publishes no partial List.

An absent optional source and a header-only source are both valid empty evidence. Issue rows do not become Transaction/Posting Facts and are never monetary obligations merely because an amount is present.

## Section

The retained default selection is `status=open`, preserving admitted source order. The aligned result and human output retain recorded date and three-way due meaning as separate coordinates, alongside category, title, optional exact amount/currency, and details. Missing recorded date/amount remains visibly absent rather than becoming a sentinel date or numeric zero.

Portfolio P1 supports human only. There is no compact or JSON renderer.

## Editor migration boundary

Issue add/list/close support only the same exact legacy and current headers. Add observes the target header beside the Issue writer: legacy files remain eight columns, current files remain nine columns, and a new current row with no due input writes explicit `undetermined`. Close changes status and decision details while preserving the original source width and exact due coordinate.

This compatibility does not migrate or confer writer authority over the separately owned canonical Household source. Explicit due-entry UI remains a later slice; no path accepts `DueOn` or `NoDueDate` and then silently discards it into a legacy row.

## Proof

Public tests cover ordered open/resolved rows, optional recorded date and amount, all three due states, invalid due text and Gregorian dates, exact ILS amount, source coordinates, absent/header-only source, invalid status/date/amount-currency pair/precision, duplicate identity, all-or-nothing failure, open-only selection, empty List, source-width-preserving add/close, and deterministic human rendering.
