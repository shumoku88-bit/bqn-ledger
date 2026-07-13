from pathlib import Path

core_path = Path('mcp-server/core.js')
core = core_path.read_text()
replacements = [
    (
        "const allText = await this.exec('bqn', ['src_edit/account_list_cmd.bqn', this.baseReal, '']);",
        "const allText = await this.exec('bqn', ['src_edit/account_list_cmd.bqn', this.baseReal, '', 'JPY']);",
    ),
    (
        "const text = await this.exec('bqn', ['src_edit/account_list_cmd.bqn', this.baseReal, role]);",
        "const text = await this.exec('bqn', ['src_edit/account_list_cmd.bqn', this.baseReal, role, 'JPY']);",
    ),
    (
        "const args = ['src_edit/journal_add_cmd.bqn', base, 'journal', candidate.date, candidate.memo, candidate.from_account, candidate.to_account, String(candidate.amount), ...candidate.metadata];",
        "const args = ['src_edit/journal_add_cmd.bqn', base, 'journal', candidate.date, candidate.memo, candidate.from_account, candidate.to_account, String(candidate.amount), 'JPY', ...candidate.metadata];",
    ),
    (
        "const args = ['--base', base, 'journal', 'add', '--date', candidate.date, '--memo', candidate.memo, '--from', candidate.from_account, '--to', candidate.to_account, '--amount', String(candidate.amount)];",
        "const args = ['--base', base, 'journal', 'add', '--date', candidate.date, '--memo', candidate.memo, '--from', candidate.from_account, '--to', candidate.to_account, '--amount', String(candidate.amount), '--currency', 'JPY'];",
    ),
]
for old, new in replacements:
    if old not in core:
        raise SystemExit(f'missing core replacement target: {old}')
    core = core.replace(old, new, 1)
core_path.write_text(core)

test_path = Path('mcp-server/test/core.test.js')
test = test_path.read_text()
old = "assert.equal(draft.tsv_row.split('\\t').length, 6);"
new = "assert.equal(draft.tsv_row.split('\\t').length, 7); assert.match(draft.tsv_row, /\\tcurrency=JPY(?:\\t|$)/);"
if old not in test:
    raise SystemExit('missing MCP row-width assertion')
test_path.write_text(test.replace(old, new, 1))
