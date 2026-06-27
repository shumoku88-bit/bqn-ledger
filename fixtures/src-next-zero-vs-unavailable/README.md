# Zero vs Unavailable Failure Fixture

Tests that missing baseline data shows "unavailable" not 0.

Key case: Actual Comparison with no previous cycle data (first cycle ever).
Expected: `status: unavailable`, not silently comparing against zero.
