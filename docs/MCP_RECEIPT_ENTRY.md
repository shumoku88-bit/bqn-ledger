# MCP Receipt Entry

Status: current operational guide
Owner: MCP adapter / BQN editor boundary
Canonical: yes
Exit: revise when the MCP tool schema, authentication boundary, or editor commit contract changes

## Purpose and responsibility boundary

This adapter supports a confirmation-gated experiment:

```text
receipt image
  -> ChatGPT image understanding
  -> structured candidate
  -> MCP prepare
  -> human review
  -> MCP commit by draft_id
  -> BQN validation and reports
```

The server does **not** receive, upload, store, or OCR images. ChatGPT owns image understanding. MCP starts at the structured candidate and remains a thin adapter over the BQN report engine and BQN editor.

## Tools

Read-only tools:

- `ledger_list_sections()` — canonical section list from `tools/report --list-sections`.
- `ledger_report_section({section})` — one section selected from that list.
- `ledger_snapshot()` — canonical BQN snapshot.
- `ledger_list_accounts()` — minimal `{name, role}` account candidates from the BQN account-list path.
- `ledger_prepare_entry({date,memo,from_account,to_account,amount,metadata?})` — validates and creates a draft without modifying source files.

Write tool:

- `ledger_commit_entry({draft_id})` — appends exactly the previously prepared row. No entry fields or paths are accepted.

`amount` is a positive safe integer in yen. `metadata` is an optional array of existing `key=value` tokens, for example `['receipt=demo-reference','party=example']`. Multiple receipt categories are prepared and confirmed separately.

## Prepare/commit contract

`ledger_prepare_entry`:

1. rejects unsafe types, non-positive/non-integer amounts, and TAB/LF/CR/NUL;
2. delegates date, account, metadata, and native transaction-block validation/rendering to `src_edit/journal_block_add_cmd.bqn`;
3. checks exact duplicate coordinates and returns `POSSIBLE_DUPLICATE` as a warning;
4. fingerprints the configured native Journal, `accounts.tsv`, and the resolved base identity;
5. stores a single-use draft outside the source directory with mode `0600` in a mode `0700` runtime directory;
6. returns the exact candidate, native Journal block, warning list, journal fingerprint, and expiration time.

A draft expires after ten minutes by default. A human must compare the receipt and exact preview before authorizing commit.

`ledger_commit_entry`:

1. accepts only a UUID `draft_id` and cannot resolve arbitrary paths;
2. rejects missing, used, or expired drafts;
3. rechecks base identity and journal/accounts fingerprints;
4. asks the BQN editor to render the exact native Journal block again and compares it byte-for-byte;
5. copies the configured Journal and base TSV files to a temporary private directory and runs the approved editor append plus native validation, recent-journal, and snapshot there;
6. invokes `tools/edit journal add --yes --post-check none` on the selected base, reusing its backup, stale check, and atomic append;
7. verifies that the resulting Journal is exactly the old bytes plus one prepared transaction block;
8. runs recent-journal and snapshot reports, then marks the draft used.

Validation and stale failures are fail-closed. The editor backup remains the recovery source. A process/device failure after the atomic append but before the draft is marked used is an operational ambiguity: inspect the journal/backup and prepare again; do not blindly retry commit.

## Data and runtime locations

Real source data remains outside this public repository:

```sh
export LEDGER_DATA_DIR="$HOME/ledger-data/data"
```

Drafts default to `${XDG_RUNTIME_DIR:-$HOME/.local/state}/bqn-ledger-mcp`. Override with `MCP_RUNTIME_DIR`; never place it under `LEDGER_DATA_DIR`. Draft JSON contains the proposed entry and is sensitive. Server logs record error codes only, not request bodies, report text, journal rows, amounts, paths, or tokens.

## Safe Termux startup

```sh
cd "$HOME/bqn-ledger/mcp-server"
npm ci
export LEDGER_DATA_DIR="$HOME/ledger-data/data"
export MCP_BEARER_TOKEN="$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')"
npm start
```

Defaults bind only `127.0.0.1:3000`. Endpoint: `http://127.0.0.1:3000/mcp` using Streamable HTTP; legacy SSE is not provided. Stop with `Ctrl-C` or terminate the recorded service PID.

For prepare-only/dry-run operation, use all read tools and `ledger_prepare_entry`, but do not call `ledger_commit_entry`.

## Remote use and authentication

### Recommended path: Secure MCP Tunnel

For ChatGPT remote use, the supported operational path is a **Secure MCP Tunnel**: a TLS tunnel with an OAuth-capable authorization boundary in front of the loopback-only MCP origin.

```text
ChatGPT
  -> public HTTPS / OAuth authorization
  -> Secure MCP Tunnel
  -> 127.0.0.1:3000/mcp (mandatory origin bearer)
  -> BQN MCP adapter
```

Required properties:

1. keep the MCP process bound to `127.0.0.1`; never expose port 3000 directly;
2. require an authentication flow supported by ChatGPT at the public boundary (normally OAuth);
3. keep the independent origin `MCP_BEARER_TOKEN` secret between the trusted tunnel/proxy and MCP server;
4. set `MCP_ALLOWED_HOSTS` to the exact public hostname rather than a wildcard;
5. publish only `/mcp` and the minimal health endpoint needed operationally;
6. rotate credentials and stop the tunnel immediately if a URL or credential leaks;
7. test read tools first, then one real prepare without commit, and only then one explicitly confirmed commit.

An account-less TryCloudflare Quick Tunnel is suitable only for anonymous fixture connectivity experiments. It has no uptime guarantee or stable hostname and must **not** expose a real `LEDGER_DATA_DIR`, even briefly. A random URL is not authentication.

The built-in bearer gate is mandatory and intended for localhost clients or a trusted authenticated reverse proxy. It is defense in depth, not a replacement for ChatGPT-compatible OAuth. A TLS tunnel alone does not make authentication optional.

`.env.example` contains placeholders only. Never commit tokens, tunnel credentials, drafts, real reports, receipts, or real account data.

## Threat model

Defended boundaries include command injection (no shell execution), path traversal (no path tool inputs and strict draft UUIDs), arbitrary report selection (canonical allowlist), stale writes, account drift, replayed/expired drafts, oversized output, long-running commands, unauthenticated HTTP calls, and accidental source writes during prepare. Express' bounded JSON parser limits request bodies.

The operator remains responsible for device security, tunnel/OAuth configuration, ChatGPT data handling, token rotation, Android process lifetime, and reviewing every receipt candidate.

## Non-goals

- OCR, image storage, or receipt uploads
- automatic account classification
- balance/accounting reimplementation in JavaScript
- batch commits
- journal edit/delete/reversal through MCP
- plan, budget, account, cycle, config, or issue mutation
- hosted storage, multi-user service, or unattended bookkeeping

## Recovery

On prepare failure, no source data changed. On stale failure, prepare again. On editor failure, inspect its diagnostic and backup; do not hand-edit through MCP. If power/process loss makes commit status unclear, inspect the exact journal row and `.backup` before taking further action. Rotate a leaked token and stop the tunnel immediately.
