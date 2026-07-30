# add-ui action catalog probe

## Question

Can the repeated action declarations in `tools/add-ui.sh` be understood more clearly as one BQN array model, and would that model suggest a useful production boundary between UI metadata and shell interaction?

Current analogue: `tools/add-ui.sh`.

The shell currently repeats action knowledge across:

- help text;
- accepted command-line modes;
- selector menu rows;
- the large interaction `case`;
- mode-specific input choreography.

This experiment does not change any of those owners. It models the current twelve daily UI actions with synthetic public metadata and compares two views of the same observations:

1. a row-oriented sequence of action namespaces;
2. a column-oriented catalog with aligned `key`, `label`, `family`, `effect`, and `inputs` arrays.

## Boundaries

Preserved in the observation:

- the twelve current `add-ui.sh` mode keys;
- their broad UI families;
- representative interaction inputs;
- the distinction between append, replace, derived append, and orchestration;
- shell remains responsible for terminal interaction;
- BQN editor remains responsible for command validation and write protocols.

Intentionally relaxed:

- labels and input tokens are observational, not a production schema;
- the probe does not execute editor commands;
- `effect` describes the UI flow only and is not an authoritative accounting or persistence classification;
- no shell, runtime, editor, or source file imports this experiment.

## Compared representations

### Row-oriented namespaces

A selected action is already a complete object:

```text
{key, label, family, effect, inputs}
```

This is direct when reasoning about one chosen mode.

### Column-oriented catalog

The same fields are aligned arrays:

```text
key     ─┐
label    │
family   ├─ same action coordinate
effect   │
inputs  ─┘
```

This makes whole-catalog questions direct:

- generate every menu row;
- validate key uniqueness;
- select all journal-family actions;
- select all replace actions;
- compare input counts;
- align effect keys with a function array.

The probe also projects a selected column coordinate back into one row namespace. This tests a hybrid rather than declaring rows or columns universally superior.

## Execution

The final probe ran successfully in GitHub Actions workflow run `30535122149` on 2026-07-30.

Observed output included:

```text
action count: 12
column key shape: ⟨12⟩
row collection shape: ⟨12⟩
unique key count: 12
input count by action: 3‿5‿3‿5‿5‿5‿6‿3‿3‿2‿3‿3
first-occurrence families: ⟨"account","journal","budget","plan","issue"⟩
journal family keys: ⟨"expense","multi","move","income","reverse"⟩
replace effect keys: ⟨"plan-edit","issue-close"⟩
selected records agree: 1
reverse handler description: "derived_append/reverse"
missing key index bound: 12
```

The aligned `key` and `label` columns generated all twelve selector rows without a separate menu declaration. Family and effect questions became masks over aligned columns. Projecting the selected `expense` coordinate produced the same record as filtering the row-oriented collection.

The absent lookup returned the key-count bound `12`. A production lookup would therefore need an explicit fail-closed bound check before selection, just as other exact catalog owners do.

## Function arrays and Choose

The experiment first attempted to Pick a function from `effectHandlers` into a local name and then call it. This exposed BQN's syntactic roles:

- a lowercase name is a subject, so `handler action` parses as two subjects;
- changing the name to uppercase does not change the role of the Pick expression on the right side, so direct assignment still has mismatched roles;
- Choose `◶` directly expresses the intended operation: compute an effect index, choose the aligned function, and apply it to the original action.

The successful form was:

```bqn
EffectIndex ← {𝕊 action: IndexOf ⟨action.effect,effectKeys⟩}
Describe ← EffectIndex◶effectHandlers
```

This is more than shorter dispatch syntax. It states that the effect coordinate and the handler coordinate are one aligned relation.

## Views, namespaces, and evaluation order

A namespace was convenient for one selected action but could not be printed with `•Repr` directly. The probe therefore introduced an explicit `RecordView` that publishes only the fields needed for observation.

The first inline comparison of two `RecordView` applications also exposed right-to-left evaluation. Naming `columnView` and `rowView` before comparing them made both the execution order and the intended evidence visible.

These failures are retained as useful results. They show that a BQN catalog is not merely a shell table rewritten with glyphs. Function role, selected views, and evaluation order affect the shape of a clear design.

## Result

The most promising model is a hybrid:

```text
aligned column catalog
  owns stable portfolio-wide observations and derivations

selected row namespace
  owns one chosen action passed to a concrete interaction stage

explicit view/export
  publishes only what a shell or another client needs
```

The column catalog made uniqueness, ordering, menu generation, grouping, effect selection, and dispatch alignment direct. The row namespace remained natural after one action had been selected.

This does **not** imply that all of `add-ui.sh` should move into BQN. The following remain genuinely effectful interaction stages:

- `/dev/tty` input and cancellation;
- fzf, gum, and numbered fallback selection;
- loops such as multi-posting collection;
- account-list subprocesses;
- plan-finish orchestration and status translation;
- invoking the approved editor and displaying its result.

Encoding those stages as generic catalog data could hide the human conversation rather than clarify it.

## New capability revealed

A structured action metadata export could serve more than the current terminal selector:

- `add-ui.sh` mode admission and menu rows;
- the main command hub;
- a conversational client;
- a future thin terminal or HTML presenter;
- documentation generated from the same admitted action coordinates.

That is a new capability, not a meaning-preserving shell refactor.

## Possible production slice

The smallest plausible adoption slice is:

```text
one admitted action catalog
→ exact key lookup
→ stable order and menu label export
→ shell keeps explicit mode-specific interaction dispatch
```

Before selection, that slice must decide whether BQN, a simple config file, or shell itself is the clearest owner. BQN is already useful as the design lens even if the eventual production catalog is not a BQN module.

## Destination

- observed experiment: retained;
- possible production slice: stable action keys, order, admission, and selector metadata only;
- possible new capability: structured action metadata export for multiple thin clients;
- parked: replacing every mode-specific shell interaction with generic BQN-driven choreography;
- next useful probe: compare a narrow BQN metadata exporter with a small shell/config catalog and characterize unknown-key, duplicate-key, ordering, and client-boundary behavior.
