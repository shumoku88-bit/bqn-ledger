# Date Today review observation — 2026-08-12

## Owner

`src/application/date_today.bqn`

## Decision

Retain the production owner unchanged.

The module has one responsibility: observe the operating-system local date at the Application boundary and publish `YYYY-MM-DD` text. It owns no date arithmetic, policy, Report selection, cache behavior, or source admission.

The direct law now proves that `Today` returns ten-character strict Gregorian text accepted by the Ledger date owner.

Current Report determinism remains separately owned by the Profile adapter: explicit `LATEST` input bypasses the ambient clock for qualification and replay. The clock owner therefore stays intentionally small rather than acquiring override or policy behavior.

No generic clock abstraction is introduced. The current process boundary is the clearest retained shape for the one ambient-date capability.
