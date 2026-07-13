from pathlib import Path
import re

path = Path('TODO.md')
text = path.read_text()
text = re.sub(
    r'^Last hygiene pass:.*$',
    'Last hygiene pass: 2026-07-13 — verified Currency Mixed-Ledger M2 from PR #198 and selected M2.5 as the next finite production-source checkpoint.',
    text,
    count=1,
    flags=re.M,
)

active = '''### Currency Mixed-Ledger M2.5: Production JPY Source Migration and Strict-Source Checkpoint

Plan: `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`

Verification: `docs/archive/audits/CURRENCY_MIXED_LEDGER_M2_POST_IMPLEMENTATION_VERIFICATION-2026-07-13.md`

Goal:
- 実際の `LEDGER_DATA_DIR` をread-only auditとexact dry-runで確認し、明示承認後にだけ既存JPY sourceの欠落通貨metadataを安全に補完できる状態へ進める。

Allowed:
- actual `LEDGER_DATA_DIR` に対する `tools/currency-setup audit`
- actual `LEDGER_DATA_DIR` に対する `tools/currency-setup dry-run`
- missing / duplicate / unknown currency状態の確認
- exact proposed replacementの人間によるreview
- migration対象件数と対象ファイルの記録
- 明示承認後の別operationとしてのsafe-write migration
- pre-write backup / snapshot-token boundary
- migration後のlint / full checks
- new editor rowが明示的な `currency=` を生成することの再確認
- strict missing-currency enforcementを別sliceとして採否判断するための証拠整理

Not authorized:
- このverification/routing PR内でのproduction source変更
- dry-run確認前の自動apply
- explicit JPY / ILS metadataの上書き
- account名またはFrom/To referenceの変更
- ILSへの推測変換
- legacy compatibility fixtureの削除
- public report / balances / human currency formatting変更
- FX / conversion / valuation
- Currency axis
- mixed aggregation
- M3以降の実装

Exit:
- actual source audit resultが確認される
- dry-run proposalがfile / row単位でreviewされる
- duplicate / unknown / invalid stateが0、またはmigration前に解消される
- production write前に明示承認がある
- migrationは欠落している `currency=JPY` だけを追加する
- first five columns、account names、From/To、row order、empty fields、comments、unrelated metadataが保持される
- pre-write recovery copyが残る
- migration後のlint / full checksがpassする
- migrationを再実行しても追加変更が0になる
- strict missing-currency behaviorは自動有効化せず別判断として残る

'''
pattern = r'### Currency Mixed-Ledger M2: Editor Currency-aware Account and Journal Input\n.*?(?=---\n\n## Next candidates)'
text, count = re.subn(pattern, active, text, count=1, flags=re.S)
if count != 1:
    raise SystemExit('active M2 section replacement failed')

old = 'Mixed-ledger daily-use の後続候補とslice境界は `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md` を参照する。M2.5/M3を自動実装キューとして扱わない。'
new = 'Mixed-ledger daily-use の後続候補とslice境界は `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md` を参照する。M3を自動実装キューとして扱わない。'
if old not in text:
    raise SystemExit('next-candidate routing line not found')
text = text.replace(old, new, 1)
path.write_text(text)
