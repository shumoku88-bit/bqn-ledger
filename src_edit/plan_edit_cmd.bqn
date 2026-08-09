# Prepare one canonical plan.journal block edit.
# Source coordinates come only from strict Plan admission. Date edits touch the
# header date; amount edits replace binary Posting lines in order. Metadata and
# every unrelated source byte remain in place. The complete candidate is
# re-admitted before publication.

lib ← •Import "../src/text/parse.bqn"
loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
planSource ← •Import "../src/application/plan_source_adapter.bqn"
actualSource ← •Import "../src/application/editor_actual.bqn"
rootAdmission ← •Import "../src/ledger/canonical_journal_root_admission.bqn"
planAdmission ← •Import "../src/ledger/plan_journal_admission.bqn"
validate ← •Import "validate.bqn"
decimal ← •Import "../src/ledger/exact_decimal.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
lf ← @+10
cr ← @+13

Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
ReplaceAt ← {𝕊 index‿value‿xs: (index↑xs)∾⟨value⟩∾(index+1)↓xs}
JoinLines ← {𝕊 xs:
  result ← ""
  {𝕊:
    result↩⊑xs
    {𝕊 line: result∾↩lf∾line}¨1↓xs
  }⍟(0<≠xs) @
  result
}
ExactMagnitudeEqual ← {𝕊 oldCoefficient‿oldScale‿newCoefficient‿newScale:
  (|oldCoefficient)×10⋆newScale = newCoefficient×10⋆oldScale
}

{𝕊:Fail "usage: plan_edit_cmd.bqn <baseDir> <candidateFile> <index> <planId> <date> <amount> <showAll>"}⍟(7≠≠args) @
baseDir ← 0⊑args
candidateFile ← 1⊑args
indexVal ← lib.ToNum 2⊑args
idVal ← 3⊑args
dateVal ← 4⊑args
amountVal ← 5⊑args
showAll ← "1"≡6⊑args
{𝕊:Fail "must specify Plan using --index or --id"}⍟((indexVal≤0) ∧ 0=≠idVal) @
{𝕊:Fail "must specify at least one of --date or --amount"}⍟((0=≠dateVal) ∧ 0=≠amountVal) @

planResult ← planSource.Load ⟨baseDir,setup.registry⟩
{𝕊:Fail "canonical plan.journal rejected"}⍟(planResult.state≢"ok") @
facts ← planResult.facts
transactionCount ← facts.transactions.count
transactionIndices ← ↕transactionCount
planIDs ← facts.transactions.plan_id
completionIDs ← {𝕩.plan_id}¨actualSource.CompletionEvidence baseDir
closedMask ← {Contains ⟨𝕩,completionIDs⟩}¨planIDs
visibleIndices ← (¬closedMask)/transactionIndices
{𝕊:visibleIndices↩transactionIndices}⍟showAll @

selectedIndex ← ¯1
{𝕊:
  {𝕊:Fail ("invalid plan index: "∾•Fmt indexVal∾" (available: 1-"∾•Fmt ≠visibleIndices∾")")}⍟((indexVal<1) ∨ indexVal>≠visibleIndices) @
  selectedIndex↩(indexVal-1)⊑visibleIndices
}⍟(indexVal>0) @
{𝕊:
  matches ← {idVal≡𝕩⊑planIDs}¨visibleIndices
  missingMessage ← "plan_id not found or already closed: "
  {𝕊:missingMessage↩"plan_id not found: "}⍟showAll @
  {𝕊:Fail (missingMessage∾idVal)}⍟(1≠+´matches) @
  selectedIndex↩⊑matches/visibleIndices
}⍟(indexVal≤0) @
{𝕊:Fail ("cannot edit closed plan: "∾selectedIndex⊑planIDs)}⍟(selectedIndex⊑closedMask) @

targetPlanID ← selectedIndex⊑planIDs
currentDate ← selectedIndex⊑facts.transactions.date_text
targetDate ← currentDate
{𝕊:
  dateCheck ← validate.ValidateDate dateVal
  {𝕊:Fail 1⊑dateCheck}⍟(¬0⊑dateCheck) @
  targetDate↩dateVal
}⍟(0<≠dateVal) @

postingMask ← selectedIndex=facts.postings.transaction_index
postingIndices ← postingMask/↕facts.postings.count
postingCount ← ≠postingIndices
currency ← (selectedIndex⊑facts.transactions.domain_index)⊑facts.domains.code
amountChanged ← 0
parsedAmount ← @
{𝕊:
  {𝕊:Fail "Plan amount edit requires exactly two Postings"}⍟(2≠postingCount) @
  amountCheck ← validate.ValidateExactAmountForCurrency currency‿amountVal
  {𝕊:Fail 1⊑amountCheck}⍟(¬0⊑amountCheck) @
  parsedAmount↩decimal.Parse amountVal
  {𝕊:Fail "Plan edit amount must be strictly positive"}⍟((parsedAmount.state≢"ok") ∨ parsedAmount.coefficient≤0) @
  firstPosting ← ⊑postingIndices
  amountChanged↩¬ExactMagnitudeEqual ⟨firstPosting⊑facts.postings.source_coefficient,firstPosting⊑facts.postings.source_scale,parsedAmount.coefficient,parsedAmount.scale⟩
}⍟(0<≠amountVal) @
dateChanged ← targetDate≢currentDate

raw ← loader.ReadRaw Join ⟨baseDir,canonical.plan⟩
{𝕊:Fail "canonical Plan edit refuses CR source normalization"}⍟(∨´0∾cr=raw) @
lines ← lf loader.SplitKeepEmpty raw
headerIndex ← (selectedIndex⊑facts.transactions.source_start_line)-1
{𝕊:Fail "admitted Plan header coordinate is outside source"}⍟((headerIndex<0) ∨ headerIndex≥≠lines) @
header ← headerIndex⊑lines
{𝕊:Fail "admitted Plan header date does not match source coordinate"}⍟(currentDate≢10↑header) @
candidateLines ← lines
{𝕊:candidateLines↩ReplaceAt ⟨headerIndex,targetDate∾10↓header,candidateLines⟩}⍟dateChanged @

expectedAmountTexts ← postingIndices⊏facts.postings.amount_text
{𝕊:
  expectedAmountTexts↩⟨⟩
  {𝕊 postingIndex:
    sourceLine ← postingIndex⊑facts.postings.source_line
    lineIndex ← sourceLine-1
    {𝕊:Fail "admitted Posting coordinate is outside Plan source"}⍟((lineIndex<0) ∨ lineIndex≥≠candidateLines) @
    account ← (postingIndex⊑facts.postings.account_index)⊑facts.accounts.key
    sourceCoefficient ← postingIndex⊑facts.postings.source_coefficient
    signedAmount ← amountVal
    {𝕊:signedAmount↩"-"∾amountVal}⍟(sourceCoefficient<0) @
    replacement ← "    "∾account∾"    "∾signedAmount∾" "∾currency
    candidateLines↩ReplaceAt ⟨lineIndex,replacement,candidateLines⟩
    expectedAmountTexts∾↩⟨signedAmount⟩
  }¨postingIndices
}⍟amountChanged @

candidateRaw ← JoinLines candidateLines
{𝕊:Fail "canonical Plan edit produced no source change"}⍟(candidateRaw≡raw) @

accountResult ← accountSource.Load baseDir
{𝕊:Fail "canonical accounts.journal rejected"}⍟(accountResult.state≢"ok") @
rootResult ← rootAdmission.Admit ⟨candidateRaw,canonical.accounts⟩
{𝕊:Fail "candidate plan.journal root include topology rejected"}⍟(rootResult.state≢"ok") @
candidateResult ← planAdmission.Admit ⟨candidateRaw,accountResult.accounts,setup.registry⟩
{𝕊:
  diagnostic ← ⊑candidateResult.diagnostics
  Fail ("candidate canonical Plan rejected: "∾diagnostic.code∾" at line "∾•Fmt diagnostic.line)
}⍟(candidateResult.state≢"ok") @
{𝕊:Fail "candidate Plan transaction count changed"}⍟((≠candidateResult.transactions)≠transactionCount) @
candidateIDs ← {𝕩.plan_id}¨candidateResult.transactions
{𝕊:Fail "candidate Plan identities or ordering changed"}⍟(candidateIDs≢planIDs) @
candidate ← selectedIndex⊑candidateResult.transactions
candidateAccounts ← {𝕩.account_key}¨candidate.postings
candidateAmounts ← {𝕩.amount_text}¨candidate.postings
candidateCommodities ← {𝕩.commodity}¨candidate.postings
originalAccounts ← {(𝕩⊑facts.postings.account_index)⊑facts.accounts.key}¨postingIndices
originalMetadata ← selectedIndex⊑facts.transactions.metadata
candidateMetadataKeys ← {𝕩.key}¨candidate.metadata
originalMetadataKeys ← {𝕩.key}¨originalMetadata
candidateMetadataValues ← {𝕩.value}¨candidate.metadata
originalMetadataValues ← {𝕩.value}¨originalMetadata
candidateOk ← (candidate.plan_id≡targetPlanID) ∧ (candidate.date≡targetDate) ∧ (candidate.description≡selectedIndex⊑facts.transactions.description) ∧ (candidate.status_marker≡selectedIndex⊑facts.transactions.status_marker) ∧ (candidateAccounts≡originalAccounts) ∧ (candidateAmounts≡expectedAmountTexts) ∧ (∧´{𝕩≡currency}¨candidateCommodities) ∧ (candidateMetadataKeys≡originalMetadataKeys) ∧ (candidateMetadataValues≡originalMetadataValues) ∧ (candidate.source_start_line=selectedIndex⊑facts.transactions.source_start_line) ∧ (candidate.source_end_line=selectedIndex⊑facts.transactions.source_end_line)
{𝕊:Fail "re-admitted Plan candidate does not match edit intent"}⍟(¬candidateOk) @

candidateFile •FChars candidateRaw
•Out "OK"∾tab∾"REWRITE"∾tab∾canonical.plan∾tab∾targetPlanID