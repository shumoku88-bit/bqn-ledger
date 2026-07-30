# add-ui action metadata export boundary probe

## Question

Can an aligned BQN action catalog publish a small stable metadata view that shell can consume without moving mode-specific human interaction into BQN?

The previous action-catalog experiment showed that BQN can make the complete action portfolio visible as aligned coordinates. This probe asks a narrower boundary question:

```text
BQN catalog
→ admitted public metadata view
→ shell consumer
```

It compares that path with two alternatives:

1. a small static TSV/config file as the metadata owner;
2. continued direct declarations in shell.

The experiment does not assume that the BQN path must become production architecture.

## Experimental model

The BQN catalog contains three aligned columns for the twelve current daily actions:

```text
key / label / family
```

The probe checks:

- all three columns have the same length;
- keys are unique;
- a deliberately duplicated key fails the uniqueness condition;
- a known key resolves as known;
- an absent key resolves as unknown rather than being selected;
- source order survives export;
- the first and last action coordinates remain stable.

It then publishes only the three stable columns as tab-separated rows between explicit export markers.

The shell consumer:

- extracts the export block;
- compares it byte-for-byte with the static TSV candidate;
- checks the BQN validation observations;
- reads the rows using tab-separated shell fields;
- derives the selector's `key / label` view;
- confirms all twelve rows and representative first-class actions.

No runtime, editor, `add-ui.sh`, source, or write path imports the experiment.

## First boundary failure

The initial BQN exporter used:

```bqn
"\t"
```

That produced the literal characters backslash and `t`; BQN did not interpret the spelling as a C-style tab escape. The shell diff therefore showed twelve structurally correct rows with the wrong separator bytes.

The corrected boundary names the actual character explicitly:

```bqn
tab ← @+9
```

and constructs each row with that value.

This was useful evidence. A text protocol is not established by visual resemblance or by borrowing another language's escape convention. The exact character belongs to the export contract.

## Observed result

GitHub Actions run `30536814450` completed successfully after the character fix.

The successful consumer proved all of the following together:

- the BQN coordinate lengths are aligned;
- the twelve action keys are unique;
- the synthetic duplicate is detected;
- `expense` is admitted as known;
- `missing` is rejected as unknown;
- BQN export order matches the static TSV order;
- all Japanese labels and family values survive the process boundary;
- shell parses the exported tab fields and derives twelve selector rows;
- representative `expense` and `issue-close` menu rows remain exact.

The previous action-catalog probe also continued to pass in the same workflow. The new boundary did not disturb the earlier observations.

## Candidate comparison

### BQN-owned catalog and export

Strengths:

- aligned columns make length, uniqueness, selection, ordering, and derived views explicit;
- malformed catalog variants can be characterized before publication;
- one admitted coordinate model can publish several narrow client views;
- future terminal, conversational, documentation, or HTML clients could share the same coordinates without sharing shell control flow.

Costs:

- shell needs a process boundary and a small text protocol;
- exact characters, output markers, unknown-key behavior, and failure publication must be deliberate contracts;
- BQN becomes an operational dependency for menu metadata even when no array calculation is otherwise needed.

### Static TSV/config owner

Strengths:

- already shaped for shell and other thin clients;
- no generation process is required;
- ordering, labels, and families are immediately inspectable;
- the transport and stored representation are the same thing.

Costs:

- alignment and uniqueness need a separate validator;
- richer derived questions may accumulate in consumers;
- adding function relationships or multiple views may turn a simple file into an implicit schema.

### Direct shell ownership

Strengths:

- no process or format boundary;
- mode-specific human interaction remains visible beside its dispatch;
- simplest while only one shell client needs the declarations.

Costs:

- action knowledge is already repeated across help, admission, menu, and dispatch surfaces;
- drift is harder to observe as one portfolio question;
- another client would duplicate the same stable metadata.

## Result

The BQN-to-shell export boundary is **technically clear and viable**, but it is not yet selected for production.

The experiment strengthens the hybrid model:

```text
aligned BQN catalog
  is a strong owner for portfolio structure and validation

narrow exported view
  can cross into shell without exporting BQN namespaces or control flow

shell
  remains the owner of prompting, cancellation, selection tools,
  loops, orchestration, editor invocation, and user-visible timing
```

However, a working boundary is not by itself a reason to activate it. With one terminal client, a small TSV owner or even direct shell declarations may still be the clearer operational choice. A BQN production owner becomes substantially more compelling when either:

- a second real client needs the same admitted action metadata; or
- help, mode admission, menu order, and labels demonstrably drift often enough to justify one generated source.

## New capability

The export demonstrates a possible **action metadata surface** independent of any particular UI toolkit.

That surface could later support:

- terminal selector rows;
- a conversational action chooser;
- generated command documentation;
- a thin HTML presenter;
- capability discovery without exposing editor command construction.

This remains a new capability decision, not an automatic cleanup refactor.

## Destination

- observed experiment: retained;
- production BQN exporter: not selected;
- static TSV/config owner: still a live candidate;
- direct shell ownership: still a live candidate;
- generic BQN-driven interaction choreography: parked;
- revisit signal: a second real metadata client or concrete drift among current shell declarations;
- next useful move: when that signal appears, compare one finite production catalog owner using exact duplicate, unknown-key, ordering, encoding, and unavailable-export failure cases.
