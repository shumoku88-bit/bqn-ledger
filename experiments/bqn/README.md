# BQN experiments

This directory is an optional scratchpad for trying BQN expressions and representations before a production decision.

Experiments are not production owners. Production code must not import them, and synthetic/public evidence must be used rather than private Household data.

## Retention after a decision

An experiment does not become permanent repository architecture merely because it was useful.

After review:

- if the idea is promoted into production, retire the executable candidate/probe and its dedicated CI once current production tests own the law;
- if the experiment demonstrates why a plausible form should **not** be adopted, keep it when that negative evidence remains useful and still matches current production;
- if neither the code nor the observation explains a current decision, remove it and rely on Git history.

Historical experiment implementations must not remain as second candidate owners beside the production implementation.

## Current retained evidence

`matrix_result_cells_rank.bqn` and `matrix_result_cells_rank.md` are retained negative evidence: the Cells/Rank rewrite preserved behavior but made the small fixed-field `matrix_result` assembly less clear, and current production still intentionally uses the simpler Each-based form.

The earlier action-catalog and sparse classify-once probes were retired after their useful ideas were promoted into current production owners. Their full experimental history remains available in Git history and the cross-cutting reachability audit record.
