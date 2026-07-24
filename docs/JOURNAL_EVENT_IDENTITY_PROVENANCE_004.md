# Journal Event Identity Provenance 004

Status: audit snapshot
Owner: journal-identity
Canonical: no; current route: `TODO.md`
Exit: retain as evidence; this investigation does not authorize implementation or identity changes
Date: 2026-07-24

## 1. Scope

This is a finite, read-only investigation of the two purchase-shaped event identities left unresolved by Journal Event Identity Provenance 003.

The investigation traces only the original external or operator input path. It does not decide whether an identity is needed, removable, replaceable, or eligible for cleanup.

No event identity, Journal source, classifier, parser, writer, editor, Posting IR, report, or production file was changed.

## 2. Finite question

> For the two purchase-shaped identities left unresolved by Provenance 003, can the operator command, manual edit, external script, editor invocation, migration-external input, or another private source that supplied the original identity string be directly identified from historical evidence?

The result distinguishes an exact operator command from an inference that the command wrote the production transaction. A matching string, a supported option, or a similar public fixture is not by itself direct provenance.

## 3. Starting gate

Public repository gate passed:

- expected `origin/main`: `de8d0523e6efbab4547ff4a5264fa4e81c487887`;
- local `main` matched `origin/main`;
- public working tree was clean;
- investigation branch: `docs/journal-event-identity-provenance-004`.

The private repository was inspected read-only. Its starting branch was `main`. Its starting Git state contained two pre-existing untracked backup files. Their names and contents are intentionally not recorded here. They were not created, removed, moved, staged, committed, or otherwise modified.

## 4. Evidence locations inspected

### Current public tree

- `src_edit/journal_block_add_cmd.bqn` — durable `event-id` is caller-supplied input; ordinary Journal append is identity-free;
- `tools/edit-bqn` and `tools/edit` — explicit `journal-block add` dispatch and safe-write boundary;
- ordinary Journal add/multi-add, plan completion, reverse, and travel editor paths;
- `src_edit/travel_friend_add_cmd.bqn` — separate caller-supplied travel source identity contract;
- public synthetic Journal checks and purchase-shaped examples.

### Public historical tree and Git history

- historical BQN editor and writer revisions;
- deleted Go editor paths, especially the historical Journal add and reverse implementation;
- migration/converter history and old derived-identity generators;
- relevant Journal, travel, plan-completion, and reverse commits and checks.

The historical Go Journal add path accepted ordinary semantic fields and the reverse path selected an existing row. No historical Go path was found that generated these purchase-shaped identities as a durable Journal input.

### Private evidence

- current production Journal and its historical Git versions;
- private Git exact-string history for the two targets;
- tracked historical Journal copies and migration/prefix/suffix candidate evidence;
- project-local candidate scripts, notes, manifests, TSV snapshots, and travel-source files using exact fixed-string searches;
- narrow operator-history search using exact fixed-string target matches only.

Each target occurred once in the current production Journal and had one Journal-history introduction/change record. No exact target match was found in a private TSV, script, note, manifest, travel-source file, or other non-Journal local source.

## 5. Search restrictions

- Target values were held only in shell variables or permission-restricted temporary files outside both repositories.
- Exact fixed-string matching was used; target values were never printed into this document or the public repository.
- Operator history was searched only for the exact target strings and the resulting command context. The history was not exported or broadly dumped.
- Browser history, mail, application databases, encrypted material, unrelated projects, and general documents were not inspected.
- Temporary target files were removed after each investigation step.

## 6. Public input-path catalogue

| Candidate input path | Public evidence result |
|---|---|
| explicit `journal-block add --event-id` | Current BQN editor accepts the identity as explicit durable input; this is an input path, not a generator formula. |
| historical Journal add or multi-add | Ordinary add paths are identity-free; no target match or purchase-shaped generator was found. |
| old Go editor | Historical Go code was inspected; Journal add did not accept a durable purchase identity, and reverse selected an existing row rather than generating this family. |
| BQN editor history | Explicit durable input is supported; no public exact target match was found. |
| manual Journal edit | No public diff or save history directly added either target. |
| external shell script | No public or private project-local script contained either target. |
| temporary migration helper | No target was found in migration/prefix/suffix evidence. The public migration converter produces the separate `legacy:` family. |
| travel editor source-event ID | No target was found in travel source files; that path has a separate source-event contract. |
| public synthetic example or manual transfer | Purchase-shaped examples establish only syntax compatibility; neither target exactly matches a public example. |
| another private source | No exact target was found outside Journal history and the narrow operator history. |

## 7. Private evidence availability

The two targets were selected from the current production Journal without displaying their raw values. For each target:

- current production occurrence count: 1;
- private Journal-history introduction/change count: 1;
- non-Journal private source match: 0;
- exact operator-history match: present;
- event identity was supplied through an explicit `--event-id` argument in the matching command history;
- no independent generator, migration formula, travel source, or external script was found.

Target A had an exact history sequence containing one dry-run and one applying invocation using a named native-base variable. This is direct operator-command evidence and is consistent with the unique production Journal occurrence.

Target B had four exact history entries: one non-rehearsal applying invocation using a relative base and three invocations against an explicitly named rehearsal base. The command and identity are directly evidenced, but the retained history does not prove that the relative base resolved to the private production Journal. The production correspondence is therefore an inference, not a direct command-to-file proof.

## 8. Target A aggregate result

Target A is classified as `VERIFIED_OPERATOR_COMMAND`.

The exact target string appears in the operator command history as an explicit `journal-block add --event-id` input, with a dry-run followed by an applying invocation. The current production Journal contains exactly one matching transaction, and private Journal history records one corresponding introduction/change. The command is not a generator formula: the identity was supplied as an argument and carried into the durable Journal block.

Confidence: high for the operator command and input mechanism. The identity-change implication is `NOT_AUTHORIZED`.

## 9. Target B aggregate result

Target B is classified as `INFERRED_OPERATOR_INPUT`.

The exact target string appears in operator command history as an explicit `journal-block add --event-id` input, including an applying invocation. The current production Journal contains exactly one matching transaction, and private Journal history records one corresponding introduction/change. However, the retained command used a relative base, while the recorded surrounding shell context does not preserve a direct link from that base to the private production Journal. Rehearsal commands are present separately, so the command-to-production association cannot be elevated to direct verification.

Confidence: medium for the operator input mechanism; lower for the exact production-file linkage. The identity-change implication is `NOT_AUTHORIZED`.

## 10. Direct evidence versus inference

Direct evidence:

- both target strings were exact fixed-string matches in operator history;
- both matching commands explicitly supplied `--event-id` to `journal-block add`;
- each target has one current production Journal occurrence and one private Journal-history introduction/change record;
- the public BQN implementation confirms that durable `event-id` is accepted as input rather than generated by this path.

Inference boundary:

- Target A has a named native-base command sequence with dry-run/apply ordering, supporting direct operator attribution;
- Target B's relative-base command is exact evidence of an operator input, but the retained history does not prove its base directory was the private production base;
- no evidence proves a manual transfer, external script, or independent private source for either target;
- shell history does not preserve enough context to reconstruct every process environment or variable expansion.

## 11. Attribution matrix

| Target | Observed structural family | Candidate input path | Exact-match evidence found | Operator command evidence | Private source evidence | Historical timing consistency | Attribution class | Confidence | Reconstructibility | Identity-change implication |
|---|---|---|---|---|---|---|---|---|---|---|
| Target A | purchase-shaped explicit durable identity | explicit `journal-block add --event-id` | current Journal: unique; Journal history: one change; operator history: exact | exact dry-run followed by applying invocation with named native-base variable | no separate source; unique Journal history only | consistent command order and Journal history | `VERIFIED_OPERATOR_COMMAND` | high | operator input path reproducible; original private context not fully retained | `NOT_AUTHORIZED` |
| Target B | purchase-shaped explicit durable identity | explicit `journal-block add --event-id` | current Journal: unique; Journal history: one change; operator history: exact | exact applying invocation with relative base; rehearsal variants also present | no separate source; production linkage not directly preserved | consistent with the Journal occurrence, but base resolution is unproven | `INFERRED_OPERATOR_INPUT` | medium | input mechanism reproducible; production-file linkage remains unresolved | `NOT_AUTHORIZED` |

## 12. Remaining unknowns

- Target B's historical relative-base command cannot be tied directly to the private production Journal from retained evidence.
- The original shell variable expansion and complete working-directory/session context are not retained for all commands.
- No direct evidence was found for manual editing, an external script, a migration helper, a travel source, or another private source.
- No conclusion is drawn about deletion, replacement, cleanup, classification, or future writer policy.

## 13. Privacy boundary

- No raw event identity is written here.
- No private path, private commit hash, production hash, description, date, account, amount, or raw command is written here.
- No private-derived fixture, mapping, or temporary repository file was created.
- The two pre-existing private backup files were left untouched.

## 14. Explicit non-authorization of identity changes

This investigation authorizes no event-id deletion, replacement, cleanup preview, cleanup apply, candidate Journal generation, migration, rewrite, classifier change, Inventory 002 change, Provenance 003 change, writer change, editor change, parser change, or Posting IR change.

The two target identities remain outside any identity-change operation. Their input-path attribution does not authorize changing production data.

## 15. Recommended next finite task

One finite task only:

> Verify the historical relative-base destination for Target B using only already-retained operator-session context, without exporting shell history, changing production data, or modifying public classification.

Do not combine that task with cleanup, apply, migration, writer changes, classifier changes, or investigation of any third identity.

## 16. Validation

The following public checks were run after the documentation was written:

```text
git diff --check: PASS
bash checks/check-docs-lifecycle.sh: PASS
bash checks/check-absolute-links.sh: PASS
bash checks/check-repo-index.sh: PASS
env -u LEDGER_DATA_DIR rtk bash ./tools/check.sh: PASS
```

Private read-only safety checks were repeated after the investigation:

- production Journal SHA-256 unchanged;
- production Journal byte size unchanged;
- private branch unchanged;
- private HEAD unchanged;
- private Git status unchanged;
- pre-existing untracked backup count unchanged;
- no private data was committed.
