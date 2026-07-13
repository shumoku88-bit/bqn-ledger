'use strict';

const { spawn } = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');

const DRAFT_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const SECTION_RE = /^[a-z0-9-]{1,64}$/;
const CONTROL_RE = /[\t\r\n\0]/;

class LedgerError extends Error {
  constructor(code, message, details = {}) { super(message); this.code = code; this.details = details; }
  toJSON() { return { ok: false, error: { code: this.code, message: this.message, ...this.details } }; }
}

async function hashFile(file) {
  const data = await fs.readFile(file);
  return crypto.createHash('sha256').update(data).digest('hex');
}

function runProcess(command, args, { cwd, env, timeoutMs = 60_000, maxOutput = 200_000 } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd, env, shell: false, stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '', stderr = '', bytes = 0, timedOut = false, oversized = false;
    const collect = target => chunk => {
      bytes += chunk.length;
      if (bytes > maxOutput) { oversized = true; child.kill('SIGKILL'); return; }
      if (target === 'out') stdout += chunk; else stderr += chunk;
    };
    child.stdout.on('data', collect('out')); child.stderr.on('data', collect('err'));
    child.on('error', reject);
    const timer = setTimeout(() => { timedOut = true; child.kill('SIGKILL'); }, timeoutMs);
    child.on('close', code => {
      clearTimeout(timer);
      if (timedOut) return reject(new LedgerError('COMMAND_TIMEOUT', 'Ledger operation timed out.'));
      if (oversized) return reject(new LedgerError('OUTPUT_LIMIT', 'Ledger operation exceeded its output limit.'));
      resolve({ code, stdout, stderr });
    });
  });
}

class LedgerCore {
  constructor(options = {}) {
    this.root = path.resolve(options.root || path.join(__dirname, '..'));
    this.baseDir = path.resolve(options.baseDir || process.env.LEDGER_DATA_DIR || path.join(this.root, 'data'));
    this.runtimeDir = path.resolve(options.runtimeDir || process.env.MCP_RUNTIME_DIR || path.join(process.env.XDG_RUNTIME_DIR || path.join(os.homedir(), '.local', 'state'), 'bqn-ledger-mcp'));
    this.ttlMs = options.ttlMs || 10 * 60_000;
    this.now = options.now || (() => Date.now());
    this.runner = options.runner || runProcess;
    this.commitLock = false;
  }

  async init() {
    await fs.mkdir(this.runtimeDir, { recursive: true, mode: 0o700 });
    await fs.chmod(this.runtimeDir, 0o700);
    this.baseReal = await fs.realpath(this.baseDir);
    for (const file of ['accounts.tsv', 'journal.tsv', 'cycle.tsv']) await fs.access(path.join(this.baseReal, file));
    return this;
  }

  async exec(command, args, options = {}) {
    const result = await this.runner(command, args, {
      cwd: this.root,
      env: { ...process.env, LEDGER_DATA_DIR: this.baseReal, NO_COLOR: '1', ...options.env },
      timeoutMs: options.timeoutMs,
      maxOutput: options.maxOutput,
    });
    if (result.code !== 0) throw new LedgerError('LEDGER_VALIDATION_FAILED', 'The BQN/editor operation rejected the request.');
    return result.stdout.trim();
  }

  async report(args, base = this.baseReal) {
    return this.exec(path.join(this.root, 'tools', 'report'), [base, '--no-color', ...args]);
  }

  async listSections() { return this.report(['--list-sections']); }
  async snapshot() { return this.report(['--section', 'snapshot']); }
  async reportSection(section) {
    if (typeof section !== 'string' || !SECTION_RE.test(section)) throw new LedgerError('INVALID_SECTION', 'Invalid report section name.');
    const list = await this.listSections();
    const allowed = new Set(list.split('\n').map(line => line.split('\t')[0]));
    if (!allowed.has(section)) throw new LedgerError('INVALID_SECTION', 'Unknown report section.');
    return this.report(['--section', section]);
  }

  async listAccounts() {
    const allText = await this.exec('bqn', ['src_edit/account_list_cmd.bqn', this.baseReal, '']);
    const all = allText ? allText.split('\n') : [];
    const result = [];
    for (const role of ['asset', 'liability', 'income', 'expense', 'budget']) {
      const text = await this.exec('bqn', ['src_edit/account_list_cmd.bqn', this.baseReal, role]);
      for (const name of text ? text.split('\n') : []) result.push({ name, role });
    }
    const known = new Set(result.map(x => x.name));
    for (const name of all) if (!known.has(name)) result.push({ name, role: 'unknown' });
    return result.sort((a, b) => a.name.localeCompare(b.name, 'en'));
  }

  normalizeCandidate(input) {
    if (!input || typeof input !== 'object' || Array.isArray(input)) throw new LedgerError('INVALID_INPUT', 'Entry candidate must be an object.');
    const required = ['date', 'memo', 'from_account', 'to_account', 'amount'];
    for (const key of required) if (!(key in input)) throw new LedgerError('INVALID_INPUT', `Missing required field: ${key}.`);
    for (const key of ['date', 'memo', 'from_account', 'to_account']) {
      if (typeof input[key] !== 'string' || CONTROL_RE.test(input[key])) throw new LedgerError('INVALID_INPUT', `${key} contains an invalid character or type.`);
    }
    if (!Number.isSafeInteger(input.amount) || input.amount <= 0) throw new LedgerError('INVALID_AMOUNT', 'amount must be a positive safe integer in yen.');
    const metadata = input.metadata ?? [];
    if (!Array.isArray(metadata) || metadata.some(x => typeof x !== 'string' || CONTROL_RE.test(x) || x.length > 512)) {
      throw new LedgerError('INVALID_METADATA', 'metadata must be an array of safe key=value strings.');
    }
    if (metadata.length > 32) throw new LedgerError('INVALID_METADATA', 'Too many metadata fields.');
    return { date: input.date, memo: input.memo, from_account: input.from_account, to_account: input.to_account, amount: input.amount, metadata: [...metadata] };
  }

  async editorCandidate(candidate, base = this.baseReal) {
    const args = ['src_edit/journal_add_cmd.bqn', base, 'journal', candidate.date, candidate.memo, candidate.from_account, candidate.to_account, String(candidate.amount), ...candidate.metadata];
    const out = await this.exec('bqn', args);
    const lines = out.split('\n');
    if (lines.length !== 2 || lines[0] !== 'OK\tAPPEND\tjournal.tsv') throw new LedgerError('EDITOR_PROTOCOL', 'Unexpected editor validation response.');
    return lines[1];
  }

  async fingerprints() {
    return { journal: await hashFile(path.join(this.baseReal, 'journal.tsv')), accounts: await hashFile(path.join(this.baseReal, 'accounts.tsv')), base: crypto.createHash('sha256').update(this.baseReal).digest('hex') };
  }

  async duplicateWarnings(candidate) {
    const text = await fs.readFile(path.join(this.baseReal, 'journal.tsv'), 'utf8');
    const duplicate = text.split(/\n/).some(line => {
      if (!line || line.startsWith('#') || line.startsWith('\\')) return false;
      const f = line.replace(/\r$/, '').split('\t');
      return f.length >= 5 && f[0] === candidate.date && f[1] === candidate.memo && f[2] === candidate.from_account && f[3] === candidate.to_account && f[4] === String(candidate.amount);
    });
    return duplicate ? [{ code: 'POSSIBLE_DUPLICATE', message: 'An exact matching journal entry already exists; confirm whether this receipt is distinct.' }] : [];
  }

  draftPath(id) { return path.join(this.runtimeDir, `${id}.json`); }

  async prepareEntry(input) {
    const candidate = this.normalizeCandidate(input);
    const tsvRow = await this.editorCandidate(candidate);
    const warnings = await this.duplicateWarnings(candidate);
    const fingerprint = await this.fingerprints();
    const draftId = crypto.randomUUID();
    const expiresAt = new Date(this.now() + this.ttlMs).toISOString();
    const draft = { version: 1, draftId, candidate, tsvRow, warnings, fingerprint, expiresAt, used: false };
    await fs.writeFile(this.draftPath(draftId), JSON.stringify(draft), { mode: 0o600, flag: 'wx' });
    return { ok: true, draft_id: draftId, candidate, tsv_row: tsvRow, warnings, validation: { editor: 'accepted', source_unchanged: true }, journal_fingerprint: fingerprint.journal, expires_at: expiresAt };
  }

  async loadDraft(id) {
    if (typeof id !== 'string' || !DRAFT_RE.test(id)) throw new LedgerError('INVALID_DRAFT_ID', 'Invalid draft_id.');
    let draft;
    try { draft = JSON.parse(await fs.readFile(this.draftPath(id), 'utf8')); }
    catch (e) { if (e.code === 'ENOENT') throw new LedgerError('DRAFT_NOT_FOUND', 'Draft not found or already consumed.'); throw e; }
    if (draft.used) throw new LedgerError('DRAFT_USED', 'Draft has already been used.');
    if (Date.parse(draft.expiresAt) <= this.now()) throw new LedgerError('DRAFT_EXPIRED', 'Draft has expired; prepare the entry again.');
    return draft;
  }

  async makePreflightBase() {
    const parent = await fs.mkdtemp(path.join(os.tmpdir(), 'bqn-ledger-mcp-'));
    const base = path.join(parent, 'data'); await fs.mkdir(base);
    for (const name of await fs.readdir(this.baseReal)) if (name.endsWith('.tsv')) await fs.copyFile(path.join(this.baseReal, name), path.join(base, name));
    return { parent, base };
  }

  async applyViaEditor(candidate, base, postCheck = 'lint') {
    const args = ['--base', base, 'journal', 'add', '--date', candidate.date, '--memo', candidate.memo, '--from', candidate.from_account, '--to', candidate.to_account, '--amount', String(candidate.amount)];
    for (const token of candidate.metadata) args.push('--meta', token);
    args.push('--yes', '--post-check', postCheck);
    return this.exec(path.join(this.root, 'tools', 'edit'), args);
  }

  async commitEntry(id) {
    if (this.commitLock) throw new LedgerError('COMMIT_BUSY', 'Another commit is in progress.');
    this.commitLock = true;
    let preflight;
    try {
      const draft = await this.loadDraft(id);
      const current = await this.fingerprints();
      for (const key of ['journal', 'accounts', 'base']) if (current[key] !== draft.fingerprint[key]) throw new LedgerError('STALE_DRAFT', 'Ledger sources changed after prepare; prepare the entry again.');
      if (await this.editorCandidate(draft.candidate) !== draft.tsvRow) throw new LedgerError('STALE_DRAFT', 'The editor no longer accepts the exact prepared row.');

      preflight = await this.makePreflightBase();
      await this.applyViaEditor(draft.candidate, preflight.base, 'lint');
      await this.report(['--section', 'recent'], preflight.base);
      await this.report(['--section', 'snapshot'], preflight.base);

      const before = await fs.readFile(path.join(this.baseReal, 'journal.tsv'), 'utf8');
      await this.applyViaEditor(draft.candidate, this.baseReal, 'none');
      const after = await fs.readFile(path.join(this.baseReal, 'journal.tsv'), 'utf8');
      const expected = before + (before && !before.endsWith('\n') ? '\n' : '') + draft.tsvRow + '\n';
      if (after !== expected) throw new LedgerError('POST_WRITE_MISMATCH', 'Post-write verification did not find exactly one prepared row.');
      await this.report(['--section', 'recent']);
      await this.report(['--section', 'snapshot']);

      draft.used = true; draft.usedAt = new Date(this.now()).toISOString();
      await fs.writeFile(this.draftPath(id), JSON.stringify(draft), { mode: 0o600 });
      return { ok: true, draft_id: id, committed: true, rows_appended: 1, candidate: draft.candidate, validation: { editor: 'accepted', preflight_report: 'passed', post_write_report: 'passed' } };
    } finally {
      if (preflight) await fs.rm(preflight.parent, { recursive: true, force: true });
      this.commitLock = false;
    }
  }
}

module.exports = { LedgerCore, LedgerError, runProcess };
