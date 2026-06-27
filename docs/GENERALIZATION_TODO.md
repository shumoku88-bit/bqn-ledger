# bqn-ledger: lifestyle configuration active remainder

Status: active remainder / compressed
Date: 2026-06-27

This document tracks the remaining design decisions for the lifestyle configuration (generalization) framework.

## Current active remainder

1. **Prefix fallback removal decision**:
   Condition: All account references in live ledger TSVs must explicitly declare `role=`. Use counts are detected in `src_next_household_metadata_prefix_fallback_total_count`. Removal parameters are defined in [docs/ACCOUNT_ROLE_CONTRACT.md](ACCOUNT_ROLE_CONTRACT.md).
2. **Configuration boundary policy**:
   Any configuration-externalization candidate must respect the [docs/SAFETY_PROFILE.md](SAFETY_PROFILE.md). Keep user configs simple; do not turn configuration into a DSL for arbitrary accounting computation.
3. **Canonical Daily Cube axis constraint**:
   Canonical Daily Cube shape and Layer contracts must not become user configuration. New coordinates or meanings should become separate projections/views rather than extra Daily Cube axes.

## Historical completed phase details

Detailed roadmaps and completed phases are archived in:
- [docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md](archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md)
