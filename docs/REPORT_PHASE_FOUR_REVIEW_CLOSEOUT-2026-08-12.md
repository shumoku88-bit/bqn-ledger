# Report Phase 4 review closeout — 2026-08-12

## Final state

The dense-array review of every production BQN owner listed under Phase 4 `src/report/` is complete.

Final runtime main before this closeout: `fb62b941ab7042e26e0054f524802d8003500c3b`.

The phase preserved the Report layer as a boundary over already-owned Section semantics. It simplified repeated metadata lookup, renderer dispatch, publication structure, and one shared text primitive without moving accounting meaning or Section-specific presentation policy into generic report machinery.

## Main outcomes

### Catalog as one aligned relation

The retained destination catalog is now represented directly as aligned columns:

```text
key / label / category / owner / shape / human / compact / json
                         ↓
                  one catalog coordinate
```

`catalog.Table` exposes the static relation directly instead of storing row namespaces and rebuilding columns on every read. `catalog.Find` classifies once on the key axis and publishes the matched coordinate together with the public entry.

`request.Validate` reuses that coordinate rather than looking the same key up again. Catalog TSV and Section metadata TSV/JSON derive complete row or line cells before one final flatten. Listing and metadata remain source-independent.

### Coordinate-driven renderer dispatch

Request admission establishes the canonical catalog coordinate before rendering. `render.bqn` now keeps and uses it:

```text
request key
  -> admitted catalog coordinate
  -> supported surface coordinate
  -> lazy formatter selection with ◶
```

Human formatters are aligned one-to-one with the retained catalog axis. Compact and JSON formatters use the catalog support masks to map an admitted catalog coordinate onto the corresponding supported-formatter axis.

This removed the repeated report-key comparison tree without giving the Catalog formatter ownership. Section modules still own their Human/Compact/JSON formatters; Report Render owns only admission and dispatch.

### Purpose-specific composition retained

The twelve purpose-specific composer functions remain intentionally separate. Their input shapes, date requirements, accounting calls, and Section calls carry real report meaning and should not be collapsed into a universal context merely to reduce line count.

The shared `Publish` boundary was the removable part. Section result state is now classified into three publication classes:

```text
error        -> failed composition
ok/deficit   -> renderable successful composition
unavailable  -> unavailable composition with reason
```

Lazy `◶` publication removes mutable success/unavailable staging while preserving diagnostic and reason access only on the paths where they are valid. The qualification suite now explicitly proves that a Daily Target `deficit` remains a successful composition whose retained result state is `deficit`.

Date guards remain in the purpose-specific composers because they prevent invalid ordinal evaluation and therefore protect an evaluation boundary rather than incidental control-flow topology.

### Shared text and JSON primitives

`text.RenderTable` was reread and retained as an already-clear structural renderer over preformatted text cells. Width calculation, alignment, separators, and row publication remain visible on their natural column/row axes.

Only `text.FormatAmount` had removable nested mutation. Parentheses presentation is now one predicate over style and sign followed by lazy selection. Direct primitive laws were added for display width, padding, minus style, and parentheses style.

`json_text.bqn` required no production change. Its existing structure already maps characters to escaped chunks, maps encoded values/pairs to separator-aware cells, and flattens once. Rather than manufacture a refactor, the review strengthened laws for all JSON control escapes, empty string/array/object values, both booleans, and existing exact-number/object behavior.

## Important boundary lessons

Phase 4 reinforced that array-oriented cleanup is not a ban on guards or named boundaries.

- Catalog coordinates should be retained and reused after admission rather than discarded and recomputed from strings.
- `◶` is useful when dispatch is genuinely coordinate-based and lazy evaluation matters.
- Date guards remain where removing them would evaluate invalid ordinal operations.
- Report composition stays purpose-specific where inputs and semantic ownership differ.
- Section formatters remain Section-owned; the catalog remains metadata-only.
- An already structural primitive such as `json_text.bqn` is allowed to remain unchanged when stronger laws are the useful review result.

## Merged review changes

- PR #692 — Catalog / Catalog Text / Request / Section Metadata: introduced the aligned catalog relation, coordinate-returning lookup, coordinate reuse, and structural metadata publication.
- PR #693 — Render: replaced repeated report-key comparisons with catalog-coordinate and surface-coordinate lazy dispatch.
- PR #694 — Text: simplified negative amount presentation and added direct shared text primitive laws.
- PR #696 — Compose: classified shared publication state while retaining purpose-specific composer and date boundaries. The earlier #695 was closed during rebase and replaced by #696 on current main.
- PR #697 — JSON Text: retained production code unchanged and strengthened JSON boundary laws.

All retained public destination paths remained qualified by the repository full check and checked-in destination goldens. Final runtime main CI #2836 succeeded on `fb62b941ab7042e26e0054f524802d8003500c3b`.

## Protected contracts

Phase 4 retained:

- report catalog key order, labels, categories, owner paths, shapes, and supported surfaces;
- source-independent catalog and metadata listing;
- request diagnostic ownership, order, and `all` semantics;
- purpose-specific composer input shapes and date admission boundaries;
- successful / deficit / unavailable / error composition semantics;
- Section ownership of report semantics and formatter policy;
- presentation policy inputs and byte-for-byte Human / Compact / JSON destinations covered by tests and goldens;
- exact decimal JSON numbers and explicit JSON escaping;
- accounting ownership, canonical Household source ownership, provenance, and writer authority.

## Phase boundary

Phase 4 is complete.

The next normal review cursor is the first Phase 5 application owner:

```text
src/application/account_source_adapter.bqn
```

Phase 5 should begin by reviewing application adapter/effect lifetime and change locality. The first observation already visible at the boundary is repeated local path joining across canonical source adapters. Before centralizing it, the review must identify whether path composition belongs to generic source I/O, canonical Household source naming, or a narrower adapter capability, and must preserve physical basename and schema-admission ownership.
