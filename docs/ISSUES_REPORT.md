# Retained Issues report

Status: Portfolio P9 destination proof

Owners:

- `src/ledger/issue_admission.bqn` — strict non-accounting source admission;
- `src/sections/issues.bqn` — retained source-ordered open List and human renderer.

## Strict source

The current schema is exactly:

```text
issue_id  status  date  due  closed  category  title  amount  currency  details
```

with tab separators and this exact header. During the bounded shared-source migration window, the exact earlier nine-column header without `closed` and the older eight-column header without `due`/`closed` are also admitted. Missing historical evidence is normalized without invention: an earlier `open` row gets `closed=none`, while an earlier `resolved`/`dropped` row gets `closed=undetermined`; an eight-column row also gets `due=undetermined`. Rules:

- `issue_id` is required and unique;
- status is `open | resolved | dropped`;
- recorded `date` is empty or strict Gregorian `YYYY-MM-DD` and is never repurposed as due or close time;
- `due` is `none`, `undetermined`, or a strict Gregorian `YYYY-MM-DD`;
- `closed` is `none`, `undetermined`, or a strict Gregorian `YYYY-MM-DD`;
- `open` requires `closed=none`;
- `resolved` and `dropped` require a known close date or `closed=undetermined`, never `none`;
- a known close date cannot precede a known recorded date;
- category and title are required;
- amount and currency are both absent or both present;
- present amount is an exact unsigned decimal within registry currency precision;
- details may be empty;
- extra/missing columns are rejected;
- physical source row and `issues.tsv:row:N` reference are retained;
- any invalid row rejects the whole source and publishes no partial List.

An absent optional source and a header-only source are both valid empty evidence. Issue rows do not become Transaction/Posting Facts and are never monetary obligations merely because an amount is present.

## Section

The retained default selection is `status=open`, preserving admitted source order. The aligned result retains recorded date, three-way due meaning, and close lifecycle as separate coordinates, alongside category, title, optional exact amount/currency, and details. The human open-Issue table displays recorded date and due; its selected rows necessarily carry `closed=none`, so the close coordinate is not repeated as a visual column. Missing recorded date/amount remains visibly absent rather than becoming a sentinel date or numeric zero.

Portfolio P1 supports human only. There is no compact or JSON renderer.

## Editor migration boundary

Issue add/list/close admit the exact eight-, nine-, and ten-column headers during the bounded migration window and preserve an existing target's source width. A newly created source uses the ten-column header. New open rows write `due=undetermined` and `closed=none`; direct creation of an already-closed row writes `closed=undetermined` rather than fabricating historical close evidence.

On a ten-column source, close changes status, records one strict close date, and appends the decision details in the same candidate row while preserving due and all unrelated fields. The shell adapter supplies its local calendar date by default and exposes `--closed-date YYYY-MM-DD` for explicit/reconstructible invocation. A close date cannot be passed to an eight- or nine-column target because those schemas cannot represent it; the command fails rather than silently discarding the date.

The canonical shared Household source must not be widened until every active engine admits the ten-column schema. This compatibility does not confer writer authority over that separately owned source.

## Proof

Public tests cover ordered open/resolved rows, optional recorded date and amount, all three due states, all three close states, status/close lifecycle consistency, invalid Gregorian due/close dates, close-before-recorded rejection, exact ILS amount, source coordinates, absent/header-only sources, invalid status/date/amount-currency pair/precision, duplicate identity, all-or-nothing failure, open-only selection, empty List, source-width-preserving add/close, close-date stamping on ten-column sources, and deterministic human rendering.
