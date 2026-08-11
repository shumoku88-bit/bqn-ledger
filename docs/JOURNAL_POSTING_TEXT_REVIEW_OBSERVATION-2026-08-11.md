# Journal Posting text review observation — 2026-08-11

## Owner and scope

`src/ledger/journal_posting_text.bqn` is the small retained pure splitter for one Posting source line. It owns only textual boundaries:

- strip the trailing semicolon comment;
- preserve ordinary single spaces inside an Account name;
- treat a tab or two consecutive spaces as the canonical Account/Amount separator;
- retain the finite historical three-single-space-token compatibility path when no canonical separator exists and token two is an exact number;
- publish Account text, Amount text, amount words, and explicit/elided/valid shape flags.

Exact transaction admission, Account lookup, currency policy, amount normalization, balance, and Journal structure remain downstream.

## Characterization first

Focused laws were added before production changed. They protect:

- the first semicolon as the comment boundary;
- canonical tab separation before the legacy compatibility path;
- the first canonical two-space separator as the Account/Amount boundary;
- ordinary single spaces inside Account names;
- explicit amount words after comment stripping.

CI #2721 was SUCCESS on the characterization-only head.

## Character-axis coordinates

The previous `BeforeComment` staged the default coordinate as text length and conditionally mutated it when a semicolon existed.

The retained form exposes the character-axis relation directly:

```text
semicolon mask
  -> semicolon coordinates
  -> append text length as absent coordinate
  -> first coordinate
  -> prefix body
```

The canonical separator follows the same domain-specific shape:

```text
tab / two-space mask
  -> separator coordinates
  -> append body length as absent coordinate
  -> first coordinate
  -> canonical Account and Amount cells
```

No generic `FirstCoordinateOrEnd` helper is introduced. Keeping the names `commentCoordinates` and `separatorCoordinates` preserves the source grammar being expressed.

## Finite compatibility retained

The legacy fallback remains explicit and guarded:

```text
no canonical separator
+ exactly three single-space words
+ token two parses exactly
-> legacy explicit Posting
```

This is an intentionally finite compatibility boundary. It is not widened into a general single-space Account/Amount parser, and it is not removed merely to make the canonical path more compact.

The fallback retains local mutation of `account` and `amount` because it conditionally replaces the canonical/no-separator interpretation. Eagerly indexing legacy tokens outside its shape guard would make the parser less total, not more BQN-native.

## Evidence

- CI #2721 SUCCESS: characterization-only coordinate/precedence laws;
- CI #2723 SUCCESS: structural comment/separator coordinates with full `tools/check.sh` and coverage.

## Review conclusion

This owner did not need an architectural rewrite. The useful subtraction was only:

```text
mutable default coordinate + guarded replacement

->

character mask -> explicit first coordinate with absent-end fill
```

The parser remains deliberately small. Its compatibility branch and result vocabulary continue to make the grammar boundary visible rather than hiding it behind a generic parsing abstraction.
