# Envelope & Backing accounting capability

Status: Portfolio P7A accounting composition; section surfaces and expanded scenario proof remain in progress.

`src/accounting/envelope_backing.bqn` composes strict Budget, Actual, and Plan Facts over explicit `[start,end_exclusive)`, observation, domain, and explicit funding Account indices.

Envelope ownership requires admitted `role=budget kind=envelope budget=...`; unassigned requires exactly one admitted `role=budget kind=unassigned`. Funding ownership is supplied explicitly and validated as selected-domain asset Accounts. Account names are never interpreted.

The result keeps entitlement, consumption, refunds, ledger remaining, open Plan reserve, and post-Plan headroom separate. It also keeps funding balance, signed envelope total, positive backing requirement, backing surplus, Budget unassigned, and reconciliation delta separate. Completion uses durable `plan_id` Join and rejects duplicate, ambiguous, currency-mismatched, or direction-mismatched evidence.

All arithmetic normalizes exactly to one scale and fails closed. Budget, Actual, Plan, funding, and unassigned contributors are source-qualified. Missing ownership is unavailable rather than numeric zero.

The strict public proof currently establishes entitlement `60`, consumption `30`, remaining `30`, completed Plan reserve `0`, funding `965`, backing requirement `30`, surplus `935`, unassigned `40`, and reconciliation delta `895`, plus missing/invalid funding behavior.

P7B must add synthetic open Plan, refund, overspent, under-backed, empty Plan, conflict/overflow proofs and the retained human/compact/JSON section before this portfolio item is complete.
