# AI-Assisted Adoption Guide

Status: current operational guide / docs-only
Owner: onboarding / workflow / safety
Canonical: no; current contracts remain `README.md`, `AGENTS.md`, `docs/DATA_DIR_SETUP.md`, `docs/BQN_EDITOR_USAGE.md`, and `docs/SAFETY_PROFILE.md`
Exit: replace when a tested setup command or wizard provides the same review, privacy, and fail-closed boundaries

This guide is for someone who has cloned `bqn-ledger` and wants their own terminal AI coding assistant to help adapt it to their household.

The goal is not one-click automation. The goal is a small, reviewable path from a public clone to a private usable ledger, while keeping the human-readable TSV files as source truth and keeping the human in control of writes.

## Prompt to give your AI

From the repository root, start your coding assistant and say:

```text
Read README.md, AGENTS.md, and docs/AI_ASSISTED_ADOPTION_GUIDE.md.
Help me evaluate and set up bqn-ledger for my household.
Start read-only. Ask questions instead of guessing.
Do not edit source TSV, create real household data, or commit private information
until you have shown me a setup plan and I have explicitly approved it.
```

The assistant may translate or explain the documentation in the user's language, but it must not silently change the accounting meaning.

## Ground rules

1. **Start read-only.** Inspect the repository, demo fixture, current commands, and current contracts before proposing writes.
2. **Keep real data outside the public repository.** Use a separate base directory selected with `LEDGER_DATA_DIR`; the repository `data/` directory is a public sandbox.
3. **Do not infer personal facts.** Country or nationality does not determine currency, timezone, date preference, income cycle, account structure, or budgeting method.
4. **Do not invent accounting meaning.** Ask before creating account names, roles, currencies, opening balances, cycle boundaries, classifications, or policies.
5. **Do not publish private evidence.** Never commit or paste private names, amounts, account identifiers, secrets, or real data paths into a public branch, issue, PR, fixture, or log.
6. **Use existing safe write paths.** After setup, ordinary writes should go through the documented BQN editor or UI preview/confirmation flow.
7. **Separate setup from product development.** A missing user requirement may need a small repository change, but it does not authorize a generic framework or broad rewrite.

## Adoption workflow

### 1. Read the current path

At minimum, the assistant should read:

```text
README.md
AGENTS.md
docs/AI_ASSISTED_ADOPTION_GUIDE.md
docs/DATA_DIR_SETUP.md
docs/CONVENTIONS.md
docs/BQN_EDITOR_USAGE.md
docs/SAFETY_PROFILE.md
```

Historical and archived plans may explain past decisions, but they are not current instructions unless the current docs route to them.

### 2. Verify the public clone before using private data

Use only the public demo and sandbox:

```sh
tools/report fixtures/demo --section snapshot
tools/report fixtures/demo --list-sections
tools/check.sh
```

The assistant should report missing dependencies or failed checks before attempting household setup. It should not hide failures by editing fixtures or expected output.

### 3. Interview the user without guessing

Ask only the questions needed for a minimal first ledger. Typical topics are:

- preferred explanation language;
- timezone and date conventions;
- source currency or currencies and required decimal precision;
- first reporting date and life/accounting cycle boundaries;
- accounts and payment methods the user actually wants to track;
- whether cash, cards, liabilities, or third-party payments are needed;
- whether plan, budget, envelope, or issue tracking should be enabled now or deferred;
- where private data and backups will live.

Do not assume that all features must be enabled on day one.

### 4. Classify every requirement

Before changing anything, produce a short table that classifies each requirement as one of:

```text
A. supported by current private TSV/configuration
B. supported by current code but needs user-specific setup
C. requires a small code-and-test change
D. unsupported or broad enough to require a separate design decision
E. unclear; ask the user
```

For category C, explain the current semantic owner, intended files, focused tests, and non-goals before editing. For category D, stop instead of improvising a large feature.

Supported currencies are defined in the repository-wide `config/currencies.tsv` registry (e.g. JPY, ILS, and USD are supported). You can add a new single currency to the registry to enable exact decimal journal/plan/budget entries. FX, market rates, valuation, and cross-currency totals are out of scope and unsupported.

### 5. Prepare a private setup draft

Create or prepare a base directory outside the repository, following `docs/DATA_DIR_SETUP.md`.

A minimal usable base contains:

```text
accounts.tsv
journal.tsv
cycle.tsv
```

Daily use commonly also needs:

```text
plan.tsv
budget_alloc.tsv
config.tsv
```

Create only what the user has chosen to use. Preserve the documented TSV shapes and metadata contracts. Prefer an empty, valid journal over fabricated transactions.

Before applying the draft, show the user:

- the proposed private directory location;
- the files to be created or changed;
- the account roles and currencies, without publishing private values;
- the cycle boundaries;
- any deferred or unsupported requirements;
- whether repository code changes are needed.

### 6. Validate before ordinary writes

After the user approves the private draft, verify the selected base directory:

```sh
export LEDGER_DATA_DIR=/absolute/path/to/ledger-data/data
tools/doctor
tools/report --section snapshot
tools/add-ui.sh --check
```

A setup is not complete merely because files exist. The effective base directory must be visible, required TSV files must be recognized, and the report/input preflight must succeed or fail with a clear diagnostic.

Do not copy private command output into a public PR. Summarize only the pass/fail result and privacy-safe diagnostics.

### 7. Hand off to daily use

After validation, summarize:

- the effective base directory;
- enabled features and intentionally deferred features;
- supported currencies and cycle semantics;
- the normal report command;
- the normal editor/UI command;
- backup expectations;
- the rule that AI remains read-only by default.

Ordinary additions should use `tools/edit`, `tools/edit-bqn`, or the documented UI. Large corrections and deletions should remain visible to the human reviewing the source TSV.

## When a small repository adaptation is needed

Keep it separate from private setup:

```text
private household setup
  !=
public repository code change
```

For a public code change:

- create a narrow branch and PR;
- use synthetic fixtures and public-safe examples only;
- preserve the existing semantic owner instead of duplicating policy;
- add or update focused tests;
- run the normal full checks;
- state explicit non-goals;
- do not commit the user's private TSV or real values;
- stop after the requested adaptation instead of automatically generalizing adjacent features.

The desired outcome is not that every household uses an identical setup. The desired outcome is that another person's AI can identify the smallest safe difference between the current ledger and that person's needs.

## Adoption completion checklist

- [ ] The public demo runs or any dependency failure is clearly explained.
- [ ] The user's requirements were asked, not inferred from nationality or locale.
- [ ] Every requirement was classified before edits.
- [ ] Real source data lives outside the public repository.
- [ ] No private data was committed, published, or copied into fixtures.
- [ ] The private base directory passes `tools/doctor` and report/input preflight.
- [ ] Unsupported needs are recorded without pretending they work.
- [ ] The user reviewed the setup summary and explicitly accepted it.
- [ ] Daily writes use the documented safe editor/UI path.
- [ ] AI returns to read-only-by-default behavior after setup.

## Non-goals of this guide

- no setup wizard or setup-state marker;
- no automatic editing of source TSV;
- no bank synchronization or cloud service;
- no automatic currency conversion, FX, valuation, or market-rate lookup;
- no promise that every country or currency works without a code change;
- no translation campaign for every document;
- no generic plugin, dataframe, query, or agent framework;
- no change to the Canonical Daily Cube, Posting IR, source TSV schemas, or runtime behavior.
