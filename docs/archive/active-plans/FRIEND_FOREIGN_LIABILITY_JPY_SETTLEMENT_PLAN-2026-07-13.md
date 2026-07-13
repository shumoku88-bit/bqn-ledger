# Friend foreign-liability → JPY-liability settlement

Status: rejected alternative
Owner: currency / travel settlement
Canonical: no; superseded by [FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md](FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md)
Exit: retained as historical rationale; do not use as current implementation authorization.

This note records a rejected alternative: record a foreign-currency friend liability/expense in the canonical journal, then close it and add JPY liability through two rows linked by `settlement_id` and currency-specific `clearing:*` accounts.

It is not selected for the travel friend-purchase consumer. It must not authorize a foreign-currency friend-liability account, a clearing account, `role=settlement_clearing`, a two-row settlement preview, account/schema changes, or writer work.

Use [FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md](FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md) for the current source-event → one-row JPY finalization design.
