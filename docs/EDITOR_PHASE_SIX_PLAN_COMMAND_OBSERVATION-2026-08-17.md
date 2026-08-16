# Editor Phase 6 canonical Plan command observation — 2026-08-17

## Status

The normal Phase 6 review has covered the canonical Plan command family:

- `src_edit/plan_add_cmd.bqn`
- `src_edit/plan_edit_cmd.bqn`
- `src_edit/plan_finish_cmd.bqn`
- `src_edit/plan_finish_validate_cmd.bqn`
- `src_edit/plan_id.bqn`
- `src_edit/plan_list_cmd.bqn`
- `src_edit/plan_related_cmd.bqn`
- `src_edit/plan_validate_cmd.bqn`

The family remains split by responsibility rather than collapsed into a generic Plan command framework:

```text
Add       -> construct + re-admit one append candidate
Edit      -> source-coordinate rewrite + re-admit whole candidate
Finish    -> observe one open Plan + emit Actual completion intent
List      -> read-only projected Plan rows
Related   -> read-only relation key + future related rows
Validate  -> strict canonical Plan admission leaf
Finish Validate -> strict published completion-link leaf
Plan ID   -> current ID format + generation only
```

## Plan Add

Plan Add already had the correct semantic boundaries:

- canonical Account admission;
- Account-owned Commodity implication;
- registry-owned currency policy;
- canonical Plan root topology;
- strict existing Plan admission;
- Actual completion evidence in the Plan-ID identity universe;
- whole proposed source re-admission before publication;
- exact candidate intent comparison.

The procedural residue was concentrated in construction.

### Currency inference

The selected Account pair yields zero, one, or multiple known Commodity values. An omitted explicit currency is valid only when the unique known Commodity relation contains exactly one value.

The reviewed form derives the final currency through that guarded coordinate instead of mutating an initially copied explicit value.

The same mismatch checks remain:

```text
from Account Commodity = selected currency
to Account Commodity   = selected currency
selected currency      = admitted registry policy
```

### Metadata relation

Metadata tokens are mapped independently into canonical key/value records.

Alias normalization remains local to Plan Add and preserves the established underscore-to-native-key compatibility, for example:

```text
due_on -> due-on
txn_id -> txn-id
execution_envelope -> execution-envelope
reservation_amount -> reservation-amount
```

The review removes the mutable metadata accumulator but retains:

- exactly one `=` per token;
- `plan-id` prohibition through metadata;
- allowed canonical metadata vocabulary;
- uniqueness after key normalization;
- separate no-currency-metadata validation.

No generic metadata framework is introduced.

### Plan identity

The existing identity universe remains:

```text
current admitted Plan IDs
+
Plan IDs observed in Actual completion evidence
```

An explicit Plan ID is validated and checked for collision. An omitted ID uses `plan_id.GeneratePlanID` against that same universe.

The reviewed form chooses between those two paths directly rather than assigning through a mutable final-ID sentinel.

### Block and source-ending construction

Header, Plan identity metadata, caller metadata, and two Posting lines are one ordered line relation. The block is joined from that relation rather than grown line by line.

The established source-ending transport law remains:

- preserve an existing blank separator when the source already ends with two LF characters;
- otherwise add the required separator before the new block;
- always end the proposed source with LF.

The whole resulting source is still re-admitted through canonical root and Plan admission before the shell writer receives an append payload.

## Plan ID owner

`src_edit/plan_id.bqn` retains the current responsibilities that have live consumers:

- slug normalization;
- `plan-YYYY-MM-DD-series` validation;
- deterministic generated identity;
- collision suffix generation.

Two old helpers were no longer reachable outside the module:

```text
ExtractPlanId
LoadExistingPlanIDs
```

They parsed Plan IDs from TSV-shaped lines and optional legacy paths. Current Plan Add obtains identities from admitted canonical Plan transactions and Actual completion evidence instead.

Those dead TSV readers are removed rather than kept as a compatibility shell beside the canonical Journal path.

The `source_io` import remains because current Plan-ID format validation still uses the shared split primitive. The whole module is therefore not legacy residue.

## Plan Edit

Plan Edit retains its strongest law: physical rewrite coordinates come only from strict admitted Plan evidence.

The review does not replace this with a generic text editor or re-discover source structure from raw text.

### Visible Plan coordinate

The admitted transaction index relation is filtered by Actual completion evidence to produce open Plan coordinates. `--all` chooses the full admitted coordinate relation; otherwise only open coordinates are visible.

Index selection and Plan-ID selection are now two explicit branches over that relation rather than mutation of a `selectedIndex` sentinel.

No generic Plan selector owner is introduced because Edit and Finish have different visibility and failure semantics.

### Date coordinate

An optional date edit validates only when supplied. The target date then derives directly from:

```text
provided date ? new date : admitted current date
```

This removes mutable target-date staging without eager validation of an absent input.

### Guarded amount staging retained

The amount-edit path deliberately keeps local guarded staging for `parsedAmount` and `amountChanged`.

That mutation protects a real evaluation boundary:

- absent amount must not be parsed;
- amount override requires exactly two Postings;
- currency-specific exact validation must run before comparison;
- positive amount validation precedes exact old/new magnitude comparison.

Making those values unconditional merely to remove mutation would weaken the visibility of that failure order.

### Source-coordinate rewrite retained

The following laws remain unchanged:

- CR source normalization is refused;
- header coordinate must be inside the admitted source;
- admitted header date must match the physical source coordinate;
- amount replacement uses admitted Posting source lines and admitted Account order;
- only the selected header date and/or two Posting lines may change;
- the candidate root topology is re-admitted;
- the entire candidate Plan is re-admitted;
- transaction count is unchanged;
- Plan identities and ordering are unchanged;
- selected metadata keys and values are unchanged;
- selected source start/end coordinates are unchanged after the same-shape rewrite.

`JoinLines` is relation-driven, but the writer provenance law is not compressed away.

## Plan Finish

Plan Finish does not rewrite Plan source. It observes one open Plan and emits an Actual completion intent carrying the Plan identity.

Open coordinates still derive from canonical Plan admission minus Plan IDs already observed in Actual completion evidence.

Index-vs-ID selection is now explicit rather than staged through a mutable sentinel. The two selection laws remain local:

```text
positive index -> open Plan relation in source order
Plan ID        -> exactly one open admitted Plan
```

The rest of the completion intent remains unchanged:

- actual date validation;
- Plan Posting order and exact text preservation without an override;
- amount override only for exactly two Postings;
- exact currency-specific positive override validation;
- emitted Posting tokens preserve selected Account order and signs;
- Plan source is observation only;
- shell publication remains Actual-owned;
- existing Plan observation race fence and post-publication rollback remain outside this semantic leaf.

## Plan List

Plan List already consumes `src/application/editor_plan_rows.bqn`, so Plan/Actual admission and closed-state derivation remain application-owned.

The stable TSV contract remains nine fields:

```text
number plan_id date memo from to amount status display
```

The row projection already carries `currency`, but the human display previously omitted it. Under multi-currency admission that rendered a bare amount such as `50000` with no Commodity identity.

Only the human display now retains the admitted Commodity, for example:

```text
50000 JPY
```

No extra TSV field and no selector-owned currency lookup are introduced.

Temporal filtering remains a relation over open projected rows and the existing Plan temporal-status owner.

## Plan Related

`src_edit/plan_related_cmd.bqn` is production-unchanged after law review.

Its relation order remains:

1. canonical `series` metadata;
2. series parsed from a valid legacy-shaped Plan ID;
3. exact description/from/to/amount relation key.

This fallback is still live behavior, not the dead TSV source reader removed from `plan_id.bqn`.

The command already uses projected canonical Plan rows, a direct selected-row branch, a future-date mask, and a relation filter. Its inheritable metadata vocabulary remains deliberately narrower than all Plan metadata.

No concrete correctness or architectural defect justifies a generic relation-key framework in this pass.

## Plan completion validator

`src_edit/plan_finish_validate_cmd.bqn` is production-unchanged.

It validates one published completion link by requiring:

- exactly one admitted Plan identity;
- exactly one Actual completion evidence row for that identity;
- exact completion date equality.

It does not own Plan selection, Actual writer publication, or general Journal validation.

## Plan Journal validator

`src_edit/plan_validate_cmd.bqn` is production-unchanged.

Its responsibility remains one strict post-write admission of canonical `plan.journal`, publishing either the first admitted diagnostic or the canonical Plan basename and transaction count.

It is an appropriate narrow validation leaf and does not need to absorb Add/Edit candidate comparison laws.

## No new generic selector or writer framework

Edit and Finish now expose similar index-vs-ID shapes, but their semantic universes differ:

```text
Edit   -> open Plans by default, all admitted Plans only when explicitly requested,
          then refuses mutation of a closed Plan
Finish -> open Plans only
```

Their effects also differ: Edit prepares a Plan source rewrite while Finish prepares an Actual completion intent.

A shared selector abstraction at this point would save little code while hiding the different laws. The review therefore leaves selection owner-local.

## Qualification evidence

The existing Plan checks already cover the critical boundaries:

- generated and collision-suffixed Plan IDs;
- explicit Plan IDs;
- metadata alias normalization;
- no-final-newline append;
- Account/Currency mismatch rejection;
- candidate/post-write validation and rollback;
- exact-byte date-only Plan edits;
- admitted-coordinate amount edits;
- multi-Posting date edit versus binary-only amount edit;
- closed Plan and invalid selector rejection;
- Plan Finish Actual-only publication;
- Posting order/sign preservation;
- multi-Posting completion without override;
- duplicate completion rejection;
- Plan observation race fencing;
- read-only Plan List and stable nine-column TSV shape.

This review adds the commodity-display assertion while retaining those existing law guards.

## Decision

The Plan command family now has a clearer shape without merging responsibilities:

```text
canonical relations
  -> owner-local selection / construction
  -> explicit candidate or completion intent
  -> existing independent admission/publication guards
```

The normal Phase 6 cursor can advance to:

```text
src_edit/render.bqn
```
