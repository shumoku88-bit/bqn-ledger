# Third-Party Dependencies

Status: current dependency inventory
Owner: maintenance
Canonical: yes
Exit: revise when runtime or development dependencies change

This document is a lightweight inventory of external tools and libraries used by BQN Ledger.

It is not a full SBOM. It exists so maintainers and reviewers can see the main runtime and development assumptions in one place.

## Runtime and development tools

| Dependency | Used for | Notes |
|---|---|---|
| CBQN | Running BQN report engine, tests, and checks | README currently recommends commit `12a4fb9f` or later. CI reproducibility should keep this relationship explicit. |
| Bash | Shell wrappers and check scripts | Used by `tools/`, `checks/`, and GitHub Actions. |
| ripgrep | Repository checks | Installed in CI for check tooling. |
| fzf | Optional interactive UI | Presentation/selection helper only. |
| gum | Optional interactive UI | Presentation/selection helper only. |
| Node.js | Optional MCP adapter runtime and tests | Termux-compatible; not required by the canonical BQN report/editor path. |
| `@modelcontextprotocol/sdk` | Optional Streamable HTTP MCP protocol | npm lockfile-pinned transitive graph under `mcp-server/`; legacy SSE is not used. |
| Express / Zod | Optional MCP HTTP boundary and input schema | npm lockfile-pinned; request parsing remains bounded and core tests are transport-independent. |

## Legacy / archived implementation notes

All Go source code has been completely retired and removed from the active tree. Legacy/historical design records and planning documents are kept in `docs/archive/` for background reference only. No active workflows or tools require Go.

## Reproducibility notes

- The public repo should keep runtime requirements in README, CONTRIBUTING, and CI aligned.
- If CBQN is pinned in CI, update README at the same time.
- Removed or archived experiments should not be listed as current dependency paths.
- MCP dependencies are installed reproducibly with `npm ci --prefix mcp-server`; `npm audit --omit=dev` is part of dependency review.

## Data safety note

Dependencies should be evaluated with the assumption that real household data lives outside this repository. Public examples, issues, and tests should use sandbox or fixture data only.
