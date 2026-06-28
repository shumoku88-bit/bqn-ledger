# Third-Party Dependencies

This document is a lightweight inventory of external tools and libraries used by BQN Ledger.

It is not a full SBOM. It exists so maintainers and reviewers can see the main runtime and development assumptions in one place.

## Runtime and development tools

| Dependency | Used for | Notes |
|---|---|---|
| CBQN | Running BQN report engine, tests, and checks | README currently recommends commit `12a4fb9f` or later. CI reproducibility should keep this relationship explicit. |
| Go | Building and testing the TSV editor | README and CI use Go 1.22+. |
| Bash | Shell wrappers and check scripts | Used by `tools/`, `checks/`, and GitHub Actions. |
| ripgrep | Repository checks | Installed in CI for check tooling. |
| fzf | Optional interactive UI | Presentation/selection helper only. |
| gum | Optional interactive UI | Presentation/selection helper only. |

## Go module dependencies

Go dependencies are declared in module-local `go.mod` files.

Known modules:

- `editor/go.mod`: Go editor and tests.
- `tui/go.mod`: frozen TUI experiment, not part of the current daily path unless explicitly revived.

## Reproducibility notes

- The public repo should keep runtime requirements in README, CONTRIBUTING, and CI aligned.
- If CBQN is pinned in CI, update README at the same time.
- If the frozen TUI remains in the repository, its status should stay explicit so it does not look like an unsupported production path.

## Data safety note

Dependencies should be evaluated with the assumption that real household data lives outside this repository. Public examples, issues, and tests should use sandbox or fixture data only.
