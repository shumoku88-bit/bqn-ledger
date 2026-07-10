# Prefix Fallback Product-Selection Removal Plan

Status: completed
Owner: envelope
Canonical: no; semantic decision: `../audits/PREFIX_FALLBACK_CURRENT_MAIN_RECONCILIATION-2026-07-11.md`
Exit: completed and retired after PR #151 plus post-implementation verification

Date: 2026-07-11
Implementation PR: #151
Merge commit: `1a992628ba6bdd6a8bc86fc9a382f4d973e55071`
Verification: `../audits/PREFIX_FALLBACK_PRODUCT_SELECTION_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md`

## Original selected meaning

```text
explicit role metadata = classification owner
prefix-shaped missing role = diagnostic signal only
prefix fallback != product/accounting/envelope selection authority
```

## Authorized finite slice

The plan authorized one narrow runtime safety slice:

- make envelope expense eligibility explicit `role=expense` only;
- make envelope budget eligibility explicit `role=budget` only;
- make household-policy classified expense counts explicit-role-owned;
- preserve prefix-shaped missing-role observation as diagnostic evidence;
- correct stale fallback commentary;
- add focused negative evidence for both expense and budget product-selection paths;
- avoid broad envelope refactoring and avoid Currency Stage 2 B2 changes.

## Completion result

PR #151 implemented the selected slice.

Post-implementation verification status:

```text
verified
```

The merged result proves that missing-role `expenses:` / `budget:` candidates remain visible diagnostically but do not enter the touched product-selection paths solely by prefix shape.

No material unresolved plan/runtime mismatch was found.

## Current routing

This completed plan is historical evidence, not current implementation authority.

Current finite routing returns to:

```text
Currency Stage 2 Slice B2: Snapshot Arithmetic Evidence
```

Use `TODO.md` and `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md` for current work.
