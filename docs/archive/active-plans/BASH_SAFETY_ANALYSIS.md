# Bash Safety & Crash Prevention Analysis

- Status: implemented first pass (Option 1 + guardrail)
- Date: 2026-06-29
- Context: A crash occurred in `tools/add-ui.sh` at line 459 where the `local` keyword was used outside a function, causing a runtime failure. This occurred because `bash -n` only checks syntax, and CLI smoke checks did not reach the specific `plan-edit`/`plan-finish` code paths.

## Implemented first pass (2026-06-29)

- `tools/add-ui.sh` top-level runtime flow is now wrapped in `main()`, so helper-path `local` declarations execute inside function scope.
- Added `checks/check-bash-safety.sh` as a dedicated lightweight Bash safety check, wired into `tools/check.sh`.
- The check runs `bash -n` for shell entrypoints and guards against top-level `local` without adding a new external `shellcheck` dependency.

## Proposed Options

### Option 1: Encapsulate script in a `main()` function
* **Implementation**: Move all top-level runtime code into a `main()` function and call `main "$@"` at the bottom of the script.
* **Pros**:
  * Eliminates the root cause: `local` is always valid within `main` and its helper paths.
  * Zero external tool dependencies (retains BQN/Go/Bash minimal tooling constraint).
  * Cleans up the script's global namespace variables.
* **Cons**:
  * Requires restructuring the bottom half of `add-ui.sh`.
* **Estimation**: Low cost (30 mins of refactoring).

### Option 2: Introduce `shellcheck` linter
* **Implementation**: Add `shellcheck tools/add-ui.sh` to `check.sh` and CI workflows.
* **Pros**:
  * Automatically catches syntax/semantic issues like SC2168 (`local` invalid outside function) and other common bash pitfalls.
* **Cons**:
  * Adds `shellcheck` as a required CLI tool in local development environment and CI runner.
* **Estimation**: Low implementation cost, but increases tooling dependency surface.

### Option 3: Implement comprehensive mode smoke tests
* **Implementation**: Update `check-ui-smoke.sh` to run `add-ui.sh` in dry-run/mock modes for every available command/action, confirming the script initializes and parses arguments without crashing.
* **Pros**:
  * Validates run-time execution paths without introducing new tools.
* **Cons**:
  * Can be tricky to implement for interactive paths (may require mocking `gum` and `fzf` behavior or piping inputs).
* **Estimation**: Medium cost.
