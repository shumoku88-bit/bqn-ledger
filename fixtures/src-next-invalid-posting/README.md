# src-next-invalid-posting

Small public fixture for `src_next` Posting IR scalar validation.

Purpose:
- Demonstrates that malformed scalar fields become rejected projection rows before cube materialization.
- `BAD-AMOUNT` uses a non-integer amount and must be reported as `invalid_amount`.
- `BAD-DATE` uses an invalid calendar date and must be reported as `invalid_date`.
- Valid rows still materialize normally, so skipped rows are diagnostic evidence, not silent zero-valued successes.

Classification note:
- This fixture protects the Quality Bar rule: fail closed, not pretty wrong.
