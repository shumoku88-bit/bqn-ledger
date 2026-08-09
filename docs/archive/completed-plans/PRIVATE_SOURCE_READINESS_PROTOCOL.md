# Private source readiness protocol

Status: Phase 0C safety contract; no private audit performed
Owner: ledger-facts source migration
Public audit: `docs/PUBLIC_SOURCE_READINESS_AUDIT.md`

## Boundary

Canonical household data belongs to moko. A pit does not discover, inspect, summarize, copy, or modify a private base merely because public fixture migration is authorized.

The strict-source requirements are approved, but that approval is not permission to read or change private data.

## Readonly audit procedure

Run a private audit only after moko explicitly identifies or authorizes the base for that action.

1. Confirm the exact base path and that the requested action is readonly.
2. Run the audit against that explicit path; do not rely on `LEDGER_DATA_DIR`, `data/`, or system defaults.
3. Use:

   ```bash
   python3 tools/characterization/report_source_readiness_audit.py /explicit/private/base --summary
   ```

4. Keep detailed row/path output local unless moko explicitly requests it.
5. Report only the minimum useful aggregate readiness findings in conversation.
6. Do not add private paths, account names, memos, amounts, source hashes, or audit output to Git.
7. Do not repair data during the audit.

The current audit reads config/account/Plan/Budget shape and Actual layout only. It does not need transaction content to count strict-source metadata readiness.

## Approved coordinates to inspect

- explicit supported `DEFAULT_CURRENCY`;
- explicit currency on arithmetic accounts;
- explicit currency on Plan/Budget rows;
- durable `plan_id=` where Plan relationships are used;
- missing account role as unclassified evidence;
- one configured safe Actual basename directly under the base;
- explicit domain/source policy for an empty source.

Whether a particular Plan row participates in a durable relationship may require a later purpose-built readonly relation audit. Do not infer that solely from the aggregate metadata counter.

## Migration is a separate authorization

After a readonly audit, any private write requires a new explicit instruction and a migration plan containing:

- exact files and transformations;
- preview/diff with private values kept local;
- backup or reversible copy;
- pre-write hashes or equivalent stale checks;
- exclusive/atomic write where practical;
- strict parser/admission validation after writing;
- report/check validation;
- rollback steps;
- no fallback added to production runtime if migration fails.

A migration must stop if the source changed after preview. One approval does not authorize unrelated future migrations.

## Publication rule

Public synthetic fixtures and aggregate, non-identifying engineering conclusions are the repository evidence. Private household rows and generated reports never become public fixtures, golden files, documentation examples, commits, or issue text.
