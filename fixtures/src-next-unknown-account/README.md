# src-next-unknown-account

Small public fixture for `src_next` comparison analysis.

Purpose:
- Demonstrates `src_next` valid/skipped projection partition evidence for an unknown account row.
- The current engine is expected to fail closed on the same source data.

Classification note:
- Treat the helper difference as an **expected design difference** for the read-only prototype comparison surface.
- If `src_next` were considered for production replacement, this would become a **regression candidate** unless a production fail-closed contract were added.
