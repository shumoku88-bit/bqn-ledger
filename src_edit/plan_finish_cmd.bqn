# Prepare one canonical Plan completion intent.
# Plan selection comes from strict plan.journal admission. Completion does not
# rewrite Plan source; it publishes one Actual transaction carrying plan-id.

lib ← •Import "../src/text/parse.bqn"
planSource ← •Import "../src/application/plan_source_adapter.bqn"
actualSource ← •Import "../src/application/editor_actual.bqn"
validate ← •Import "validate.bqn"
decimal ← •Import "../src/ledger/exact_decimal.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}

{𝕊:Fail "usage: plan_finish_cmd.bqn <baseDir> <index> <planId> <actualDate> <actualAmount>"}⍟(5≠≠args) @
baseDir ← 0⊑args
indexVal ← lib.ToNum 1⊑args
idVal ← 2⊑args
actualDate ← 3⊑args
actualAmount ← 4⊑args
{𝕊:Fail "must specify Plan using --index or --id"}⍟((indexVal≤0) ∧ 0=≠idVal) @

dateCheck ← validate.ValidateDate actualDate
{𝕊:Fail 1⊑dateCheck}⍟(¬0⊑dateCheck) @

planResult ← planSource.Load ⟨baseDir,setup.registry⟩
{𝕊:Fail "canonical plan.journal rejected"}⍟(planResult.state≢"ok") @
facts ← planResult.facts
transactionCount ← facts.transactions.count
transactionIndices ← ↕transactionCount
planIDs ← facts.transactions.plan_id
completionEvidence ← actualSource.CompletionEvidence baseDir
completionIDs ← {𝕩.plan_id}¨completionEvidence
closedMask ← {Contains ⟨𝕩,completionIDs⟩}¨planIDs
openIndices ← (¬closedMask)/transactionIndices

byIndex ← indexVal>0
selectedIndex ← byIndex ◶ ⟨
  {𝕊:
    matches ← {idVal≡𝕩⊑planIDs}¨openIndices
    {𝕊:Fail ("plan_id not found or already completed: "∾idVal)}⍟(1≠+´matches) @
    ⊑matches/openIndices
  },
  {𝕊:
    {𝕊:Fail ("invalid plan index: "∾•Fmt indexVal∾" (available: 1-"∾•Fmt ≠openIndices∾")")}⍟((indexVal<1) ∨ indexVal>≠openIndices) @
    (indexVal-1)⊑openIndices
  }
⟩ @

targetPlanID ← selectedIndex⊑planIDs
{𝕊:Fail ("plan_id already completed: "∾targetPlanID)}⍟(Contains ⟨targetPlanID,completionIDs⟩) @
postingMask ← selectedIndex=facts.postings.transaction_index
postingIndices ← postingMask/↕facts.postings.count
postingCount ← ≠postingIndices
selectedCoefficients ← postingIndices⊏facts.postings.source_coefficient
selectedAccounts ← (postingIndices⊏facts.postings.account_index)⊏facts.accounts.key
originalAmountTexts ← postingIndices⊏facts.postings.amount_text
currency ← (selectedIndex⊑facts.transactions.domain_index)⊑facts.domains.code
description ← selectedIndex⊑facts.transactions.description

hasOverride ← 0<≠actualAmount
{𝕊:
  {𝕊:Fail "actual amount override requires exactly two Plan Postings"}⍟(2≠postingCount) @
  amountCheck ← validate.ValidateExactAmountForCurrency currency‿actualAmount
  {𝕊:Fail 1⊑amountCheck}⍟(¬0⊑amountCheck) @
  parsed ← decimal.Parse actualAmount
  {𝕊:Fail "actual amount must be strictly positive"}⍟((parsed.state≢"ok") ∨ parsed.coefficient≤0) @
}⍟hasOverride @
replacementAmountTexts ← {𝕊 coefficient: ((coefficient<0)/"-")∾actualAmount}¨selectedCoefficients
actualAmountTexts ← hasOverride ◶ ⟨{originalAmountTexts},{replacementAmountTexts}⟩ @
postingTokens ← {𝕊 i: (i⊑selectedAccounts)∾"="∾i⊑actualAmountTexts}¨↕postingCount

•Out "OK"∾tab∾"PLAN_FINISH"∾tab∾targetPlanID∾tab∾actualDate∾tab∾currency∾tab∾(•Fmt postingCount)∾tab∾description
{𝕊 posting: •Out "P"∾tab∾posting}¨postingTokens