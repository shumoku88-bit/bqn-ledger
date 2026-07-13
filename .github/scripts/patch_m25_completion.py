from pathlib import Path
import re

path = Path('TODO.md')
text = path.read_text()
text = re.sub(
    r'^Last hygiene pass:.*$',
    'Last hygiene pass: 2026-07-13 — completed and verified the M2.5 production JPY source migration; no next finite mixed-ledger slice is selected.',
    text,
    count=1,
    flags=re.M,
)

active = '''## Active work

No finite mixed-ledger slice is currently selected. M3 and strict-source enforcement remain separate candidates and are not authorized by M2.5 completion.

'''
pattern = r'## Active work\n.*?(?=---\n\n## Next candidates)'
text, count = re.subn(pattern, active, text, count=1, flags=re.S)
if count != 1:
    raise SystemExit('active section replacement failed')

anchor = 'Mixed-ledger daily-use の後続候補とslice境界は `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md` を参照する。M3を自動実装キューとして扱わない。\n\n'
if anchor not in text:
    raise SystemExit('next-candidate anchor missing')
replacement = anchor + '''### Currency Mixed-Ledger M3: Currency-selected balances report

Status: candidate only。M2.5 completion does not authorize implementation.

- public `--currency JPY|ILS` selection
- ledger default when no override is supplied
- visible `Currency view:` line with selection provenance
- `balances` as the first report consumer
- ILS human formatting such as `₪12.50`
- no cross-currency aggregation, FX, JSON widening, or broad report campaign

### Strict production source enforcement

Status: candidate only。Production migration is complete, but legacy compatibility fixtures remain valid until a separate runtime/docs slice is selected.

- decide where missing account/row currency may now fail closed
- preserve explicitly documented compatibility fixtures and migration tests
- do not combine with M3 reporting unless separately justified

'''
text = text.replace(anchor, replacement, 1)
path.write_text(text)
