'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const crypto = require('node:crypto');
const { LedgerCore, LedgerError } = require('../core.js');

const root = path.resolve(__dirname, '../..');
const good = { date: '2026-02-21', memo: 'Anonymous shop', from_account: 'assets:bank', to_account: 'expenses:groceries', amount: 321, metadata: ['receipt=demo-001'] };
async function setup(options = {}) {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'ledger-mcp-test-'));
  const base = path.join(dir, 'data'); const runtime = path.join(dir, 'runtime');
  await fs.cp(path.join(root, 'fixtures/demo'), base, { recursive: true });
  const core = await new LedgerCore({ root, baseDir: base, runtimeDir: runtime, ...options }).init();
  return { dir, base, runtime, core, cleanup: () => fs.rm(dir, { recursive: true, force: true }) };
}
async function sha(file) { return crypto.createHash('sha256').update(await fs.readFile(file)).digest('hex'); }
async function tsvHashes(base) { const out = {}; for (const x of await fs.readdir(base)) if (x.endsWith('.tsv')) out[x] = await sha(path.join(base, x)); return out; }
async function rejectsCode(promise, code) { await assert.rejects(promise, e => e instanceof LedgerError && e.code === code); }

test('read tools and prepare do not modify source TSV', async t => {
  const s = await setup(); t.after(s.cleanup); const before = await tsvHashes(s.base);
  assert.match(await s.core.listSections(), /snapshot/); assert.match(await s.core.snapshot(), /Snapshot/); assert.match(await s.core.reportSection('recent'), /Recent Journal/);
  const accounts = await s.core.listAccounts(); assert(accounts.some(x => x.name === 'assets:bank' && x.role === 'asset'));
  const draft = await s.core.prepareEntry(good); assert.match(draft.draft_id, /^[0-9a-f-]{36}$/); assert.equal(draft.validation.editor, 'accepted'); assert.equal(draft.tsv_row.split('\t').length, 6);
  assert.deepEqual(await tsvHashes(s.base), before); assert.equal((await fs.stat(path.join(s.runtime, `${draft.draft_id}.json`))).mode & 0o777, 0o600);
});

test('prepare rejects unknown account and invalid amount forms', async t => {
  const s = await setup(); t.after(s.cleanup);
  await rejectsCode(s.core.prepareEntry({ ...good, to_account: 'expenses:missing' }), 'LEDGER_VALIDATION_FAILED');
  for (const amount of [0, -1, 1.5, '100', NaN]) await rejectsCode(s.core.prepareEntry({ ...good, amount }), 'INVALID_AMOUNT');
});

test('prepare rejects control characters, invalid dates, and metadata', async t => {
  const s = await setup(); t.after(s.cleanup);
  for (const memo of ['bad\tmemo', 'bad\nmemo', 'bad\0memo']) await rejectsCode(s.core.prepareEntry({ ...good, memo }), 'INVALID_INPUT');
  await rejectsCode(s.core.prepareEntry({ ...good, date: '2026-02-30' }), 'LEDGER_VALIDATION_FAILED');
  for (const metadata of [['missing-equals'], ['Bad=value'], ['note=bad\nvalue'], 'note=x']) {
    const code = typeof metadata === 'string' || metadata[0]?.includes('\n') ? 'INVALID_METADATA' : 'LEDGER_VALIDATION_FAILED';
    await rejectsCode(s.core.prepareEntry({ ...good, metadata }), code);
  }
});

test('exact duplicate is a warning, not an automatic rejection', async t => {
  const s = await setup(); t.after(s.cleanup);
  const r = await s.core.prepareEntry({ date: '2026-02-20', memo: 'Groceries', from_account: 'assets:bank', to_account: 'expenses:groceries', amount: 11000, metadata: [] });
  assert.equal(r.warnings[0].code, 'POSSIBLE_DUPLICATE');
});

test('commit appends exactly one prepared row and reports pass', async t => {
  const s = await setup(); t.after(s.cleanup); const file = path.join(s.base, 'journal.tsv'); const before = (await fs.readFile(file, 'utf8')).split('\n').length;
  const draft = await s.core.prepareEntry(good); const result = await s.core.commitEntry(draft.draft_id); const text = await fs.readFile(file, 'utf8');
  assert.equal(result.rows_appended, 1); assert.equal(text.split('\n').length, before + 1); assert.equal(text.trimEnd().split('\n').at(-1), draft.tsv_row); assert.equal(result.validation.post_write_report, 'passed');
});

test('stale journal rejects commit without prepared row', async t => {
  const s = await setup(); t.after(s.cleanup); const draft = await s.core.prepareEntry(good); const file = path.join(s.base, 'journal.tsv'); await fs.appendFile(file, '# concurrent change\n');
  await rejectsCode(s.core.commitEntry(draft.draft_id), 'STALE_DRAFT'); assert(!((await fs.readFile(file, 'utf8')).includes(draft.tsv_row)));
});

test('used, expired, malformed and traversal draft IDs are rejected', async t => {
  let now = Date.parse('2026-07-12T00:00:00Z'); const s = await setup({ now: () => now, ttlMs: 1000 }); t.after(s.cleanup);
  const used = await s.core.prepareEntry(good); await s.core.commitEntry(used.draft_id); await rejectsCode(s.core.commitEntry(used.draft_id), 'DRAFT_USED');
  const expired = await s.core.prepareEntry({ ...good, memo: 'Expiry test' }); now += 1001; await rejectsCode(s.core.commitEntry(expired.draft_id), 'DRAFT_EXPIRED');
  for (const id of ['bad', '../journal.tsv', '00000000-0000-4000-8000-000000000000/../../x']) await rejectsCode(s.core.commitEntry(id), 'INVALID_DRAFT_ID');
});

test('BQN/editor validation failure never appends', async t => {
  const s = await setup(); t.after(s.cleanup); const file = path.join(s.base, 'journal.tsv'); const before = await sha(file);
  const original = s.core.editorCandidate.bind(s.core); s.core.editorCandidate = async () => { throw new LedgerError('LEDGER_VALIDATION_FAILED', 'injected'); };
  await rejectsCode(s.core.prepareEntry(good), 'LEDGER_VALIDATION_FAILED'); assert.equal(await sha(file), before); s.core.editorCandidate = original;
});

test('section and draft inputs cannot execute commands or read outside base', async t => {
  const s = await setup(); t.after(s.cleanup); const marker = path.join(s.dir, 'owned');
  for (const section of ['../../etc/passwd', `snapshot;touch${marker}`, '/etc/passwd']) await rejectsCode(s.core.reportSection(section), 'INVALID_SECTION');
  await rejectsCode(s.core.commitEntry('../../outside'), 'INVALID_DRAFT_ID'); await assert.rejects(fs.access(marker));
  const response = await s.core.listAccounts(); assert(!JSON.stringify(response).includes(s.dir));
});
