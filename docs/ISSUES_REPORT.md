# Retained Issues report

Status: Portfolio P9 destination proof

Owners:

- `src/ledger/issue_admission.bqn` — strict non-accounting source admission;
- `src/sections/issues.bqn` — retained source-ordered open List and human renderer.

## Strict source

Destination schema is exactly:

```text
issue_id  status  date  category  title  amount  currency  details
```

with tab separators and this exact header. Rules:

- `issue_id` is required and unique;
- status is `open | resolved | dropped`;
- date is empty or strict Gregorian `YYYY-MM-DD`;
- category and title are required;
- amount and currency are both absent or both present;
- present amount is an exact unsigned decimal within registry currency precision;
- details may be empty;
- extra/missing columns are rejected;
- physical source row and `issues.tsv:row:N` reference are retained;
- any invalid row rejects the whole source and publishes no partial List.

An absent optional source and a header-only source are both valid empty evidence. Issue rows do not become Transaction/Posting Facts and are never monetary obligations merely because an amount is present.

## Section

The retained default selection is `status=open`, preserving admitted source order. Human output displays date, category, title, optional exact amount/currency, and details. Missing date/amount remains visibly absent rather than becoming a sentinel date or numeric zero.

Portfolio P1 supports human only. There is no compact or JSON renderer.

## Editor migration boundary

Current production editor commands still operate the historical five-column schema:

```text
date  status  title  amount  memo
```

They are not destination admission consumers and must not be silently pointed at the strict schema while private/user sources may still use the historical form. At atomic cutover, issue add/list/close must migrate together to `issue_admission.bqn` semantics and durable `issue_id`; no dual parser or five-to-eight-column fallback is permitted.

That source migration requires the repository's explicit private-source protocol before user data is inspected or rewritten. Until then, destination proof uses only `fixtures/ledger-facts-phase1-proof/issues.destination.tsv`, which current production does not read.

## Proof

Public tests cover ordered open/resolved rows, optional date and amount, exact ILS amount, source coordinates, absent/header-only source, invalid status/date/amount-currency pair/precision, duplicate identity, all-or-nothing failure, open-only selection, empty List, and deterministic human golden.

Production routing remains unchanged until atomic cutover.
