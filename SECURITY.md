# Security Policy

## Scope

This repository contains a plain-text ledger/report engine, editor tooling, fixtures, and documentation.

The public `data/` directory and `fixtures/` are sandbox data only. Real household ledger data should live outside this repository and be selected with `LEDGER_DATA_DIR`.

## Reporting a vulnerability

If you find a security issue, please open a GitHub issue with a minimal reproduction that uses sandbox or fixture data only.

Do not include private household data, real account names, personal addresses, screenshots with private financial details, access tokens, API keys, or local paths that identify a private machine.

## Maintainer handling rules

- Treat source TSV files as sensitive when they come from a real `LEDGER_DATA_DIR`.
- Do not request or post real household data in public issues or pull requests.
- Prefer fixture-based reproduction cases.
- Keep changes small enough to review.
- Run `tools/check.sh` for changes that affect report behavior, write paths, or fixtures.

## Current security posture

BQN derives reports and checks from source TSV files. Daily writes go through the BQN editor and shell wrappers, which are intended to preserve reviewable write paths, backups, stale checks, and post-write validation.

This project is not a network service and does not provide authentication, authorization, or hosted storage.
