# Friend travel JPY finalization post-implementation verification

Status: audit snapshot
Owner: currency / safety
Canonical: no; canonical plan: `docs/archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`
Exit: retained as the independent verification record for PR #210's pure-preview slice

## Scope and identity

This docs-only review compares the selected active plan with merged `main`, the focused unit tests, local check results, and the exact implementation-head CI result. It does not authorize or modify a writer, source TSV, source-event storage, status/index persistence, public entrypoint, fixture, report, editor/UI, FX, foreign posting, or clearing path.

Implementation identity:

- implementation PR: #210, merged;
- final implementation head: `37f8edb5ec4511eddcda5fd18caedb5e1a5236af`;
- merge commit: `078de24e8178b160f0cf63f1ed60f828f65dd9a9`;
- CI check run #759: success as supplied in the implementation identity;
- GitHub PR evidence independently reports head `37f8edb5ec4511eddcda5fd18caedb5e1a5236af`, merge commit `078de24e8178b160f0cf63f1ed60f828f65dd9a9`, and completed `check` conclusion `SUCCESS` (Actions run `29239437757`, job `86781663738`).

The implementation diff from the merge commit's first parent to the final head contains only `TODO.md`, `docs/AI_CODEMAP.md`, the active plan, `src_next/friend_travel_jpy_finalization.bqn`, and its unit test. The runtime implementation is isolated to the new module and is not imported outside its focused test.

## Classification method

- `verified`: merged code directly establishes the claim and focused tests or repository/CI evidence exercise or corroborate it.
- `partially verified`: only part of the claim has direct evidence.
- `rejected`: merged behavior contradicts the claim.
- `not evidenced`: available code, tests, execution, and exact-head CI do not establish the claim.

## Claim-to-evidence verification

| Claim | Classification | Merged-main evidence |
|---|---|---|
| API is the I/O-free `ValidateAndPreview` | verified | The module exports only `ValidateAndPreview`; its only imports are pure date and exact-decimal helpers. It contains no file, environment, clock, shell, or writer operation. Focused test calls this API directly. |
| It reads nothing beyond the supplied request | verified | `ExtractRequest` copies only required members from `request`; validation and preview consume that normalized value. There is no source/config/environment read. Imported helper code supplies algorithms, not request data. |
| Purchase date and finalization date are separate | verified | `event.date` and `request.finalization_date` receive independent date diagnostics; `PreviewRow.date` uses only `finalization_date`. Tests reject each independently and assert preview date differs from purchase date. |
| Original amount is a positive exact decimal | verified | `decimal.Parse event.original_amount` plus `state="ok"` and positive coefficient is required. Tests reject empty, malformed, zero, zero-scale variants, and negative values while accepting an exact decimal. |
| Original currency is a three-character uppercase source-fact token | verified | `IsCurrencyToken` requires exactly three ASCII uppercase letters and does not apply the canonical posting allowlist. Tests reject malformed tokens and accept `CHF`. |
| JPY amount is a positive integer only | verified | Exact-decimal parse must have positive coefficient and scale zero; preview formats that coefficient. Tests reject malformed, zero, negative, and fractional values and verify canonical integer output. |
| Explicit existing JPY liability and expense descriptors are required | verified | Required descriptor members are extracted; `AccountDiagnostics` requires safe name, `exists=1`, `currency="JPY"`, and exact liability/expense role. Missing members fail closed; unknown, non-JPY, and wrong-role cases are tested for both endpoints. |
| Role/currency are not inferred from account names | verified | Validation reads descriptor `role` and `currency` fields directly. Wrong metadata is rejected independently of the supplied name; no prefix/name parser exists in this module. |
| Accepted result has exactly one preview row | verified | Success constructs `preview_rows⇐⟨PreviewRow ...⟩`; accepted test asserts one row and no diagnostics. |
| Row direction is JPY liability → JPY expense | verified | `from_account` is the validated liability descriptor name and `to_account` is the validated expense descriptor name. Accepted test asserts both endpoints. |
| Preview date is finalization date | verified | `PreviewRow.date ⇐ request.finalization_date`; accepted test asserts `2026-07-13`, not the event's `2026-06-15`. |
| Metadata is `currency=JPY`, `source_event_id`, and `trip_id` | verified | `PreviewRow.metadata` constructs exactly those three ordered entries; accepted test asserts the full vector. |
| Original foreign amount is not emitted as canonical expense | verified | Preview amount comes only from parsed `jpy_amount`; original amount is used only for validation. Test asserts output amount differs from the event's original amount and contains no foreign currency marker. |
| There is no foreign row, clearing row, or second row | verified | The sole success constructor produces one row with validated JPY endpoints; no alternate row constructor exists. Tests assert one row and absence of foreign/clearing endpoint evidence. |
| Duplicate `source_event_id` is rejected | verified | Membership in supplied `existing_finalization_ids` adds `source_event_already_finalized`; any diagnostic leaves zero rows. Test includes repeated matching entries and asserts this diagnostic. |
| Independent diagnostics are collected in deterministic order | verified | `ValidateExtractedRequest` appends each independent diagnostic in a fixed source order, followed by account and duplicate checks. Multi-error test asserts the leading deterministic sequence; all rejection tests enforce nonempty diagnostics and zero rows. |
| Any error produces zero preview rows | verified | Error result is initialized with empty rows and success replacement occurs only when diagnostic count is zero. `CheckRejected` applies the zero-row invariant across all invalid-case tests. |
| Missing namespace members fail closed as `request_shape_invalid` | verified | Required-member extraction is guarded and returns one fixed shape diagnostic with zero rows. Tests cover missing top-level, event, account, and index members. |
| Only the extraction boundary catches member absence; validation/preview as a whole is not caught | verified | The sole catch (`⎊`) is attached to `ExtractRequest`; `ValidateExtractedRequest` and `PreviewRow` are invoked outside that catch. Thus implementation defects after extraction remain visible rather than being converted to shape errors. |
| Diagnostic messages do not reflect private values | verified | Messages are fixed literals. Focused tests inject private dates, memo text, amounts, IDs, currencies, state, and account names, then assert none occur in diagnostic messages; shape diagnostics are similarly checked. |
| Source status and finalization index are not changed | verified | Status and supplied IDs are read only for validation/membership. The module has no mutation/write API and returns only state, diagnostics, and preview rows. |
| Writer and public runtime remain disconnected | verified | Repository search outside docs and the focused test finds no import or call of this module/API. The PR diff adds no tool, editor, report, dispatcher, or writer connection. |
| Strict-source Steps 2–5 and M4 remain unselected | verified | The active plan and `TODO.md` explicitly keep them independent and unselected; PR #210 added no strict-source runtime or M4 implementation. |

## Execution evidence

Executed from merged `main` without resolving or reading the effective real-data directory:

```text
bqn tests/test_src_next_friend_travel_jpy_finalization.bqn
  PASS — test_src_next_friend_travel_jpy_finalization.bqn: OK

env -u LEDGER_DATA_DIR rtk bash ./tools/check.sh
  PASS — all five phases completed; devtools-check 14 passed / 0 failed

rtk tools/coverage
  PASS — inventory includes test_src_next_friend_travel_jpy_finalization.bqn
```

`git diff --check` is recorded after this docs-only change in the final verification pass.

## Verdict and routing

All required claims are `verified`; none are partially verified, rejected, or not evidenced. The selected pure validation plus all-or-nothing one-row JPY preview slice is therefore independently verified and closed.

This verdict does **not** select or reject a future atomic write design. Source-event status transition, durable finalization index, and journal append remain one explicitly unselected candidate that would require a separate plan covering atomicity, recovery, stale checks, backup, and post-write evidence. No writer is auto-selected. Strict-source Steps 2–5 and M4 remain independently unselected.

The active plan remains active under its Exit contract because the follow-up atomic write slice has been neither selected nor declined. Its completed pure-preview portion must not be treated as continuing implementation authority.
