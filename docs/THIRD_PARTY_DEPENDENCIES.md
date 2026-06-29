# Third-Party Dependencies

This document is a lightweight inventory of external tools and libraries used by BQN Ledger.

It is not a full SBOM. It exists so maintainers and reviewers can see the main runtime and development assumptions in one place.

## Runtime and development tools

| Dependency | Used for | Notes |
|---|---|---|
| CBQN | Running BQN report engine, tests, and checks | README currently recommends commit `12a4fb9f` or later. CI reproducibility should keep this relationship explicit. |
| Bash | Shell wrappers and check scripts | Used by `tools/`, `checks/`, and GitHub Actions. |
| ripgrep | Repository checks | Installed in CI for check tooling. |
| Go | Legacy preview-helper safety check | Not part of the active daily editor path; used to keep `tools/legacy/finish-preview.go` preview-only until removal/archive. |
| fzf | Optional interactive UI | Presentation/selection helper only. |
| gum | Optional interactive UI | Presentation/selection helper only. |

## Legacy / archived implementation notes

Any remaining Go source in the repository is historical support code only and is not the active editor implementation. Go may still be required by checks that prove legacy helpers remain preview-only; it should not be treated as the current daily write path.

## Reproducibility notes

- The public repo should keep runtime requirements in README, CONTRIBUTING, and CI aligned.
- If CBQN is pinned in CI, update README at the same time.
- Removed or archived experiments should not be listed as current dependency paths.

## Data safety note

Dependencies should be evaluated with the assumption that real household data lives outside this repository. Public examples, issues, and tests should use sandbox or fixture data only.
