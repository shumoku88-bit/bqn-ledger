# Next session

Status: no finite slice selected
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: select the next finite slice from `TODO.md` before starting work

## Current state

The Journal resolved envelope assignment persistence characterization is completed.

Completed record:

`docs/archive/completed-plans/JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN-2026-07-22.md`

## Result

- account metadata supplies entry-time default envelope proposals;
- the accepted assignment is persisted as a distinct balanced budget-layer companion event;
- the companion links to one durable actual event through `actual-event-id`;
- Defaults V1 resolve the selected purchase to `daily 2300 / flex 500`;
- Defaults V2 resolve a new purchase to `flex 2800`;
- the persisted V1 companion remains `daily 2300 / flex 500` under V2;
- actual and budget events each balance independently;
- missing, unknown, duplicate, and unbalanced evidence fails visibly;
- GitHub Actions check run #1122 succeeded.

## Production boundary

Production Journal routing, writer/editor work, envelope/report runtime migration, private data, source conversion, shadow read, cutover, reverse synchronization, per-posting layers, correction-event policy, and Cube/TBDS shape changes remain unselected.

No later Journal slice is selected automatically.
