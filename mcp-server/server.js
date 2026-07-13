#!/usr/bin/env node
'use strict';

const path = require('node:path');
const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js');
const { StreamableHTTPServerTransport } = require('@modelcontextprotocol/sdk/server/streamableHttp.js');
const { createMcpExpressApp } = require('@modelcontextprotocol/sdk/server/express.js');
const z = require('zod/v4');
const { LedgerCore, LedgerError } = require('./core.js');

const HOST = process.env.MCP_HOST || '127.0.0.1';
const PORT = Number(process.env.MCP_PORT || 3000);
const TOKEN = process.env.MCP_BEARER_TOKEN;
const ALLOWED_HOSTS = process.env.MCP_ALLOWED_HOSTS?.split(',').map(x => x.trim()).filter(Boolean);
if (!TOKEN || TOKEN.length < 32) {
  console.error('MCP_BEARER_TOKEN must contain at least 32 characters.');
  process.exit(1);
}

function response(value) { return { content: [{ type: 'text', text: JSON.stringify(value) }], structuredContent: value }; }
function failure(error) {
  const safe = error instanceof LedgerError ? error.toJSON() : { ok: false, error: { code: 'INTERNAL_ERROR', message: 'The ledger operation failed.' } };
  console.error(`MCP operation failed: ${safe.error.code}`);
  return { isError: true, ...response(safe) };
}

async function makeServer(core) {
  const server = new McpServer({ name: 'bqn-ledger', version: '0.2.0' });
  const tool = (name, description, inputSchema, handler, annotations = { readOnlyHint: true }) => server.registerTool(name, { description, inputSchema, annotations }, async args => {
    try { return response(await handler(args)); } catch (error) { return failure(error); }
  });

  tool('ledger_list_sections', 'List canonical BQN report sections.', {}, async () => ({ ok: true, sections: await core.listSections() }));
  tool('ledger_report_section', 'Read one allowlisted canonical BQN report section.', { section: z.string().min(1).max(64) }, async ({ section }) => ({ ok: true, section, report: await core.reportSection(section) }));
  tool('ledger_snapshot', 'Read the canonical BQN snapshot without recalculation in MCP.', {}, async () => ({ ok: true, report: await core.snapshot() }));
  tool('ledger_list_accounts', 'List account names and roles required to prepare an entry.', {}, async () => ({ ok: true, accounts: await core.listAccounts() }));
  tool('ledger_prepare_entry', 'Validate and save a short-lived receipt entry draft without modifying source TSV.', {
    date: z.string(), memo: z.string(), from_account: z.string(), to_account: z.string(), amount: z.number(), metadata: z.array(z.string()).optional(),
  }, async input => core.prepareEntry(input));
  tool('ledger_commit_entry', 'Commit exactly one previously prepared draft. Human confirmation is required before calling.', { draft_id: z.string() }, async ({ draft_id }) => core.commitEntry(draft_id), { readOnlyHint: false, destructiveHint: false, idempotentHint: false });
  return server;
}

(async () => {
  const core = await new LedgerCore({ root: path.join(__dirname, '..') }).init();
  const app = createMcpExpressApp({ host: HOST, allowedHosts: ALLOWED_HOSTS });
  app.get('/health', (_req, res) => res.json({ ok: true, service: 'bqn-ledger' }));
  app.use('/mcp', (req, res, next) => {
    if (req.get('authorization') !== `Bearer ${TOKEN}`) return res.set('WWW-Authenticate', 'Bearer').status(401).json({ error: 'unauthorized' });
    next();
  });
  app.post('/mcp', async (req, res) => {
    const server = await makeServer(core);
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
    try { await server.connect(transport); await transport.handleRequest(req, res, req.body); }
    catch { if (!res.headersSent) res.status(500).json({ error: 'internal_error' }); }
    finally { res.on('close', () => { transport.close(); server.close(); }); }
  });
  app.all('/mcp', (_req, res) => res.status(405).set('Allow', 'POST').send('Method Not Allowed'));
  app.listen(PORT, HOST, error => {
    if (error) throw error;
    console.log(`BQN Ledger MCP listening on http://${HOST}:${PORT}/mcp`);
  });
})().catch(error => { console.error(`MCP startup failed: ${error.code || 'INTERNAL_ERROR'}`); process.exit(1); });
