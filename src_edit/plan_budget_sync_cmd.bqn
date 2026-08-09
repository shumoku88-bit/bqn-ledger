# Derive one canonical Budget movement intent from admitted Plan, Actual, and
# Household policy evidence, then use the shared Budget candidate owner.
# Output is APPEND budget.journal, APPLIED, or NOT_LINKED.

io ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
sources ← •Import "../src/application/report_source_adapter.bqn"
candidate ← •Import "budget_movement_candidate.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}

{𝕊:Fail "usage: plan_budget_sync_cmd.bqn <baseDir> <planId>"}⍟(2≠≠args) @
base ← 0⊑args
planID ← 1⊑args

accountResult ← accountSource.Load base
{𝕊:Fail "canonical accounts.journal rejected"}⍟(accountResult.state≢"ok") @
accounts ← accountResult.accounts
context ← sources.Companions ⟨base,accounts,setup.registry⟩
{𝕊:Fail "canonical Plan/Budget/Household evidence rejected"}⍟(context.state≢"ok") @
actualResult ← sources.CanonicalActual ⟨base,setup.registry⟩
{𝕊:Fail "canonical Actual evidence rejected"}⍟(actualResult.state≢"ok") @
plan ← context.plan
actual ← actualResult.facts
budget ← context.budget
household ← context.household

planMatches ← planID⊸≡¨plan.transactions.plan_id
actualMatches ← planID⊸≡¨actual.transactions.plan_id
{𝕊:Fail "plan_id must identify exactly one canonical Plan transaction"}⍟(1≠+´planMatches) @
{𝕊:Fail "plan_id must identify exactly one completed canonical Actual transaction"}⍟(1≠+´actualMatches) @
planIndex ← ⊑planMatches/plan.transactions.index
actualIndex ← ⊑actualMatches/actual.transactions.index

PlanPostingColumn ← {𝕊 column: (planIndex=plan.postings.transaction_index)/column}
ActualPostingColumn ← {𝕊 column: (actualIndex=actual.postings.transaction_index)/column}
planAccounts ← PlanPostingColumn plan.postings.account_index
actualAccounts ← ActualPostingColumn actual.postings.account_index
planSigns ← ×PlanPostingColumn plan.postings.coefficient
actualSigns ← ×ActualPostingColumn actual.postings.coefficient
{𝕊:Fail "completed Actual Posting accounts/order do not match the canonical Plan"}⍟(planAccounts≢actualAccounts) @
{𝕊:Fail "completed Actual Posting directions do not match the canonical Plan"}⍟(planSigns≢actualSigns) @
planDomain ← (planIndex⊑plan.transactions.domain_index)⊑plan.domains.code
actualDomain ← (actualIndex⊑actual.transactions.domain_index)⊑actual.domains.code
{𝕊:Fail "completed Actual Commodity does not match the canonical Plan"}⍟(planDomain≢actualDomain) @

# Envelope axis is Household source order. Each cell contains the Plan
# destination Account axis for one envelope; exactly one selected Plan Posting may
# supply one movement intent. Empty cells and an unmatched Plan are NOT_LINKED.
destinationCells ← household.budget.plan_destination_account_indices
envelopeMask ← {𝕊 cell: ∨´0∾{Contains ⟨𝕩,cell⟩}¨planAccounts}¨destinationCells
{𝕊:•Out "OK"∾tab∾"NOT_LINKED"∾tab∾planID ⋄ •Exit 0}⍟(0=+´envelopeMask) @
{𝕊:Fail "Plan transaction maps to more than one Budget envelope"}⍟(1≠+´envelopeMask) @
envelopeIndex ← ⊑envelopeMask/↕household.budget.envelope_count
destinationCell ← envelopeIndex⊑destinationCells
mappedPostingMask ← {Contains ⟨𝕩,destinationCell⟩}¨planAccounts
{𝕊:Fail "Plan Budget sync requires exactly one mapped destination Posting"}⍟(1≠+´mappedPostingMask) @
mappedPostingIndex ← ⊑mappedPostingMask/↕≠planAccounts
actualCoefficients ← ActualPostingColumn actual.postings.coefficient
actualAmountTexts ← ActualPostingColumn actual.postings.amount_text
{𝕊:Fail "Plan Budget sync destination amount must be exact and positive"}⍟(0≥mappedPostingIndex⊑actualCoefficients) @
amount ← mappedPostingIndex⊑actualAmountTexts

fromAccount ← envelopeIndex⊑household.budget.allocation_account_key
spentMask ← "spent"⊸≡¨household.account_policy.budget_kind
{𝕊:Fail "Household policy must identify exactly one spent Budget Account"}⍟(1≠+´spentMask) @
toAccount ← ⊑spentMask/accounts.key
actualEvent ← actualIndex⊑actual.transactions.transaction_id
actualIdentity ← actualIndex⊑actual.transactions.identity_kind
date ← actualIndex⊑actual.transactions.date_text
description ← "Plan completion Budget sync: "∾planID
# Preserve a direct Actual reference when one exists. Identity-free canonical
# completions remain durably joined through their unique plan-id instead of
# inventing an event-id that is absent from actual.journal.
metadata ← ⟨
  {key⇐"layer",value⇐"budget"},
  {key⇐"event-id",value⇐"budget-sync-"∾planID},
  {key⇐"plan-id",value⇐planID}
⟩
{𝕊:metadata∾↩⟨{key⇐"actual-event-id",value⇐actualEvent}⟩}⍟(actualIdentity≡"durable") @
intent ← {
  date⇐date,description⇐description,from_account⇐fromAccount,to_account⇐toAccount,
  amount⇐amount,currency⇐actualDomain,metadata⇐metadata
}

budgetMatches ← planID⊸≡¨budget.transactions.plan_id
{𝕊:Fail "duplicate canonical Budget linkage for plan_id"}⍟(1<+´budgetMatches) @
{𝕊:
  budgetIndex ← ⊑budgetMatches/budget.transactions.index
  PostingColumn ← {𝕊 column: (budgetIndex=budget.postings.transaction_index)/column}
  accountKeys ← (PostingColumn budget.postings.account_index)⊏budget.accounts.key
  amountTexts ← PostingColumn budget.postings.amount_text
  domain ← (budgetIndex⊑budget.transactions.domain_index)⊑budget.domains.code
  observedMetadata ← {𝕩.key∾"="∾𝕩.value}¨budgetIndex⊑budget.transactions.metadata
  expectedMetadata ← {𝕩.key∾"="∾𝕩.value}¨metadata
  exact ← (budgetIndex⊑budget.transactions.date_text)≡date
  exact ∧↩ (budgetIndex⊑budget.transactions.description)≡description
  exact ∧↩ accountKeys≡fromAccount‿toAccount
  exact ∧↩ amountTexts≡("-"∾amount)‿amount
  exact ∧↩ domain≡actualDomain
  exact ∧↩ observedMetadata≡expectedMetadata
  {𝕊:Fail "existing canonical Budget plan linkage does not match derived intent"}⍟(¬exact) @
  •Out "OK"∾tab∾"APPLIED"∾tab∾planID
  •Exit 0
}⍟(1=+´budgetMatches) @

raw ← io.ReadRaw Join ⟨base,canonical.budget⟩
prepared ← candidate.Prepare ⟨raw,accounts,setup.registry,intent⟩
{𝕊:Fail prepared.message}⍟(prepared.state≢"ok") @
•Out "OK"∾tab∾"APPEND"∾tab∾canonical.budget
•Out prepared.payload
