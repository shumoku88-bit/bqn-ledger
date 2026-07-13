# src_edit/journal_add_cmd.bqn
# Narrow BQN command for `tools/edit-bqn journal add` and `budget add`.
#
# Input args:
#   <baseDir> <targetKind: journal|budget> <date> <memo> <from> <to>
#   <amount> <currency-or-empty> [meta...]
#
# Journal M2 behavior:
# - resolve explicit currency or ledger DEFAULT_CURRENCY
# - validate exact-decimal amount and ILS maximum two fractional digits
# - require From/To account currencies to match
# - append an explicit editor-owned currency= token
#
# Budget behavior remains integer-only and currency-neutral in this slice.

loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
config ← •Import "../src_next/config.bqn"
setup ← •Import "../src_next/currency_setup.bqn"
ak ← •Import "../src_next/account_key.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: journal_add_cmd.bqn <baseDir> <targetKind: journal|budget> <date> <memo> <from> <to> <amount> <currency-or-empty> [meta...]"}⍟(8 > ≠ args) @

baseDir ← 0 ⊑ args
targetKind ← 1 ⊑ args
dateVal ← 2 ⊑ args
memoVal ← 3 ⊑ args
fromVal ← 4 ⊑ args
toVal ← 5 ⊑ args
amountVal ← 6 ⊑ args
explicitCurrency ← 7 ⊑ args
metaTokens ← 8 ↓ args

validTargetKind ← ∨´ targetKind ⊸ ≡¨ "journal"‿"budget"
{𝕊 ⋄ Fail ("invalid target kind: " ∾ targetKind)}⍟(¬ validTargetKind) @
targetFile ← (targetKind ≡ "budget") ◶ ⟨ {𝕊 ⋄ sys.DefaultJournalFile @}, {𝕊 ⋄ sys.DefaultBudgetAllocFile @} ⟩ @

accountsPath ← baseDir ∾ "/" ∾ (sys.DefaultAccountsFile @)
accountLines ← loader.ReadLinesOptional accountsPath
IsDataLine ← { (0 < ≠𝕩) ? ((⊑𝕩 ≠ '#') ∧ (⊑𝕩 ≠ ⊑"\\")) ; 0 }
accountDataLines ← (IsDataLine¨ accountLines) / accountLines
resolved ← ak.Resolve accountDataLines
accounts ← resolved.accounts
accountCurrencies ← resolved.currencies

currency ← ""
renderMeta ← metaTokens

check ← validate.ValidateJournalLikeAdd {
  date ⇐ dateVal ⋄ memo ⇐ memoVal ⋄ from ⇐ fromVal ⋄ to ⇐ toVal ⋄
  amount ⇐ amountVal ⋄ meta ⇐ metaTokens ⋄ accounts ⇐ accounts
}

{𝕊:
  configLines ← loader.ReadLinesOptional (baseDir ∾ "/config.tsv")
  defaultResult ← setup.ResolveDefault configLines
  selection ← setup.ResolveSelection ⟨defaultResult, explicitCurrency⟩
  {𝕊: Fail selection.message}⍟(selection.state ≢ "ok") @
  currency ↩ selection.currency

  check ↩ validate.ValidateCurrencyJournalAdd {
    date ⇐ dateVal ⋄ memo ⇐ memoVal ⋄ from ⇐ fromVal ⋄ to ⇐ toVal ⋄
    amount ⇐ amountVal ⋄ meta ⇐ metaTokens ⋄ accounts ⇐ accounts ⋄
    account_currencies ⇐ accountCurrencies ⋄ currency ⇐ currency
  }
  renderMeta ↩ metaTokens ∾ ⟨"currency=" ∾ currency⟩
}⍟(targetKind ≡ "journal") @

{𝕊 ⋄ Fail (1 ⊑ check)}⍟(¬ 0 ⊑ check) @

row ← render.RenderJournalRow {
  date ⇐ dateVal ⋄ memo ⇐ memoVal ⋄ from ⇐ fromVal ⋄ to ⇐ toVal ⋄
  amount ⇐ amountVal ⋄ meta ⇐ renderMeta
}

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ targetFile
•Out row
