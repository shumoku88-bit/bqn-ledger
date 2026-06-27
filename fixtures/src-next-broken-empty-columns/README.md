# Broken Empty Columns Failure Fixture

Tests that empty columns in journal-like TSV are preserved (SplitKeepEmpty), not dropped (Split).

## Description

Row 1 has an empty memo field (column 2 is blank):

```
2026-06-16<TAB><TAB>assets:bank<TAB>expenses:food<TAB>5000
```

If `Split` is used instead of `SplitKeepEmpty`, the empty memo is dropped and
`assets:bank` shifts to the memo column, breaking the parse.

Row 2 has a normal memo and metadata for comparison:

```
2026-06-17<TAB>買い物<TAB>assets:bank<TAB>expenses:food<TAB>3000<TAB>receipt=yes
```

## Expected behavior

- Row 0: normal entry, source_id="給料日"
- Row 1: empty memo entry, source_id=⟨⟩ (empty), from/to/amount correct
- Row 2: normal entry with metadata, source_id="買い物"
- Total expenses: 8000 (= 5000 + 3000)
- All rows parse as `status: ok`
- `valid projection rows: 6` (3 transactions × 2 postings each)
