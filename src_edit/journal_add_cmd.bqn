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
txnid ← •Import "txn_id.bqn"

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
accountRoles ← resolved.roles

currency ← ""
renderMeta ← metaTokens
incomeTxnID ← ""

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
  
  # For journal only
  {𝕊:
    incomeIntent ← ∨´"income_budget=unassigned"⊸≡¨metaTokens
    fromIdx ← ⊑accounts⊐⟨fromVal⟩
    isIncome ← 0
    {𝕊: isIncome ↩ (fromIdx⊑accountRoles)≡"income"}⍟(fromIdx<≠accounts) @
    {𝕊:
      budgetAmountCheck ← validate.ValidateAmount amountVal
      {𝕊: Fail "income_budget=unassigned requires an integer budget amount"}⍟(¬0⊑budgetAmountCheck) @
      explicitTxn ← {"txn_id=" txnid.StartsWith 𝕩}¨metaTokens
      {𝕊: Fail "income_budget=unassigned requires at most one txn_id"}⍟(1<+´explicitTxn) @
      journalLines ← loader.ReadLinesOptional (baseDir ∾ "/" ∾ sys.DefaultJournalFile @)
      existingIDs ← txnid.Extract¨journalLines
      existingIDs ↩ (0<≠¨existingIDs)/existingIDs
      {𝕊: incomeTxnID ↩ 7↓⊑explicitTxn/metaTokens}⍟(1=+´explicitTxn) @
      {𝕊: incomeTxnID ↩ txnid.Generate {date⇐dateVal, memo⇐memoVal, existing_ids⇐existingIDs}}⍟(0=+´explicitTxn) @
      {𝕊: Fail ("duplicate txn_id: "∾incomeTxnID)}⍟(∨´incomeTxnID⊸≡¨existingIDs) @
      renderMeta ↩ ((¬explicitTxn)/metaTokens) ∾ ⟨"txn_id="∾incomeTxnID, "currency=" ∾ currency⟩
    }⍟(incomeIntent ∧ isIncome) @
    {𝕊: Fail "income_budget=unassigned requires a from account with role=income"}⍟(incomeIntent ∧ ¬isIncome) @
    {𝕊: renderMeta ↩ metaTokens ∾ ⟨"currency=" ∾ currency⟩}⍟(¬incomeIntent) @
  }⍟(targetKind ≡ "journal") @

  # For budget only
  {𝕊:
    renderMeta ↩ metaTokens ∾ ⟨"currency=" ∾ currency⟩
  }⍟(targetKind ≡ "budget") @
}⍟((targetKind ≡ "journal") ∨ targetKind ≡ "budget") @

{𝕊 ⋄ Fail (1 ⊑ check)}⍟(¬ 0 ⊑ check) @

row ← render.RenderJournalRow {
  date ⇐ dateVal ⋄ memo ⇐ memoVal ⋄ from ⇐ fromVal ⋄ to ⇐ toVal ⋄
  amount ⇐ amountVal ⋄ meta ⇐ renderMeta
}

header ← "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ targetFile
{𝕊: header ∾↩ tab ∾ incomeTxnID}⍟(0<≠incomeTxnID) @
•Out header
•Out row
