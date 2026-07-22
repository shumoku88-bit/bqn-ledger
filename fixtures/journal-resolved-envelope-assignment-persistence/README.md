# Journal resolved envelope assignment persistence fixture

Status: public synthetic test evidence
Owner: journal source migration
Canonical: no; selected plan is `docs/JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN.md`
Exit: archive with the completed characterization record

This fixture separates mutable entry defaults from durable accepted envelope effects.

- `defaults-v1.journal` maps the two food accounts to `daily` and household goods to `flex`.
- `defaults-v2.journal` changes all three expense defaults to `flex` for future entry resolution.
- `persisted-events.journal` contains two actual purchases and one balanced budget-layer companion linked to the first purchase by `actual-event-id`.

The first purchase resolves under V1 to:

```text
daily 2300
flex   500
```

Those exact values are persisted in the budget companion. Parsing the same persisted events with V2 declarations must not change that earlier budget event. A later purchase may resolve to `flex 2800` under V2.

Both event rows balance independently:

```text
actual purchase sum = 0
budget companion sum = 0
```

The budget event moves virtual envelope accounts only. It does not duplicate the bank payment or expense postings.

All names and amounts are synthetic. This fixture is not connected to production source loading, reports, the editor, private data, conversion, shadow read, or cutover.
