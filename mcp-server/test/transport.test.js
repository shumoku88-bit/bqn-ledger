'use strict';

const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '../..');
const token = 'test-only-token-00000000000000000000000000000000';

test('Streamable HTTP transport requires auth and exposes constrained tools', async t => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'ledger-mcp-http-')); t.after(() => fs.rm(dir, { recursive: true, force: true }));
  const base = path.join(dir, 'data'); await fs.cp(path.join(root, 'fixtures/demo'), base, { recursive: true });
  const port = 31000 + Math.floor(Math.random() * 1000);
  const child = spawn(process.execPath, ['server.js'], { cwd: path.join(root, 'mcp-server'), env: { ...process.env, LEDGER_DATA_DIR: base, MCP_RUNTIME_DIR: path.join(dir, 'runtime'), MCP_BEARER_TOKEN: token, MCP_PORT: String(port) }, stdio: ['ignore', 'pipe', 'pipe'] });
  let logs = '';
  t.after(() => child.kill('SIGTERM'));
  child.stdout.on('data', x => { logs += x; }); child.stderr.on('data', x => { logs += x; });
  await new Promise((resolve, reject) => { const timer = setTimeout(() => reject(new Error('server start timeout')), 10000); child.stdout.on('data', x => { if (x.toString().includes('listening')) { clearTimeout(timer); resolve(); } }); child.on('exit', code => reject(new Error(`server exited ${code}`))); });
  const url = `http://127.0.0.1:${port}/mcp`;
  const noAuth = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{}' }); assert.equal(noAuth.status, 401);
  async function rpc(body) { const r = await fetch(url, { method: 'POST', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json', accept: 'application/json, text/event-stream' }, body: JSON.stringify(body) }); assert.equal(r.status, 200); return r.json(); }
  const listed = await rpc({ jsonrpc: '2.0', id: 1, method: 'tools/list', params: {} });
  assert.deepEqual(listed.result.tools.map(x => x.name), ['ledger_list_sections', 'ledger_report_section', 'ledger_snapshot', 'ledger_list_accounts', 'ledger_prepare_entry', 'ledger_commit_entry']);
  const before = await fs.readFile(path.join(base, 'actual.journal'), 'utf8');
  const prepared = await rpc({ jsonrpc: '2.0', id: 2, method: 'tools/call', params: { name: 'ledger_prepare_entry', arguments: { date: '2026-02-21', memo: 'Transport fixture', from_account: 'assets:bank', to_account: 'expenses:groceries', amount: 222 } } });
  assert.equal(prepared.result.structuredContent.ok, true); assert.equal(await fs.readFile(path.join(base, 'actual.journal'), 'utf8'), before);
  assert(!logs.includes('Transport fixture')); assert(!logs.includes(token)); assert(!logs.includes('222')); assert(!logs.includes(base));
});
