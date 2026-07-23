# Unknown Account Failure Fixture

This fixture is used to verify that the linter and report engine's strict validation path fail cleanly when an undefined account is referenced in `actual.journal`.

Expected behavior:
- `lint_cli.bqn` exits with status `1` and outputs "Unknown account: to=expenses:nonexistent"
- `main.bqn` with strict check exits with status `1`.
