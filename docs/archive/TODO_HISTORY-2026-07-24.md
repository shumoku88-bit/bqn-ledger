# TODO History — 2026-07-24

Status: historical
Owner: docs
Canonical: no; current route: `TODO.md`
Exit: retained as the completion record for the Journal-source and repository-cleanup work closed through 2026-07-24

## Report projection alignment foundation

Status: completed for the selected sequence.

Completed results:

- Actual Comparison numeric ownership moved to checked Posting IR and local TBDS period views.
- Outlook checked numeric-owner Slices A/B completed.
- Daily Trend plan numeric-owner migration completed.
- Cycle Summary remaining-plan characterization, compatibility decision, and runtime migration completed.
- Envelope allocation and execution-plan coverage characterization completed.

No later report-wide rewrite, metadata-axis expansion, generic temporal kernel, or completion-aware Cube change was selected automatically.

## Journal parser, Posting IR, and read-path foundation

Status: completed for the selected migration sequence.

Completed results:

- Minimal BQN Journal Profile Stage 0 characterization.
- Minimal BQN Journal parser Stage 1.
- Posting IR adapter success-path parity Stage 2A.
- identity/provenance parity Stage 2B.
- comparable rejection parity Stage 2C for the selected finite rejection set.
- native three-posting semantic-coordinate parity while preserving Journal and legacy row-topology differences.
- trial-balance, report-context, and file-backed source-carrier rehearsals.
- resolved-account registry mismatch rejection.
- split-purchase characterization and report information-boundary evidence.
- resolved envelope assignment persistence and budget companion projection characterization.
- native multi-posting explicit-path editor and external plan-reference profile prerequisite.

These records remain under `docs/archive/completed-plans/`. They are historical evidence, not an automatic queue for broader rejection parity or new runtime work.

## Journal-only Actual source cutover

Status: completed.

Implementation milestones:

- PR #334 cut production Actual routing to native Journal.
- PR #344 retired the Actual TSV runtime, fallback, dual-write, editor, and fixture routes.

Current boundary after closure:

- the configured native Journal is the only production Actual source;
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion/configuration source files;
- reports and supported editor flows consume Transaction IR and checked Posting IR;
- private legacy snapshots and rehearsal/recovery directories remain untouched unless separately approved.

## Canonical Journal surface and identity cleanup

Status: completed for the selected cleanup boundary.

Completed results:

- ordinary native Actual writes no longer require generated durable `event-id` metadata;
- derived `layer: actual` and transaction-level `currency: JPY` output was removed from ordinary writes;
- candidate validation uses append ordinal while durable workflows retain explicit identity checks;
- the supported production Journal surface was canonicalized without changing accounting semantics;
- read-only identity inventory separated lexical family, references, functional links, provenance, reconstructibility, and disposition;
- reconstructible non-functional migration identities were removed through a checked atomic path;
- functional identities, purchase-shaped unresolved identities, and identity-free transactions were preserved according to the selected boundary.

Current record:

- `docs/JOURNAL_RECONSTRUCTIBLE_IDENTITY_CLEANUP_001.md`

No broader identity deletion is selected.

## Unused MCP adapter retirement

Status: completed by PR #351.

Completed results:

- removed the unused MCP server, Node dependencies, CI wiring, environment variables, checks, and active documentation;
- preserved historical archive references;
- preserved the pre-removal implementation at Git tag `checkpoint-pre-mcp-removal` targeting `68861065e9172a947e96a387ddb1a28cfd200f83`.

Future recovery requires a new concrete consumer and a fresh compatibility/security review. The archived implementation is not a current runtime path.

## Routing after closure

- No finite Journal migration or report-projection implementation slice is selected.
- The generic projection and valuation design intake is recorded at `docs/archive/active-plans/GENERIC_PROJECTION_AND_VALUATION_FOUNDATION_DESIGN_INTAKE-2026-07-24.md`.
- That intake is an active backlog only. It does not authorize Cube refactoring, a Currency axis, FX, valuation, mixed-currency aggregation, or source-schema migration.
- The first eligible follow-up is a separately selected docs-only ownership inventory.