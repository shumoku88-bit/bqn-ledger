# CBQN Reproducibility Policy

BQN Ledger is implemented in BQN and currently runs on CBQN.

This document records how the repository treats CBQN version drift.

## Current policy

- README declares the recommended CBQN baseline as commit `12a4fb9f` or later.
- GitHub Actions currently builds CBQN from the upstream repository during CI.
- CI should log the actual CBQN commit used for each run when possible.
- If upstream CBQN drift breaks this repository, pin CI to a known working commit and update README, CONTRIBUTING, and `docs/THIRD_PARTY_DEPENDENCIES.md` in the same PR.

## Why not hide this behind a generic version string?

CBQN is a fast-moving implementation dependency for this project. A normal package-manager version is not currently the whole story for this repository, because the expected build includes FFI + Singeli support.

Therefore, maintainer docs should keep the relationship explicit:

- what commit or range is expected,
- whether CI follows upstream head or a pinned commit,
- and which fixture/check suite proves compatibility.

## Maintainer rule

When changing the CBQN policy, make one small PR that includes:

1. CI behavior change, if any.
2. README requirement update.
3. CONTRIBUTING setup update.
4. This document update.
5. A `tools/check.sh` run result.

## Failure handling

If CI fails after an upstream CBQN change, first reproduce with the commit used by CI, then decide whether the correct fix is:

- update BQN Ledger for the new CBQN behavior,
- pin CBQN while investigating,
- or document a new minimum CBQN baseline.
