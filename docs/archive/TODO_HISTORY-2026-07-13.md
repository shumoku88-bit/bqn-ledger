# TODO History — 2026-07-13

Status: historical
Owner: docs
Canonical: no; current route: `TODO.md`
Exit: retained as the completion record for finite work closed on 2026-07-13

## Strict production source currency enforcement: Step 1 admission core

Status: completed and separately verified.

Implementation identity:

- PR #207: `feat: add source currency admission core`
- final implementation head: `c37c75a7671822d472475a1564cf6b8202e39a56`
- merge commit: `3ca72e6f9484b3f57a6ea6748ac887d69c447c90`
- CI run #750: pass

Verified result:

- added the closed `production_strict` / `legacy_compatibility` policy carrier and pure supplied-source admission core;
- added structured privacy-safe diagnostics and complete no-partial-admission behavior on error;
- validates only allowlisted posting source basenames and fail-closes path-shaped or unknown supplied source names without reflecting them;
- public wiring, existing fallbacks, fixtures, writers, and production source remain unchanged.

Routing after closure:

- Steps 2–5 are not selected;
- writer closure, compatibility preparation, production read activation, post-implementation verification, and M4 do not auto-start.

## Currency Mixed-Ledger M3: Currency-selected balances report

Status: completed and separately verified.

Implementation identity:

- PR #204: `feat: add M3 currency-selected balances`
- final implementation head: `8fa9947b56e4f190569be7550c270f69d35d98d5`
- merge commit: `ba4a02f28d4479bb5f92bf65a136dd7e16ada839`

Verified result:

- human `balances` accepts explicit JPY/ILS selection and ledger-default selection;
- output states effective currency and selection provenance;
- checked selected-currency projection feeds existing single-currency balances arithmetic;
- JPY and ILS accounts, postings, and totals remain separate;
- ILS displays exactly two decimal places and rejects source precision above two without rounding;
- unsupported selection, invalid default/evidence, and non-balances `--currency` routes fail closed;
- existing balances JSON remains unchanged;
- no strict-source enforcement, other-section currency work, FX, conversion, valuation, Currency axis, or production-source mutation was included.

Verification record:

- `docs/archive/audits/CURRENCY_MIXED_LEDGER_M3_POST_IMPLEMENTATION_VERIFICATION-2026-07-13.md`

Routing after closure:

- no next finite slice is selected;
- strict production source enforcement remains candidate only;
- M4 remains candidate only.
