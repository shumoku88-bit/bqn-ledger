---
name: Feature request
about: Propose a small scoped improvement
title: "feature: "
labels: ""
assignees: ""
---

## Goal

What problem should this solve?

## Scope

What should change?

## Non-goals

What should explicitly not change?

## Safety / data boundary

Confirm any source TSV write behavior. Most changes should avoid real source TSV edits and use fixtures or approved editor paths.

## Acceptance checks

```bash
bash tools/check.sh
```

Add any smaller checks or manual checks that prove the change.
