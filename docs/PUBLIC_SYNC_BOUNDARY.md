# Public Sync Boundary

Status: proposed contract for the future public repository.

## Purpose

`shumoku88-bit/bqn-ledger` is the private canonical repository. A separate public repository will be generated from it through an allowlist-based synchronization process.

This document defines the boundary before any synchronization code is introduced. Until this contract is approved, no automated private-to-public sync should run.

The public repository is a publication surface, not a second source of truth. Changes flow from private canonical to public. Public contributions may be reviewed and manually re-applied to the private canonical repository, but the synchronization process must never pull public state directly into the private source tree.

## Safety model

The synchronization model is deny-by-default and fail-closed.

A path is publishable only when all of the following are true:

1. it matches the public allowlist;
2. it does not match an exclusion rule;
3. it passes the pre-sync audit;
4. its generated public tree contains only approved fixture and sandbox data.

An omitted path is private. A new path is private until explicitly added to the allowlist in a reviewed change.

The first public repository should be created from a clean exported tree rather than by changing the visibility of the private canonical repository. Private Git history must not be copied by default.

## Public allowlist

The initial public export may include only these path classes:

- top-level project metadata explicitly reviewed for publication: `README.md`, `LICENSE*`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `.editorconfig`, `.gitignore`;
- runtime source: `src_next/**` and other source directories that are individually approved before the first sync;
- command wrappers and checks: `tools/**`, excluding machine-local, credential-bearing, destructive, or private-data migration helpers;
- public configuration templates: `config/**`, only when values are generic defaults or placeholders;
- public documentation: `docs/**`, excluding archived personal notes, operational diaries, private trial logs, unpublished plans, and any document rejected by audit;
- synthetic examples and approved fixtures under the dedicated public fixture paths defined below;
- CI and repository metadata under `.github/**`, after checking that they contain no private repository names, secrets, personal paths, or private workflow assumptions.

The concrete machine-readable allowlist will later be stored in a dedicated sync policy file. That file must enumerate paths or tightly bounded globs. Broad catch-all rules such as `**` are forbidden.

## Public fixtures

Public fixtures must be deliberately synthetic. They must not be anonymized copies of real household records.

Approved public fixture classes are:

- minimal valid ledger;
- empty-field and boundary parsing cases;
- planned-entry completion cases;
- budget and envelope examples using invented categories and round amounts;
- cycle-boundary examples using invented dates;
- issue and decision-log examples containing fictional text;
- golden report fixtures derived only from the synthetic source fixtures.

Public fixture requirements:

- no real names, shops, institutions, addresses, account identifiers, medical terms tied to a person, or recognizable personal narratives;
- no exact copied transaction sequences, dates, balances, income cadence, or memo text from real data;
- amounts should be invented for the fixture and should avoid reproducing a real dataset through simple renaming;
- fixture provenance must be documented as `synthetic`;
- generated golden outputs must be regenerated only from approved synthetic fixture inputs.

The public sandbox `data/**`, if retained, is treated as a fixture and follows the same rules.

## Excluded from publication

The following are excluded regardless of apparent harmlessness unless a later reviewed policy change explicitly allows them:

- real or formerly real source data, including `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, `issues.tsv`, and local configuration from any operational data directory;
- backups, snapshots, exports, reports, screenshots, recordings, archives, temporary files, and generated artifacts made from real data;
- `.env*`, credentials, tokens, keys, cookies, authentication files, secret-bearing workflow files, and local AI-agent state;
- absolute home-directory paths, usernames, email addresses, device names, private repository URLs, and local mount paths;
- private trial logs, daily-use notes, incident notes, support correspondence, personal issue text, and decision records that describe real life;
- unpublished design notes whose context exposes personal financial behavior or operational security details;
- vendored caches, build products, editor state, dependency caches, and large binary artifacts not required to build or understand the public project;
- Git history from the private canonical repository unless a separate history audit explicitly approves every reachable commit.

Renaming, redacting, or deleting a sensitive file in the current tree does not make earlier private commits publishable.

## Pre-sync audit boundary

The pre-sync audit evaluates the complete exported public candidate tree, not only the diff from the previous public sync.

The audit must run before every synchronization and must fail the publication when any check is incomplete, unavailable, or ambiguous.

Minimum audit stages:

1. **Path audit**: every exported path must be justified by the allowlist; excluded patterns and unexpected files fail the run.
2. **Content audit**: scan text and supported binary metadata for secrets, personal identifiers, absolute paths, private repository references, realistic financial records, and forbidden data-file signatures.
3. **Fixture provenance audit**: verify that every public fixture is registered as synthetic and that generated outputs trace only to approved synthetic inputs.
4. **Repository hygiene audit**: reject symlinks escaping the export root, submodules pointing to private resources, oversized or unexplained binaries, caches, and executable files outside approved locations.
5. **Build and check audit**: run the public checks against the exported tree and synthetic fixtures without access to private data directories or private environment variables.
6. **Human review gate**: show the exported file manifest and audit summary before first publication and whenever the allowlist, exclusions, fixture registry, or audit rules change.

The audit must operate in a clean temporary directory. It must not read operational ledger data merely to prove that the export excludes it.

## Synchronization behavior

The future sync implementation should:

- build a fresh export tree from the private canonical default branch;
- copy only allowlisted paths;
- inject or regenerate only approved synthetic fixtures and public-facing metadata;
- run the full pre-sync audit on the export tree;
- publish only after the audit succeeds;
- make deletions in public when a previously published path leaves the allowlist;
- produce a manifest containing source commit, policy version, exported paths, audit result, and public commit;
- avoid transferring private commit history, branches, tags, releases, issues, pull requests, Actions artifacts, or repository secrets.

The synchronization credential should have write access only to the public repository and no read access to operational data outside the private source checkout.

## Initial rollout gate

Before creating or populating the public repository:

- approve this boundary document;
- choose the public repository name;
- create the machine-readable allowlist and exclusion policy;
- create or replace all public fixtures with synthetic fixtures;
- implement the clean-tree audit and manifest;
- perform one dry-run export and inspect its complete contents;
- publish the first public commit from the audited export tree.

Until these gates pass, the private `bqn-ledger` repository remains the canonical working repository and no public mirror is authoritative.
