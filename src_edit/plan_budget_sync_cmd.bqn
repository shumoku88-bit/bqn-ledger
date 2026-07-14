# plan_budget_sync_cmd.bqn — idempotent execution-envelope companion proposal.
# Args: <baseDir> <planId>
# Output: OK APPEND budget_alloc.tsv + row, or OK APPLIED/NOT_LINKED.

loader ← •Import "../src_next/loader.bqn"
config ← •Import "../src_next/config.bqn"
planid ← •Import "plan_id.bqn"
render ← •Import "render.bqn"
validate ← •Import "validate.bqn"

args ← •args ⋄ tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR" ∾ tab ∾ msg ⋄ •Exit 1}
{𝕊: Fail "usage: plan_budget_sync_cmd.bqn <baseDir> <planId>"}⍟(2≠≠args) @
base ← 0⊑args ⋄ pid ← 1⊑args
pidCheck ← planid.ValidatePlanIDFormat pid
{𝕊: Fail (1⊑pidCheck)}⍟(¬0⊑pidCheck) @

sys ← config.LoadSystemDefaults @ ⋄ cfg ← config.LoadConfig base
Path ← {base ∾ "/" ∾ 𝕩}
IsData ← {(0<≠𝕩) ∧ ((⊑𝕩)≠'#') ∧ ((⊑𝕩)≠⊑"\\")}
Data ← {(IsData¨𝕩)/𝕩}
plans ← Data loader.ReadLinesOptional (Path sys.DefaultPlanFile @)
journals ← Data loader.ReadLinesOptional (Path sys.DefaultJournalFile @)
budgets ← Data loader.ReadLinesOptional (Path sys.DefaultBudgetAllocFile @)
accounts ← Data loader.ReadLinesOptional (Path sys.DefaultAccountsFile @)

planMatches ← pid⊸≡¨ planid.ExtractPlanId¨ plans
journalMatches ← pid⊸≡¨ planid.ExtractPlanId¨ journals
budgetMatches ← pid⊸≡¨ planid.ExtractPlanId¨ budgets
{𝕊: Fail "plan_id must identify exactly one plan row"}⍟(1≠+´planMatches) @
{𝕊: Fail "plan_id must identify exactly one completed journal row"}⍟(1≠+´journalMatches) @
{𝕊: •Out "OK" ∾ tab ∾ "APPLIED" ∾ tab ∾ pid ⋄ •Exit 0}⍟(1=+´budgetMatches) @
{𝕊: Fail "duplicate budget linkage for plan_id"}⍟(1<+´budgetMatches) @

pf ← loader.SplitTsvKeepEmpty ⊑planMatches/plans
jf ← loader.SplitTsvKeepEmpty ⊑journalMatches/journals
{𝕊: Fail "plan row has fewer than 5 columns"}⍟(5>≠pf) @
{𝕊: Fail "journal row has fewer than 5 columns"}⍟(5>≠jf) @
{𝕊: Fail "completed journal accounts do not match plan"}⍟(((2⊑pf)≢2⊑jf)∨((3⊑pf)≢3⊑jf)) @

expense ← 3⊑pf
accountFields ← loader.SplitTsvKeepEmpty¨ accounts
names ← ⊑¨accountFields ⋄ ai ← ⊑names⊐⟨expense⟩
{𝕊: Fail "plan target account is unknown"}⍟(ai≥≠names) @
meta ← 1↓ai⊑accountFields
IsFixed ← {"spend_class=fixed"≡𝕩}
{𝕊: Fail "duplicate spend_class=fixed metadata"}⍟(1<+´IsFixed¨meta) @
{𝕊: •Out "OK" ∾ tab ∾ "NOT_LINKED" ∾ tab ∾ pid ⋄ •Exit 0}⍟(¬∨´IsFixed¨meta) @

envLabel ← cfg.ExecutionPlannedPaymentsEnvelope @
{𝕊: Fail "EXECUTION_PLANNED_PAYMENTS_ENVELOPE is missing"}⍟(0=≠envLabel) @
envAccount ← (cfg.BudgetPrefix @) ∾ envLabel
spentAccount ← cfg.BudgetSpent @
envMask ← envAccount⊸≡¨names ⋄ spentMask ← spentAccount⊸≡¨names
{𝕊: Fail "configured execution envelope account must resolve exactly once"}⍟(1≠+´envMask) @
{𝕊: Fail "configured budget spent account must resolve exactly once"}⍟(1≠+´spentMask) @
envMeta ← 1↓(⊑envMask/↕≠names)⊑accountFields
spentMeta ← 1↓(⊑spentMask/↕≠names)⊑accountFields
{𝕊: Fail "configured execution envelope lacks role=budget"}⍟(¬∨´"role=budget"⊸≡¨envMeta) @
{𝕊: Fail "configured execution envelope lacks envelope_role=execution"}⍟(¬∨´"envelope_role=execution"⊸≡¨envMeta) @
{𝕊: Fail "configured spent sink lacks role=budget"}⍟(¬∨´"role=budget"⊸≡¨spentMeta) @

currencyMeta ← (5↓jf) /˜ {"currency=" planid.StartsWith 𝕩}¨5↓jf
{𝕊: Fail "completed journal currency must be explicit exactly once"}⍟(1≠≠currencyMeta) @
currencyToken ← ⊑currencyMeta
{𝕊: Fail "execution envelope currency mismatch"}⍟(¬∨´currencyToken⊸≡¨envMeta) @
{𝕊: Fail "spent sink currency mismatch"}⍟(¬∨´currencyToken⊸≡¨spentMeta) @

budgetFields ← loader.SplitTsvKeepEmpty¨ budgets
LegacyExact ← {𝕊 f:
  result ← 0
  {𝕊: result ↩ ((0⊑f)≡0⊑jf) ∧ ((2⊑f)≡envAccount) ∧ ((3⊑f)≡spentAccount) ∧ ((4⊑f)≡4⊑jf)}⍟(5≤≠f) @
  result
}
{𝕊: Fail "possible existing budget companion lacks plan_id; refusing duplicate"}⍟(∨´LegacyExact¨budgetFields) @

amountCheck ← validate.ValidateAmount 4⊑jf
{𝕊: Fail (1⊑amountCheck)}⍟(¬0⊑amountCheck) @
row ← render.RenderJournalRow {date⇐0⊑jf, memo⇐"plan実績に連動した固定費封筒消化", from⇐envAccount, to⇐spentAccount, amount⇐4⊑jf, meta⇐⟨"plan_id="∾pid, ⊑currencyMeta⟩}
•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ sys.DefaultBudgetAllocFile @
•Out row
