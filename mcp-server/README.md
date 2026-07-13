# BQN Ledger MCP adapter

Confirmation-gated Streamable HTTP adapter for receipt-entry experiments. The complete contract, threat model, Termux setup, and recovery procedure are in [`../docs/MCP_RECEIPT_ENTRY.md`](../docs/MCP_RECEIPT_ENTRY.md).

```sh
npm ci
npm test
export LEDGER_DATA_DIR=/path/to/private/ledger-data/data
export MCP_BEARER_TOKEN="$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')"
npm start
```

The default endpoint is `http://127.0.0.1:3000/mcp`. It uses Streamable HTTP only; legacy SSE is not implemented. Do not expose this endpoint directly to the internet. Remote ChatGPT use must follow the **Secure MCP Tunnel** path in the operational guide (TLS + ChatGPT-compatible OAuth + exact Host allowlist + independent origin bearer); account-less Quick Tunnels are fixture-only.
