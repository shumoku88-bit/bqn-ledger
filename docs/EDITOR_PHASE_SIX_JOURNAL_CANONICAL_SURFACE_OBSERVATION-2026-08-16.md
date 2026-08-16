# Editor Phase 6 Canonical Journal Surface observation — 2026-08-16

## Status

The Canonical Journal Surface 001 family has been reviewed as one Phase 6 owner family under the 2026-08-16 BQN-native re-baseline:

- `src_edit/journal_canonical_surface_apply_cmd.bqn`
- `src_edit/journal_canonical_surface_plan.bqn`
- `src_edit/journal_canonical_surface_plan_cmd.bqn`
- `src_edit/journal_canonical_surface_preview_cmd.bqn`
- `src_edit/journal_canonical_surface_rewrite.bqn`

The family is intentionally reviewed together because classification, rewrite, candidate publication, and filesystem apply are one safety story. Splitting them into tiny independent rewrites would hide the boundary this review is meant to clarify.

## Semantic pipeline

The retained architecture is:

```text
physical Journal bytes
  -> canonical parser / historical profile
  -> physical Posting + metadata observations
  -> transaction surface classification
  -> whole-source rewrite candidate
  -> semantic equivalence verification
  -> caller-owned candidate artifact

shell filesystem boundary
  -> path / inode admission
  -> source snapshot
  -> preview or final safe publication
  -> mandatory equivalence
  -> post-check / guarded rollback
```

BQN decides what the candidate means and whether it is semantically equivalent. Shell decides whether a filesystem path is safe to write and whether the observed source is still the source being published over.

## BQN-native changes

### One physical Posting observation

The previous family classified a Posting line in `journal_canonical_surface_plan.bqn`, then `journal_canonical_surface_rewrite.bqn` independently repeated indentation/separator/account/amount parsing for the same line.

`AnalyzePostingLine` now publishes the complete physical observation needed by both consumers:

- Posting/not-Posting;
- indentation count;
- separator coordinate and separator width;
- canonical/single-space/multi-space classification;
- Account prefix;
- amount/Commodity suffix;
- CR evidence.

Planning and rewriting therefore consume one admitted observation instead of maintaining two physical parsers.

### Classification coordinate

Transaction classification previously staged a mutable `classification` string through several conditionals. The Canonical Surface has only two independent repair axes:

```text
spacing repair needed
redundant metadata present
```

Those booleans now form the four-state coordinate directly:

```text
canonical
spacing_only
redundant_metadata_only
spacing_and_redundant_metadata
```

This exposes the actual 2-bit relation rather than encoding it as mutation order.

### Whole-source line relation

Rewrite now maps `RewriteSingleLine` over the source line relation, derives a keep mask from redundant metadata observations, and filters the rewritten line relation. It no longer grows the output line collection procedurally.

The same line observation owns canonical Posting reconstruction, so source-order remains the array order.

### Presentation / manifest construction

Plan text/TSV and Apply/Preview protocol lines are built from line/field relations rather than mutable output strings. Path composition uses the existing `source_io.JoinPath` owner instead of duplicating path concatenation in BQN.

## Complexity deliberately retained

### Final newline correction

The final newline adjustment remains explicit and mutable.

`SplitKeepEmpty` preserves trailing empty cells, while Canonical Surface promises physical source-ending behavior. The candidate must therefore reconcile the joined line relation with whether the original byte sequence ended in LF. This is source-shape transport logic, not a regular semantic collection, and hiding it behind a generic join would make the law less visible.

### Ordered equivalence diagnostics

`VerifyEquivalent` retains ordered diagnostic accumulation. It compares the complete pre/post parser observations and reports transaction/header, Posting, metadata, and declaration mismatches in a stable fail-closed sequence.

The review found no stronger semantic axis that would justify replacing this with a compact but less explicit reduction.

### Caller-owned candidate artifact

`Apply` and `Preview` still let BQN write the already-verified candidate bytes to a caller-owned artifact. This is retained deliberately.

BQN does **not** choose or overwrite the canonical source path. For Apply, shell creates the temporary candidate path. For Preview, shell admits the requested output path first. BQN writes the exact candidate bytes and now reads the artifact back to verify the bytes actually stored before publishing a success protocol.

This matches the existing Cleanup rewrite protocol and keeps large candidate bytes out of fragile shell command-substitution protocols.

## Filesystem boundary defect found

The former Preview leaf protected the source only with textual equality:

```text
sourcePath == outputPath
```

That is not a filesystem identity law. `./actual.journal`, a symlink, or a same-inode hard link can name the same source through different text.

The public Canonical Surface route now goes through `tools/journal-canonical-surface`, where shell owns filesystem identity and publication effects.

The boundary:

- resolves the Household base physically;
- rejects traversal and source symlink components;
- requires the canonical root `actual.journal` directly;
- does not recover the retired nested `data/actual.journal` source topology;
- resolves the Preview parent physically;
- rejects Preview final-component symlinks;
- rejects canonical path aliases;
- rejects existing same-inode output aliases with the source;
- permits a distinct caller-owned Preview artifact;
- snapshots the canonical source before Apply candidate generation;
- rechecks the snapshot before publication;
- delegates final replacement, backup, mandatory equivalence, post-check, and rollback to the existing safe-write helpers.

`tools/edit` routes the three public Canonical Surface commands to this owner before the older monolithic editor fallback.

The old Canonical branches inside `tools/edit-bqn` are retained transitional residue rather than duplicated current authority. Their reachability/removal belongs to the later cross-cutting dead-surface audit; the supported public route is `tools/edit`.

## Source topology decision

The previous monolithic Apply branch still contained a historical fallback from:

```text
<base>/actual.journal
```

to:

```text
<base>/data/actual.journal
```

Current Household source policy defines the eight canonical files directly under the canonical data root and explicitly rejects historical nested recovery. The new public Canonical Surface writer therefore has one source authority only: `<canonical-base>/actual.journal`.

This also prevents BQN from observing one file while shell silently chooses another file as the write target.

## Qualification laws

The focused public-boundary check exercises:

- public Plan reachability;
- `./actual.journal` Preview alias rejection;
- symlink Preview rejection;
- same-inode hard-link Preview rejection;
- unchanged source digest after every rejection;
- successful distinct Preview artifact and canonical bytes;
- public Apply dry-run with unchanged source;
- public checked Apply and mandatory semantic equivalence;
- idempotent second Apply / `CANONICAL_NOOP`;
- rejection of historical nested `data/actual.journal` recovery.

The older Canonical Surface E2E portfolio remains as independent characterization of the BQN protocol and safe-write behavior while the monolithic dispatcher residue still exists.

## Decision

The reviewed family now exposes the intended ownership boundary:

```text
BQN
  physical observation
  -> classification relation
  -> rewrite relation
  -> semantic equivalence
  -> exact candidate artifact

shell
  filesystem identity
  -> snapshot
  -> preview/final publication
  -> mandatory verification
  -> rollback
```

No generic rewrite framework is introduced. Canonical Surface and Cleanup may share architectural laws without being forced into one implementation abstraction.

After final CI qualification, the normal Phase 6 cursor advances to the Journal Cleanup family beginning at:

```text
src_edit/journal_cleanup_apply_cmd.bqn
```
