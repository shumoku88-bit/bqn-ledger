# Next session

Status: selected finite canonical TSV-to-native Journal prefix converter; implementation instructions fixed
Owner: journal source migration / conversion
Canonical: yes; canonical plan is `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`
Execution: `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_IMPLEMENTATION_INSTRUCTIONS.md`
Exit: converter implementation, synthetic validation, private read-only verification, independent review, completion archive, and explicit return to no selected Journal slice
Date: 2026-07-22

## Current routing

The legacy metadata/profile prerequisite is complete and archived at `docs/archive/completed-plans/JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN-2026-07-22.md`.

The **Canonical TSV-to-native Journal prefix converter** remains selected and its public-synthetic implementation instructions are fixed. It must preserve canonical `source_event_id`, distinct optional business `txn_id`, the complete mapped legacy metadata vocabulary, transaction/posting order, and fail-closed diagnostics while keeping the current 16-field Posting IR and production TSV route unchanged.

## Owner description decision

The converter must not trim, normalize, rewrite, split, or reinterpret the TSV memo/description. It may render only a nonempty description with no unsafe control input and no leading or trailing ASCII space, and the complete generated Journal must parse back to the exact same Unicode code-point sequence. Otherwise it must fail closed with `description_not_canonically_representable` and publish no prefix.

## Explicit gates

- The implementation branch must start from the post-PR-320 `main` SHA and a clean local/remote state.
- Only public synthetic evidence is authorized until a separately gated private read-only verification.
- `currency=ILS`, fractional or incompatible commodity evidence remains fail-closed; no currency-profile expansion is included.
- Account declaration rendering must be proven against the existing registry and Journal profile before implementation proceeds. If required account semantics cannot be represented, stop and report a separate prerequisite.
- No private conversion, reconstruction, suffix replacement, production parser routing, production writer change, source-truth change, cutover, dual write, reverse synchronization, or conflict resolution is authorized.
- Production cutover remains blocked and is not selected automatically.
