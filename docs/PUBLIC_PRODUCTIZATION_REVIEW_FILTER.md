# Public Productization Review Filter

Status: review filter / docs-only

This document records how to handle broad productization proposals such as CI/CD expansion, packaging, Homebrew, Docker, public OSS onboarding, plugin systems, marketing, and community operations.

The purpose is to keep useful ideas without letting broad OSS/product advice distort the current BQN Ledger design.

## Current position

BQN Ledger is public, but it is not optimized for broad consumer onboarding.

It is a maintained reference workbench for plain-text household accounting, deterministic BQN-derived reports, safe TSV write paths, and AI-assisted maintenance.

The main priority remains:

- protect real source TSV data outside the public repository
- preserve the BQN canonical engine
- keep report results deterministic
- improve checks, fixtures, docs, release discipline, and AI-assisted maintenance
- keep Go/Bash/UI helpers outside the canonical accounting meaning
- make the public sandbox and real `LEDGER_DATA_DIR` boundary obvious

## Adopt now

The following ideas are useful now because they strengthen the current public repository without changing its identity.

### 1. Keep the existing check path as the primary quality gate

Use existing repository checks as the primary quality gate.

Preferred first step:

```bash
tools/check.sh
```

Do not replace the current check path with unrelated coverage dashboards before the existing check path is stable and trusted.

### 2. Treat release and installation docs as boundary docs first

Release notes, tags, and installation notes are useful, but they should reinforce the existing boundary:

- public `data/` is sandbox data
- real data lives outside the repository
- `LEDGER_DATA_DIR` selects real data
- `tools/report`, `tools/bl`, `tools/doctor`, and `tools/check.sh` are current user-facing entry points

### 3. Consider Homebrew only after installable layout is clear

Homebrew can be useful later, but the first problem is not the Formula. The first problem is the installed command boundary.

Before a tap, define what an installed user runs:

```bash
bqn-ledger report
bqn-ledger check
bqn-ledger doctor
bqn-ledger init <dir>
```

A Homebrew formula should not make the Go editor appear to be the whole product if the canonical engine remains BQN plus source/config TSV.

### 4. Add shellcheck only as a staged check

`shellcheck` may be useful for Bash helper scripts, but it should be introduced carefully.

Recommended approach:

1. inventory current warnings
2. decide which warnings are meaningful for this repository
3. add suppressions or local conventions where needed
4. only then fail CI on selected warnings

Avoid large mechanical rewrites just to satisfy a generic shell style rule.

### 5. Strengthen fixture, exporter, and adapter documentation

Documenting fixture purpose, exporter contracts, expected-output update rules, and read-only adapter boundaries is high-value because it supports public review, human maintenance, and AI work.

## Park for later

The following ideas are not wrong, but they are not current priorities.

### Homebrew tap

A custom tap can wait until the installed layout and wrapper command are settled.

A good future sequence:

1. define `bqn-ledger` wrapper command
2. define install layout for BQN source, tools, fixtures, and sample config
3. define `doctor` behavior after installation
4. add tag/release checklist coverage
5. test a private or personal tap
6. publish the tap if the workflow is stable

### Binary releases and package managers

GitHub Releases, Homebrew, Apt packages, and prebuilt binaries can wait until there is a clear public-user installation path.

### Docker images

Docker may be useful for reproducible checks or public demos later. It should not make the project look like a hosted service or hide the source TSV model.

### Codecov or coverage badges

Coverage may be useful for Go code. It is less clearly useful for the BQN report engine unless it maps to actual invariant and fixture coverage.

Prefer invariant coverage and golden fixtures over generic coverage percentage.

### Public community operations

Issue templates, Code of Conduct, `good first issue`, public roadmap, and community marketing can wait until the repository is intentionally seeking outside contributors.

## Reject for current repository

The following directions conflict with the current project boundary unless a separate design decision changes that boundary.

### Plugin system inside canonical meaning

Do not add a dynamic plugin system for source TSV interpretation, account role mapping, cycle logic, budget semantics, Posting IR/TBDS/Cube construction, or layer meanings.

Use `docs/EXTENSION_BOUNDARY.md` instead: extensions should read canonical outputs, not alter canonical meaning.

### Web-app security architecture without a web app

TLS, CSRF, MFA, hosted authentication, and server-side monitoring are not current requirements for a local TSV and CLI-oriented tool.

Current security work should focus on:

- not committing real private data
- anonymized fixtures and sandbox public data
- source TSV write protection
- AI data-edit boundaries
- safe logs and public exports
- deterministic fail-closed behavior

### Marketing before stable public boundary

Blog posts, videos, demos, and discovery work should not drive architecture.

Public output can be created as downstream artifacts, but the canonical engine should not be reshaped for marketing first.

## Review checklist for future proposals

When a broad improvement proposal appears, classify each item:

```text
Adopt now: strengthens current core without changing meaning.
Park: useful later, but no immediate design pressure.
Reject now: conflicts with current source/canonical boundaries.
Separate repo: interesting experiment, but not this engine.
```

Ask these questions:

- Does this preserve the BQN-only canonical report path?
- Does it keep source TSV as source of truth?
- Does it avoid adding accounting meaning to Go, Bash, or UI helpers?
- Does it improve checks, fixtures, docs, release discipline, or AI safety?
- Does it clarify public sandbox vs real `LEDGER_DATA_DIR` data?
- Does it introduce public-product pressure before the project wants that?
- Can it live downstream of machine exports instead of inside the engine?

## Recommended next PRs

If this filter is accepted, useful next PRs are:

1. define an installable command/wrapper boundary before Homebrew
2. inventory shellcheck warnings without enforcing them yet
3. document exporter contracts that are safe for read-only adapters
4. add or verify CI coverage for `tools/check.sh`
5. update release checklist with any packaging prerequisites

These should remain small, separate PRs.
