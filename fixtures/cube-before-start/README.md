# Fixture: cube-before-start

Tests the behavior of the system when `as_of` is requested before the start of any transaction or plan history in the Canonical Daily Cube.

As of `2025-01-01` (a year before `fixtures/basic` starts):
The system should gracefully return zeroed snapshots and empty trends without indexing out of bounds.
