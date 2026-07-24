# Journal Event Identity Provenance 003

Status: audit snapshot
Owner: journal-identity
Canonical: no; current route: `TODO.md`
Exit: retain as evidence; this investigation does not authorize implementation or identity changes
Date: 2026-07-24

## 1. Scope

This is a finite, read-only investigation of the 404 explicit event identities observed by Journal Event Identity Inventory 002. It traces historical generators and input paths through public Git history, historical public code, private repository history, and private exact comparison.

No event identity, Journal source, classifier, parser, writer, Posting IR, report, or production file was changed.

## 2. Finite question

> For the explicit event identities remaining in the production Journal, which historical generator or input path can be proven from Git history and exact replay, and for which family can the same input reproduce the same identity?

This report separates syntax resemblance, formula evidence, attribution, input availability, determinism, exact replay, functional linkage, and any future decision. These are not interchangeable claims.

## 3. Starting gate

Public repository gate passed:

- expected `origin/main`: `0c40ea77889a44e764152c382240e6e954da0505`;
- local `main` matched `origin/main`;
- public working tree was clean;
- branch: `docs/journal-event-identity-provenance-003`.

The private repository was inspected read-only. Its starting branch was `main`. Its Git working tree already contained two untracked backup files. They were not created, removed, staged, or otherwise modified by this investigation. This pre-existing dirty state remains a reported uncertainty.

## 4. Evidence sources

### Current public tree

- `src_edit/journal_block_add_cmd.bqn` — explicit durable identity input and ordinary identity-free mode;
- `src_edit/plan_finish_cmd.bqn` — durable completion identity formula;
- `src_edit/journal_native_reverse_cmd.bqn` and `tools/edit-bqn` — reverse identity formula;
- `src_edit/travel_friend_add_cmd.bqn` and `tools/lib/edit-bqn-travel.sh` — caller-supplied travel source identity;
- `src_edit/plan_budget_sync_cmd.bqn` — budget allocation companion path, not a native Journal event-id generator;
- `docs/JOURNAL_EVENT_IDENTITY_INVENTORY_002.md` — baseline inventory contract.

### Public historical tree and Git history

The following history was inspected with full-history path logs, `-S`/`-G` searches, commit diffs, deleted-path inspection, blame/show inspection, and relevant PR metadata:

- PR #325 / commit `a4286d4`: canonical TSV-to-native Journal prefix converter;
- PR #334 / commit `375e7a6`: native Journal source cutover and early native writer routing;
- PR #336 / commit `79f135d`: removal of derived actual metadata;
- PR #338 / commit `c07e2c1`: ordinal-based append candidate selection;
- PR #340 / commit `a27ea62`: ordinary actuals stop receiving generated event identities;
- the cleanup and canonical-surface history immediately preceding Inventory 002;
- the initial Go editor and the later BQN editor transition;
- historical `tools/to-hledger` and `txn_id` generation.

Historical deleted converter files and completion records were inspected. The converter was executed only in a detached temporary worktree at its historical public commit, never by checking out the current worktree.

### Private history and exact comparison

Private Git history contained the historical TSV snapshot lineage, the native Journal migration evidence, a verified prefix, a suffix boundary, and the pre-canonicalization native Journal. The values were compared only in memory or in temporary files outside the repository. No private value, raw identity, row mapping, path, commit hash, or derived hash was copied into this report or repository.

Production observation used only the read-only inventory summary and byte/hash before-and-after checks.

## 5. Current aggregate baseline

The read-only baseline matched Inventory 002 exactly:

```text
transactions: 410
identity-free: 6
explicit event-id: 404

legacy entry 24hex: 0
TEXTUAL_OTHER: 401
PREFIXED_OTHER: 3

incoming references: 0
duplicate identity definitions: 0
dangling references: 0
self-references: 0

functional-link transactions: 12
KEEP_FUNCTIONAL: 12
REVIEW_UNKNOWN: 392
```

The 401 `TEXTUAL_OTHER` values are not `entry-` legacy IDs under Inventory 002's lexical rule. Private exact comparison additionally observed that these 401 values have the public historical `legacy:<source-file-identity>:<zero-based-admitted-row>` structure. This investigation does not alter Inventory 002's lexical or provenance semantics.

## 6. Historical generator catalogue

### 6.1 Canonical TSV migration converter

Public evidence:

- PR #325 introduced `src_next/journal_canonical_prefix_converter.bqn`, its narrow command adapter, and `tools/journal-prefix`;
- the completion record fixes the identity as `legacy:<source_file_identity>:<zero-based admitted source_row>`;
- comments and blank lines are excluded before the admitted-row index is assigned;
- the converter preserves transaction order and emits deterministic native Journal bytes;
- `tools/to-hledger` is a one-way compatibility projection and is not the owner of this identity formula.

Formula status: verified from public code and completion evidence.

Required inputs: the immutable source TSV snapshot, the source identity token, and the admitted-row ordering. The private historical TSV snapshot and migration evidence were still available for this investigation.

Determinism: deterministic when the same snapshot, source identity token, and admitted-row ordering are supplied.

Production attribution: direct exact replay, not merely a shape match. The 401-row historical TSV input produced the same 401 identities in the same semantic order as the private migration prefix and the current production Journal.

### 6.2 Early native ordinary writer: `entry-...`

The early native `journal add` route introduced before PR #340 constructed:

```text
entry-<first-24-hex-of-SHA-256(date, memo, from, to, amount, timestamp, PID, RANDOM)>
```

The formula is visible in the historical `tools/edit-bqn` path. It depends on timestamp, process ID, and shell randomness.

Formula status: verified.

Same-input determinism: nondeterministic because hidden runtime inputs are part of the seed.

Current production match: zero. No production identity was attributed to this generator.

### 6.3 Native reverse writer: `reverse-...`

The historical and current native reverse path constructs a prefix plus a 24-hex SHA-256 truncation over the original identity, reverse date, timestamp, PID, and random value.

Formula status: verified.

Same-input determinism: nondeterministic unless the original runtime timestamp, PID, and random value are retained.

Current production match: zero observed `reverse-` identities. No production identity was attributed to this generator.

### 6.4 Plan completion writer: `completion-...`

The native plan completion path constructs:

```text
completion-<plan-id>-<actual-date>
```

The formula is deterministic for the supplied plan identity and completion date. It is not a timestamp/PID/random generator.

One production identity matched this formula exactly using the transaction's retained plan link and date. Its functional link remains part of the identity evidence.

### 6.5 Explicit durable Journal writer and purchase-shaped IDs

The native `journal-block add` path requires a caller-supplied durable `--event-id`; it does not generate one. Public synthetic checks use `purchase-...` values as explicit input examples.

Two production identities have this public structural family. Public history contains no production generator for them, and the private history did not provide a generator formula or replay inputs. They remain possible manual or external identities, not proven output of the synthetic examples.

Same-input determinism: conditional on the externally supplied identity; the writer itself has no identity-generation formula to replay.

### 6.6 Travel editor

The travel editor requires `--source-event-id` from its caller. It validates and preserves the supplied source identity but does not generate it.

No production identity was attributed to a travel-prefix generator. The public travel examples are not evidence about private production origin.

### 6.7 Business `txn_id` and budget companion paths

The historical `txn_id` helper generates a deterministic business link of the form `txn-<date>-<slug>[-NN]`. It is not an event-id generator and is intentionally kept separate from `source_event_id`.

The budget companion and execution-envelope paths use functional links and explicit synthetic event identities where needed. The current `plan_budget_sync_cmd.bqn` writes budget allocation data; it does not generate production native Journal event identities.

## 7. Production family attribution

Private exact comparison produced this aggregate decomposition without exposing raw values:

```text
legacy migration family: 401
  functional-link overlay: 11
  REVIEW_UNKNOWN overlay: 390

plan completion family: 1
  functional-link overlay: 1

purchase-shaped explicit family: 2
  functional-link overlay: 0
```

The 401 migration identities are directly proven by exact replay against the retained historical TSV snapshot and migration prefix. The one completion identity is directly proven by the public formula and exact comparison of its retained plan link and date.

The two purchase-shaped identities are not assigned to a known generator. They are classified as possible manual/external input only; that label is not proof of provenance.

## 8. Exact replay experiments

### Migration replay

A private, read-only replay used the historical admitted TSV rows and the public converter formula:

```text
source identity token: journal.tsv
row numbering: zero-based admitted-row order
formula: legacy:<source identity>:<admitted row>
```

Results:

```text
historical admitted rows: 401
migration prefix identities: 401
exact replay matches: 401
semantic order agreement: yes
```

The replay was also checked against the private migration prefix and the pre-canonicalization native Journal. The current canonicalization preserved the same identity sequence.

### Plan completion replay

For each production transaction carrying a plan link, the candidate formula was evaluated in memory. One of seven plan-linked transactions matched exactly:

```text
completion_formula_exact: 1
plan-linked nonmatches: 6
```

The six nonmatches are still covered by the proven migration replay; their plan metadata does not imply that the completion generator formula produced their event identity.

### Synthetic public replay

The historical public converter test and check were run in a detached temporary worktree:

```text
bqn tests/test_journal_canonical_prefix_converter.bqn: PASS
bash checks/check-journal-canonical-prefix-converter.sh: PASS
```

Those public tests cover deterministic bytes, identity, posting IDs, metadata parity, rejection paths, and synthetic reconstruction. The temporary worktree and temporary files were removed afterward.

## 9. Same-input determinism

| Generator or path | Determinism result | Evidence |
|---|---|---|
| Canonical TSV migration | deterministic | formula, public tests, and 401 exact private replay matches |
| Plan completion | deterministic | public formula and one exact production replay |
| Early `entry-...` writer | nondeterministic | timestamp, PID, and `RANDOM` are in the seed |
| Native reverse | nondeterministic | timestamp, PID, and `RANDOM` are in the seed |
| Explicit durable writer | conditional on hidden/external input | caller supplies the identity; no generator formula |
| Travel editor | conditional on supplied input | `--source-event-id` is required and preserved |
| `txn_id` helper | deterministic, but not an event-id generator | separate business-link owner |

## 10. Functional-link boundary

The exact replay result does not override functional retention evidence.

```text
migration exact replay + functional link: 11
completion exact replay + functional link: 1
KEEP_FUNCTIONAL total: 12
migration exact replay without functional link: 390
purchase-shaped unresolved identities without functional link: 2
REVIEW_UNKNOWN total: 392
```

No incoming references were observed. That fact is independent from generator provenance and does not authorize an identity change.

## 11. Provenance matrix

This is an aggregate matrix. It contains no raw production identity, description, account, amount, link value, path, line mapping, or private hash.

| Observed family | Current count | Candidate generator | Historical evidence | Generator formula status | Required inputs | Input availability | Same-input determinism | Exact replay result | Functional-link overlay | Provenance confidence | Reconstructibility conclusion | Deletion implication |
|---|---:|---|---|---|---|---|---|---|---:|---|---|---|
| `TEXTUAL_OTHER` with canonical `legacy:` structure | 390 | TSV-to-native migration converter | public PR #325 plus private migration evidence | verified | immutable TSV snapshot, source identity token, admitted-row order | available for replayed historical snapshot | deterministic | `VERIFIED_EXACT_REPLAY: 390` | 0 | directly proven by exact replay | `PROVEN_RECONSTRUCTIBLE` for replayed inputs | `REQUIRES_SEPARATE_DESIGN_TASK` |
| `TEXTUAL_OTHER` with canonical `legacy:` structure | 11 | TSV-to-native migration converter | same evidence | verified | same as above | available for replayed historical snapshot | deterministic | `VERIFIED_EXACT_REPLAY: 11` | 11 | directly proven by exact replay | `PROVEN_RECONSTRUCTIBLE` for replayed inputs | `KEEP_FUNCTIONAL` |
| `PREFIXED_OTHER` with completion-shaped structure | 1 | native plan completion | public `plan_finish` history plus retained plan/date evidence | verified | plan identity and actual date | available for this replay | deterministic | `VERIFIED_EXACT_REPLAY: 1` | 1 | directly proven by exact replay | `PROVEN_RECONSTRUCTIBLE` for replayed inputs | `KEEP_FUNCTIONAL` |
| `PREFIXED_OTHER` with purchase-shaped structure | 2 | no identified generator; manual/external possible | explicit durable writer and public synthetic examples only | not verified | original external input and any source history | unavailable | conditional on hidden input | `MANUAL_OR_EXTERNAL_POSSIBLE: 2` | 0 | unknown | `UNKNOWN` | `NOT_AUTHORIZED` |

The matrix accounts for all 404 explicit identities. `FORMULA_VERIFIED_INPUTS_INCOMPLETE`, `VERIFIED_NONDETERMINISTIC_GENERATOR`, and `GENERATOR_INFERRED` have zero observed production transactions in this investigation. The early `entry-...` and `reverse-...` formulas remain historical generator evidence, not production attribution.

## 12. Unresolved identities

Two explicit identities remain unresolved at generator level. Their purchase-shaped syntax is compatible with manually supplied durable identifiers, but no public or private generator formula, source input, or exact replay was found.

The 390 non-functional migration identities are not unresolved as to the migration generator: they are exact replay matches. They remain in the Inventory 002 `REVIEW_UNKNOWN` disposition because provenance evidence and reconstructibility do not themselves authorize an identity change.

## 13. What is verified

- the 401-row historical TSV-to-native migration identity formula;
- exact replay of all 401 migration identities;
- deterministic migration behavior for identical inputs;
- the plan completion formula;
- exact replay of one completion identity;
- nondeterministic inputs in the historical ordinary and reverse generators;
- that ordinary current Journal writing is identity-free;
- that durable native Journal writing accepts, rather than generates, an event identity;
- the functional-link overlay and its agreement with the Inventory 002 aggregate counts.

## 14. What is inferred

- The two purchase-shaped production identities may have been manually or externally supplied.
- Their syntax is consistent with public durable-writer examples, but syntax resemblance is not generator attribution.

## 15. What remains unknown

- The original external source or operator for the two purchase-shaped identities;
- whether either identity was entered manually, supplied by an external script, or copied from another private process;
- any hidden input or historical manifest that could explain those two identities;
- whether a future replay should use a source history not present in the inspected private Git history.

## 16. Reconstructibility conclusions

For the 401 migration identities and the one completion identity, exact replay was demonstrated with the available historical inputs. This proves reproducibility of the observed historical generation path, not a general permission to change existing source data.

The two purchase-shaped identities remain `UNKNOWN` for reconstructibility. The historical `entry-...` and `reverse-...` generators are not replayable from ordinary semantic inputs alone because their runtime entropy and process inputs are not retained.

## 17. Explicit non-authorization of identity changes

This investigation authorizes no event-id deletion, cleanup preview, candidate generation, cleanup apply, migration, rewrite, or identity replacement. Lack of references, accounting irrelevance, exact replay, or reconstructibility must not be treated as authorization.

Inventory 002 classification semantics remain unchanged.

## 18. Recommended next finite task

One finite task only:

> Investigate the two purchase-shaped identities' original external input path using private historical operator/source evidence, without changing production data or public classification.

Do not combine that task with cleanup, preview, apply, migration, writer changes, or classifier changes.

## 19. Privacy confirmation

- No raw production identity was written to this file.
- No production description, account, amount, link value, row mapping, private path, private commit hash, or private-derived hash was written to this file.
- Private comparison was read-only and remained outside the repository.
- No private-derived fixture was created.

## 20. Validation

The following were run on the investigation branch or in the detached historical public worktree as noted:

```text
public synthetic converter unit test: PASS
public synthetic converter check: PASS
git diff --check: PASS
bash checks/check-docs-lifecycle.sh: PASS
bash checks/check-absolute-links.sh: PASS
bash checks/check-repo-index.sh: PASS
env -u LEDGER_DATA_DIR rtk bash ./tools/check.sh: PASS
```

Production read-only validation recorded unchanged aggregate counts, Journal byte size, and Journal SHA-256 before and after observation. The private repository's pre-existing untracked backup files were not modified.
