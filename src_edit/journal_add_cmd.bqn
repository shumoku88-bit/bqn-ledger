# Validate and render a non-actual budget_alloc.tsv append row.
loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
config ← •Import "../src_next/config.bqn"
setup ← •Import "../src_next/currency_setup.bqn"
ak ← •Import "../src_next/account_key.bqn"
sys ← config.LoadSystemDefaults @
args ← •args ⋄ tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
{𝕊: Fail "usage: journal_add_cmd.bqn <baseDir> budget <date> <memo> <from> <to> <amount> <currency-or-empty> [meta...]"}⍟(8>≠args) @
baseDir←0⊑args ⋄ targetKind←1⊑args ⋄ dateVal←2⊑args ⋄ memoVal←3⊑args
fromVal←4⊑args ⋄ toVal←5⊑args ⋄ amountVal←6⊑args ⋄ explicitCurrency←7⊑args ⋄ metaTokens←8↓args
{𝕊: Fail "actual TSV journal add protocol has been removed"}⍟(targetKind≢"budget") @
accountLines←loader.ReadLinesOptional (baseDir∾"/"∾sys.DefaultAccountsFile @)
IsDataLine←{(0<≠𝕩)?((⊑𝕩≠'#')∧(⊑𝕩≠⊑"\\"));0}
resolved←ak.Resolve (IsDataLine¨accountLines)/accountLines
selection←setup.ResolveSelection ⟨setup.ResolveDefault loader.ReadLinesOptional (baseDir∾"/config.tsv"),explicitCurrency⟩
{𝕊: Fail selection.message}⍟(selection.state≢"ok") @
check←validate.ValidateCurrencyJournalAdd {
  date⇐dateVal⋄memo⇐memoVal⋄from⇐fromVal⋄to⇐toVal⋄amount⇐amountVal⋄meta⇐metaTokens⋄
  accounts⇐resolved.accounts⋄account_currencies⇐resolved.currencies⋄currency⇐selection.currency
}
{𝕊: Fail 1⊑check}⍟(¬0⊑check) @
row←render.RenderJournalRow {date⇐dateVal⋄memo⇐memoVal⋄from⇐fromVal⋄to⇐toVal⋄amount⇐amountVal⋄meta⇐metaTokens∾⟨"currency="∾selection.currency⟩}
•Out "OK"∾tab∾"APPEND"∾tab∾sys.DefaultBudgetAllocFile @
•Out row
