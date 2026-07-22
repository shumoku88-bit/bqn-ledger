# Next session

Status: selected finite Journal external-plan-reference profile prerequisite; docs-only contract fixed
Owner: journal source migration / test-only Journal profile
Canonical: yes; current prerequisite is `docs/JOURNAL_EXTERNAL_PLAN_REFERENCE_PROFILE_PREREQUISITE_PLAN.md`
Parent: `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`
Exit: separate prerequisite implementation, public-synthetic validation, completion archive, and explicit owner review before converter work may resume
Date: 2026-07-22

## Current routing

The **Journal external plan reference profile prerequisite** is selected. Current strict `journal_profile_stage1.Parse` requires every actual transaction carrying `plan-id` to match exactly one plan transaction in the same parsed Journal. Legacy `plan_id` instead links `plan.tsv` and `journal.tsv`, so an actual-only historical prefix can legitimately retain an external plan reference with zero in-document plans.

The selected prerequisite must add an explicitly selected non-production historical profile that admits only this zero-match actual `plan-id` case. Existing default `Parse` remains strict. One internal match still requires `execution-envelope` agreement; duplicate plan targets and every other cross-link invariant remain fail closed. Transaction IR and the 16-field Posting IR schema remain unchanged.

## Explicit gates

- The docs-only selection must be reviewed and merged before implementation begins on a separate branch and Draft PR.
- Use only public synthetic evidence.
- Unknown profile selection must fail closed; no automatic profile detection or global fallback is allowed.
- Do not synthesize plan transactions, add `plan.tsv` to converter input, drop `plan-id`, or change plan lifecycle semantics.
- The canonical TSV-to-native Journal prefix converter remains selected but blocked. Its implementation is stopped and not started.
- The stopped converter branch must not be modified or resumed automatically.
- Production source truth and report routing remain TSV.
- Private access, conversion, reconstruction, source switching, writer changes, and cutover remain prohibited and blocked.
- Prerequisite implementation completion still requires explicit owner review before any converter work is selected again.
