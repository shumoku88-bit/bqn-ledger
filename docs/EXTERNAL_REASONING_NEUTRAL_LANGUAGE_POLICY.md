# External Reasoning Neutral Language Policy

Status: active wording policy / overrides wording drift in external reasoning consultation docs
Date: 2026-06-22

This note records a wording decision for external reasoning and household-accounting consultation output.

## Core decision

External reasoning consultation should avoid meaning-heavy framing.

In particular, spending review should not frame observations as:

```text
warning
risk
bad spending
mistake
must cut
moral judgment
```

Instead, it should use neutral observation language:

```text
pace
rhythm
timing
margin
room
review candidate
confirmation candidate
observed change
```

## Why

The consultation layer is for observing the rhythm of spending, not for judging it.

For example:

```text
plan.tsv spending = known / already noticed spending
unplanned actual spending = living rhythm that emerged during the cycle
```

Unplanned spending is not automatically bad. It is a useful pace signal.

## Preferred rewrites

Use these replacements when reviewing or editing `docs/EXTERNAL_REASONING_BOUNDARY.md` or future consultation output:

```text
risk_review              -> margin_review
risk_note                -> margin_note
warnings                 -> data_notes
attention candidate      -> review candidate / confirmation candidate
suspicious delta         -> changed delta / large delta
end_cycle_scarcity       -> end_cycle_narrow_room
food shortage risk       -> food room became small
should be watched        -> appeared / was observed
```

## Consultation output rule

A consultant may say:

```text
food spending pace was faster in the first part of the cycle
weekend food spending increased
end-cycle remaining food room narrowed
tobacco pace changed around a date range
```

It should not say:

```text
food spending is bad
this must be cut
this is a warning
this is a risk
```

## Existing BQN statuses

If BQN output uses status names such as `WARN` or `UNAVAILABLE`, the consultant may quote them as source data.

But the consultant should not turn those statuses into lifestyle judgment.

## Relationship to `docs/EXTERNAL_REASONING_BOUNDARY.md`

This policy overrides any older wording in `docs/EXTERNAL_REASONING_BOUNDARY.md` that uses warning/risk/attention framing.

A later cleanup pass may rewrite that document directly. Until then, use this note as the wording authority for consultation language.
