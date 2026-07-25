# Working on bqn-ledger

This repository is a place to explore household accounting with plain-text data and BQN.

Read the code and the documents that help with the task at hand. Historical plans and decisions are available for context, but they do not limit present work.

## Development posture

You may:

- question existing designs and module boundaries;
- propose alternatives and explain your preference;
- change related files when that makes the result more coherent;
- build small experiments with public synthetic data;
- report discoveries that were not part of the original request;
- remove or replace structures that have outlived their purpose.

Prefer changes that are understandable, reviewable, and reversible. Use tests, fixtures, and checks where they make behavior clearer. Review the resulting diff and describe the important decisions.

Git preserves earlier versions. A reversible experiment is often more informative than a long permission process.

## Household data

Canonical household data and private user data belong to the user. Work with them under explicit human direction and keep private details out of public commits, issues, fixtures, and reports.

Repository code, documentation, public fixtures, tests, tools, and architecture are open to revision.

## Useful entrances

- `README.md` for running the project
- `docs/ARCHITECTURE.md` for the current data flow
- `docs/AI_CODEMAP.md` for a code map
- `TODO.md` for current notes and open directions
- `tools/check.sh` for the project checks

Follow the evidence in the repository, exercise judgment, and tell moko what you notice.
