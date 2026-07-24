# Document Governance: OKF, BQN Audit, and Archive Separation — 2026-07-25

Status: decision intake / blocked until Israel ILS cash lifecycle plan review
Owner: docs / workflow
Canonical: yes for the three-option document-governance decision
Exit: replace with one selected pilot plan, or archive after the options are explicitly combined, rejected, or deferred

## Question

How should `bqn-ledger` keep current operational knowledge small and trustworthy while retaining the large body of historical design evidence?

Three candidate approaches are under consideration:

1. adopt Google Cloud's Open Knowledge Format (OKF) wholly or partially;
2. build a repository-specific document inventory and audit consumer in BQN;
3. move cold historical documents out of the main repository into a separate archive repository.

The decision must not assume that these are mutually exclusive. They address different layers:

```text
OKF or a compatible subset
  -> document representation and interchange

BQN consumer
  -> inventory, queries, routing graph, and drift evidence

separate archive repository
  -> physical storage and attention boundary
```

## Current problem

The repository has strong local documentation practices, including lifecycle headers, canonical routing, active-plan inventories, archive directories, and narrow checks. The remaining concern is semantic and navigational drift at larger scale:

- a document may claim current or canonical authority while no current entry point reaches it;
- multiple documents may appear to own the same current meaning;
- a completed or historical document may remain highly visible to humans and agents;
- archive volume may consume attention even when lifecycle labels are technically correct;
- adding more workflow documents and checks may itself enlarge the maintenance surface.

The goal is not to minimize document count. The goal is to reduce the number of places that can plausibly be mistaken for current authority.

## Option A — OKF representation

### Verified external shape

Open Knowledge Format v0.1 is an open specification published by Google Cloud. It represents a knowledge bundle as a directory of Markdown files with YAML frontmatter. Concept identity is path-based; ordinary Markdown links form a directed graph; optional `index.md` and `log.md` files support progressive disclosure and update history. A conformant concept requires a non-empty `type`; most other fields are optional and consumers are expected to tolerate unknown fields and broken links.

Official references:

- https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing/
- https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md

### Potential fit

`bqn-ledger` already uses a related but domain-specific lifecycle header:

```text
Status:
Owner:
Canonical:
Exit:
```

A partial OKF mapping could preserve these fields as producer-specific extensions while adding the minimum interoperable field:

```yaml
---
type: current-contract
title: Journal metadata contract
status: current contract
owner: journal
canonical: true
exit: revise when the metadata carrier changes
---
```

### Potential value

- standard Markdown plus structured metadata remains readable without special tooling;
- path identity and ordinary links match existing repository practice;
- external consumers and visualizers may become usable without locking the repository to one service;
- unknown custom fields are permitted, so repository lifecycle concepts need not be discarded.

### Risks and unresolved questions

- OKF is a format, not a stale-authority detector;
- full conformance would require frontmatter on every non-reserved Markdown concept in a bundle;
- existing `index.md` behavior may differ from OKF's reserved-file rules;
- large-scale conversion could create noisy churn without improving current routing;
- OKF v0.1 is new and may evolve;
- the repository may need only a compatible subset rather than an OKF bundle claim.

## Option B — BQN read-only document consumer

### Intended responsibility

A BQN-owned consumer would not edit Markdown or decide prose meaning. It would build a checked inventory from supplied repository files and expose observable facts such as:

```text
path
location class
status
owner
canonical claim
exit text presence
outgoing links
incoming links
reachable from selected roots
```

Candidate reports include:

```text
UNREACHABLE_CURRENT
DUPLICATE_CANONICAL_CLAIM
ACTIVE_PLAN_NOT_IN_INVENTORY
CURRENT_ROUTE_TO_COMPLETED_PLAN
ARCHIVE_DOCUMENT_CLAIMS_CURRENT
BROKEN_EXPLICIT_CURRENT_PATH
```

### Potential value

- BQN arrays are well suited to inventory, grouping, joins, reachability iterations, and classification tables;
- the audit remains inspectable and testable inside the project's primary calculation language;
- one normalized inventory could support both human reports and AI context selection;
- a read-only consumer avoids turning the document tool into another source editor.

### Risks and unresolved questions

- implementing a general YAML parser in BQN would be an unnecessary project;
- implementing a complete Markdown parser would also exceed the problem;
- a generated manifest could become a second source of truth if committed or edited independently;
- reachability alone does not prove that a document is stale;
- semantic ownership conflicts cannot be fully inferred from prose or links;
- a document-management subsystem could become another long-lived product inside the ledger.

### Narrow implementation boundary

The first BQN experiment, if selected, should consume only a deliberately restricted metadata grammar or a supplied normalized in-memory fixture. It must not claim general YAML or Markdown conformance.

A possible division of responsibility is:

```text
small transport/parser boundary
  -> supplied document facts

BQN
  -> validation, grouping, graph traversal, classification, and report data
```

The parser owner must be selected explicitly rather than smuggled into shell, BQN, or generated files.

## Option C — separate cold archive repository

### Intended responsibility

Move only cold historical evidence out of the main repository while leaving current specifications, operational guides, TODO routing, and compact pointers close to the code.

Candidate shape:

```text
bqn-ledger
  current specifications
  operational guides
  TODO and active routing
  compact archive index
  selected redirect stubs

bqn-ledger-archive
  completed plans
  historical audits
  superseded designs
  old investigations
```

### Required provenance if selected

Each moved document or generated archive inventory must retain enough information to reconstruct its origin:

```text
original_repository
original_path
source_commit
archived_at
lifecycle_status
current_path, when one exists
superseded_by, when one exists
```

### Potential value

- reduces the default repository reading surface for humans and agents;
- separates operational truth from historical evidence physically, not only semantically;
- keeps full history available without requiring deletion;
- may reduce accidental archive retrieval during AI-assisted maintenance.

### Risks and unresolved questions

- Git history, PR discussions, and relative links become less locally connected;
- redirect stubs can reproduce the same volume if overused;
- two repositories create synchronization and ownership questions;
- external archive availability becomes part of historical navigation;
- moving files before measuring current reachability could hide unresolved authority conflicts rather than fix them.

## Decision criteria

Each option or combination must be evaluated against the same criteria:

1. **Current-authority clarity** — does it reduce ambiguous current ownership?
2. **Human readability** — can moko read and edit the source with ordinary tools?
3. **Agent portability** — can different agents consume the structure without repository-specific prompt lore?
4. **Historical traceability** — can a decision be connected to its original path, commit, PR, and replacement?
5. **False-positive cost** — how often will useful documents be flagged or hidden?
6. **Maintenance cost** — does the governance mechanism require more upkeep than the drift it prevents?
7. **Incremental adoption** — can it begin with new or touched documents rather than rewrite all existing files?
8. **Reversibility** — can the pilot be removed without losing documents or rewriting history?
9. **BQN value** — does BQN perform actual relational/graph work, rather than merely reimplement text parsing?
10. **Attention reduction** — does the main repository and its L1/L2 reading route become materially smaller?

## Ordered decision slices

Each slice is docs-only or read-only unless separately authorized.

1. **Current document authority inventory**
   - count current, canonical, active, completed, historical, audit, and unclassified Markdown documents;
   - identify the actual routing roots;
   - observe current lifecycle-header coverage;
   - do not classify documents as stale from age alone.

2. **OKF compatibility mapping**
   - map current lifecycle fields to OKF-required and optional/custom fields;
   - identify reserved-filename conflicts and bundle-boundary choices;
   - compare full conformance, compatible subset, and no-adoption alternatives;
   - convert no production documents.

3. **BQN consumer boundary experiment**
   - use a small synthetic document graph;
   - characterize metadata parsing ownership separately;
   - prove reachability, incoming links, duplicate claims, and deterministic classifications;
   - no filesystem write and no permanent check.

4. **Cold archive candidate measurement**
   - identify files that are completed/historical and not required by current L1/L2 routes;
   - estimate main-repository reduction;
   - preserve original-path and source-commit requirements;
   - move no files.

5. **Decision record**
   - choose one layer, a combination, or deliberate non-adoption;
   - specify a smallest reversible pilot;
   - state what existing process or document count the pilot is expected to retire or reduce.

## Current selected slice

No implementation option is selected by this intake. After the Israel ILS lifecycle planning PR is reviewed, the first eligible document-governance slice is Slice 1, a docs-only current-authority inventory using repository metadata and links. It must not add OKF frontmatter, BQN runtime, a new CI failure, or an external archive repository.

## Non-goals

- No full-repository frontmatter migration.
- No claim that `bqn-ledger` is an OKF-conformant bundle before conformance is measured.
- No general YAML parser in BQN.
- No general Markdown parser in BQN.
- No natural-language semantic synchronizer.
- No automatic deletion, movement, or rewriting of documents.
- No new AI telemetry or automatic TODO creation.
- No coupling to Israel accounting runtime or generic projection extraction.
- No resumption of PR #354 through this decision intake.

## Sequencing

1. Review and route the Israel ILS cash lifecycle first.
2. Perform this document-governance decision work second.
3. Reassess PR #354 only after both concrete priorities have a recorded outcome.
