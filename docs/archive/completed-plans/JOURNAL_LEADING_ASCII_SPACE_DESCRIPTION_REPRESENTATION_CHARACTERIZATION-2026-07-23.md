# Journal leading ASCII space description representation characterization

Status: completed public-synthetic test-only characterization
Owner: journal source migration / parser contract boundary
Canonical: no; current route: `../../../TODO.md`
Exit: archived; implementation requires a separately selected finite slice
Date: 2026-07-23

## Purpose

Determine, using public synthetic evidence only, whether a description whose first payload character is ASCII SPACE survives the current Journal grammar, Stage 1 parser, Transaction IR, and Stage 2A Posting IR path exactly.

## Finite question

Can source description `ASCII SPACE + "Synthetic description"` be represented exactly today? If not, what is the smallest future contract delta that avoids information loss?

## Starting evidence

`journal_canonical_prefix_converter.bqn` requires a nonempty description equal to its ASCII-space trim and without C0 controls or DEL. Its renderer concatenates `date`, `" * "`, and the unescaped description. The existing converter regression rejects a leading-space description with `description_not_canonically_representable`; that regression remains unchanged.

Stage 1 obtains a transaction header through `FirstLine`, then `ParseHeader`. After the date it applies `TrimLeft`, consumes the status marker, and applies `TrimLeft` again to the remaining text when extracting the description. Transaction IR owns `description`. Stage 2A emits the current 16-field Posting IR and has no description field.

## Public synthetic evidence

`tests/test_journal_leading_ascii_space_description_characterization.bqn` constructs ASCII SPACE explicitly as `@+32`. It builds two otherwise identical self-contained Journals:

- control payload: `"Synthetic description"`;
- target payload: `ASCII SPACE + "Synthetic description"`.

The header construction supplies one grammar separator after `*`; the target payload independently supplies the next ASCII SPACE. Both Journals declare JPY, two invented accounts, one actual transaction, one invented event ID, and two explicit balanced postings. Date, status, metadata, declarations, posting order, amounts, commodity, and layout are identical.

## Observed parser classification

```text
silent_normalization
```

Both parses return `ok` with zero diagnostics and one transaction. The control Transaction IR description equals its source payload. The target Transaction IR description is `"Synthetic description"`, not the target source payload. The two distinct source descriptions therefore collapse to the same Transaction IR description without a diagnostic.

This characterization fixes an observed information-loss boundary; it does not approve silent normalization as the desired specification. An exact-preservation contract implementation must intentionally update the focused expectation.

## Transaction IR result

Transaction IR has a `description` field, but the current header extraction has already removed all ASCII SPACE immediately following the status marker. Transaction IR therefore cannot distinguish the control and target sources in this case.

## Posting IR boundary

Both admitted Transaction IR values pass Stage 2A with state `ok`, zero diagnostics, two rows, preserved posting order, deltas `51` and `-51`, expected account coordinates, and all 16 current fields accessible. The complete 16-field projections for control and target are equal.

Stage 2A Posting IR owns no description field. Once Stage 1 has collapsed the descriptions, Stage 2A cannot recover the source-owned leading ASCII SPACE. This is an upstream grammar/parser ownership issue, not a Posting IR shape issue.

## Converter boundary

`converter.DescriptionRepresentable` returns false for the target description. The existing converter regression that expects `description_not_canonically_representable` was neither removed nor weakened. Converter rendering has no quote, escape, or length prefix that could independently disambiguate the payload.

The leading-space rejection must not be relaxed until the parser contract guarantees exact preservation or explicit rejection. Required ordering is:

1. Journal header grammar / parser contract;
2. exact Transaction IR description evidence;
3. converter `DescriptionRepresentable` policy;
4. public synthetic conversion parity;
5. private verification.

This slice performs only the current-boundary characterization.

## Minimal contract delta candidate

For a future separately selected slice, define the header as date, one required ASCII SPACE, status marker, one required ASCII SPACE delimiter, then description payload. After the status marker, the parser must consume exactly that one required delimiter rather than `TrimLeft` all leading ASCII SPACE characters. Transaction IR `description` then owns the remaining payload exactly.

This candidate requires no quoting, escaping, length prefix, metadata key, Posting IR field, serializer format, Unicode normalization, generic whitespace redesign, or trailing-space contract change. Trailing ASCII SPACE is a separate question.

## Why Posting IR does not need a description field

The loss occurs before Transaction IR is completed. Exact Transaction IR ownership is sufficient for the finite representation question, while Stage 2A remains a normalized accounting-row boundary. Adding description to Posting IR would not repair parser information loss and would broaden an unrelated runtime contract.

## Success criteria

- public synthetic control and target differ only by one description-owned leading ASCII SPACE;
- Stage 1 state, diagnostics, counts, and exact descriptions are asserted;
- the observed non-injective normalization is explicit;
- Stage 2A state, diagnostics, row count, 16-field shape, order, deltas, and account coordinates are asserted;
- converter rejection remains intact;
- no runtime source implementation or production routing changes.

All criteria passed.

## Non-goals

Parser or converter implementation, Posting IR changes, metadata work, trailing-space policy, private evidence, conversion, reconstruction, writer changes, production routing, cutover, and selection of a later slice are excluded.

## Validation

Passed with `LEDGER_DATA_DIR` unset:

```text
bqn tests/test_journal_leading_ascii_space_description_characterization.bqn
bqn tests/test_journal_canonical_prefix_converter.bqn
bqn tests/test_src_next_journal_profile_stage1.bqn
bqn tests/test_journal_posting_ir_adapter_stage2a.bqn
git diff --check
bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
rtk bash ./tools/check.sh
```

## Completion routing

```text
leading ASCII space description representation characterization: completed
implementation: not selected
parser contract change: not selected
converter relaxation: not selected
opaque metadata preservation: not selected
private converter retry: not selected
production source truth: TSV
production report routing: TSV
production cutover: blocked
next finite Journal slice: not selected
```
