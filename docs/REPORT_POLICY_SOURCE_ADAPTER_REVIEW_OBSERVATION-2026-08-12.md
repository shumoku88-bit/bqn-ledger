# Report Policy Source Adapter review observation — 2026-08-12

## Scope

Review `src/application/report_policy_source_adapter.bqn` as the read-only application boundary for canonical `report.toml`.

## Observation

The production adapter already has one bounded responsibility:

```text
canonical Household base
  -> canonical Report-policy basename
  -> shared source_io path composition/read
  -> Report-policy admission
```

It does not own fallback discovery, configurable filenames, legacy manifest/config compatibility, Report query resolution, presentation behavior, accounting evidence, clocks, or writer authority.

There is no mutable traversal or convenience API to subtract. Changing production code would manufacture activity without clarifying meaning.

## Decision

Retain production `report_policy_source_adapter.bqn` unchanged.

Strengthen the existing source-I/O ownership check so the boundary is reconstructible and protected:

- the adapter must import `canonical_household_sources.bqn`;
- it must read `canonical.reportPolicy` through shared `source_io.JoinPath` / `ReadRaw`;
- it must not revive legacy Report manifest/config source names;
- its existing focused source-adapter test is run from the source-I/O ownership gate alongside the Household source-adapter law.

## Test and fixture classification

No new fixture is introduced.

`tests/test_application_report_policy_source.bqn` already loads the canonical Household fixture and proves admitted `report.toml` identity plus representative presentation/query values.

`checks/check-canonical-report-policy-cutover.sh` separately proves the complete Report path works from an eight-file-only canonical Household root with legacy Report manifest/config files absent.

`checks/check-source-io-ownership.sh` is the architecture law owner for fixed canonical basename/path composition and legacy-source non-reintroduction.

Together those cover semantics, integration topology, and ownership without duplicating a source fixture.

## Protected boundaries

Unchanged:

- canonical `report.toml` physical identity;
- canonical basename ownership;
- shared application source path composition;
- raw read then strict Report-policy admission;
- diagnostics and admitted policy shape;
- absence of legacy filename selection;
- absence of fallback discovery;
- writer authority.
