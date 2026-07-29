# src_edit/plan_add_cmd.bqn
# Narrow BQN command for experimental `tools/edit-bqn plan add`.
#
# Input args:
#   <baseDir> <date> <memo> <from> <to> <amount> <planID-or-empty> <currency-or-empty> [meta...]
#
# Stdout protocol on success:
#   OK	APPEND	<plan-file>
#   <complete TSV row>

loader ← •Import "../src/application/source_io.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
plan_id ← •Import "plan_id.bqn"
defaults ← •Import "../src/application/system_defaults.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @
editorAccounts ← •Import "../src/application/editor_accounts.bqn"
actual_source ← •Import "../src/application/editor_actual.bqn"

sys ← defaults.Load @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: plan_add_cmd.bqn <baseDir> <date> <memo> <from> <to> <amount> <planID-or-empty> <currency-or-empty> [meta...]"}⍟(8 > ≠ args) @

baseDir ← 0 ⊑ args
dateVal ← 1 ⊑ args
memoVal ← 2 ⊑ args
fromVal ← 3 ⊑ args
toVal ← 4 ⊑ args
amountVal ← 5 ⊑ args
planIdArg ← 6 ⊑ args
explicitCurrency ← 7 ⊑ args
metaTokens ← 8 ↓ args

ResolvePath ← { baseDir ∾ "/" ∾ 𝕩 }

HasPlanIDMeta ← { ∨´ { "plan_id=" plan_id.StartsWith 𝕩 }¨ 𝕩 }
{𝕊 ⋄ Fail "--meta plan_id=... is not allowed; use --id or let plan add generate plan_id"}⍟(HasPlanIDMeta metaTokens) @

accountsPath ← ResolvePath (sys.DefaultAccountsFile @)
accountLines ← loader.ReadLinesOptional accountsPath
IsDataLine ← { (0 < ≠𝕩) ? ((⊑𝕩 ≠ '#') ∧ (⊑𝕩 ≠ ⊑"\\")) ; 0 }
accountDataLines ← (IsDataLine¨ accountLines) / accountLines
resolved ← editorAccounts.Require accountDataLines
accounts ← resolved.key
accountCurrencies ← resolved.currency

configLines ← loader.ReadLinesOptional (baseDir ∾ "/config.tsv")
defaultResult ← setup.ResolveDefault configLines
selection ← setup.ResolveSelection ⟨defaultResult, explicitCurrency⟩
{𝕊: Fail selection.message}⍟(selection.state ≢ "ok") @
currency ← selection.currency

check ← validate.ValidateCurrencyJournalAdd {
  date ⇐ dateVal ⋄ memo ⇐ memoVal ⋄ from ⇐ fromVal ⋄ to ⇐ toVal ⋄
  amount ⇐ amountVal ⋄ meta ⇐ metaTokens ⋄ accounts ⇐ accounts ⋄
  account_currencies ⇐ accountCurrencies ⋄ currency ⇐ currency
}
{𝕊 ⋄ Fail (1 ⊑ check)}⍟(¬ 0 ⊑ check) @

planPath ← ResolvePath (sys.DefaultPlanFile @)
planIDs ← plan_id.ExtractPlanId¨loader.ReadLinesOptional planPath
completionIDs ← {𝕩.plan_id}¨actual_source.CompletionEvidence baseDir
existingIDs ← (0<≠¨planIDs∾completionIDs)/(planIDs∾completionIDs)

finalPlanID ← ""
(0 = ≠ planIdArg) ◶ ⟨
  {𝕊 ⋄
    idCheck ← plan_id.ValidatePlanIDFormat planIdArg
    {𝕊 ⋄ Fail ("invalid plan_id: " ∾ planIdArg)}⍟(¬ 0 ⊑ idCheck) @
    {𝕊 ⋄ Fail ("plan_id already exists: " ∾ planIdArg)}⍟(∨´ planIdArg ⊸ ≡¨ existingIDs) @
    finalPlanID ↩ planIdArg
  },
  {𝕊 ⋄
    finalPlanID ↩ plan_id.GeneratePlanID {
      date ⇐ dateVal ⋄
      memo ⇐ memoVal ⋄
      meta ⇐ metaTokens ⋄
      existing_ids ⇐ existingIDs
    }
  }
⟩ @

finalMeta ← metaTokens ∾ ⟨"plan_id=" ∾ finalPlanID, "currency=" ∾ currency⟩
row ← render.RenderJournalRow {
  date ⇐ dateVal ⋄
  memo ⇐ memoVal ⋄
  from ⇐ fromVal ⋄
  to ⇐ toVal ⋄
  amount ⇐ amountVal ⋄
  meta ⇐ finalMeta
}

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ (sys.DefaultPlanFile @)
•Out row
