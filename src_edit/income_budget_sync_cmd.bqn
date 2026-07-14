# income_budget_sync_cmd.bqn — idempotent ordinary-income to unassigned proposal.
loader ← •Import "../src_next/loader.bqn"
config ← •Import "../src_next/config.bqn"
txnid ← •Import "txn_id.bqn"
render ← •Import "render.bqn"
validate ← •Import "validate.bqn"

args ← •args ⋄ tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
{𝕊: Fail "usage: income_budget_sync_cmd.bqn <baseDir> <txnId>"}⍟(2≠≠args) @
base ← 0⊑args ⋄ tid ← 1⊑args
{𝕊: Fail "txn_id must not be empty"}⍟(0=≠tid) @
sys ← config.LoadSystemDefaults @ ⋄ cfg ← config.LoadConfig base
Path ← {base∾"/"∾𝕩}
IsData ← {(0<≠𝕩)∧((⊑𝕩)≠'#')∧((⊑𝕩)≠⊑"\\")}
Data ← {(IsData¨𝕩)/𝕩}
journals ← Data loader.ReadLinesOptional (Path sys.DefaultJournalFile @)
budgets ← Data loader.ReadLinesOptional (Path sys.DefaultBudgetAllocFile @)
accounts ← Data loader.ReadLinesOptional (Path sys.DefaultAccountsFile @)
jm ← tid⊸≡¨txnid.Extract¨journals ⋄ bm ← tid⊸≡¨txnid.Extract¨budgets
{𝕊: Fail "txn_id must identify exactly one journal row"}⍟(1≠+´jm) @
{𝕊: •Out "OK"∾tab∾"APPLIED"∾tab∾tid ⋄ •Exit 0}⍟(1=+´bm) @
{𝕊: Fail "duplicate budget linkage for txn_id"}⍟(1<+´bm) @
jf ← loader.SplitTsvKeepEmpty ⊑jm/journals
{𝕊: Fail "journal row has fewer than 5 columns"}⍟(5>≠jf) @
meta ← 5↓jf
{𝕊: •Out "OK"∾tab∾"NOT_LINKED"∾tab∾tid ⋄ •Exit 0}⍟(¬∨´"income_budget=unassigned"⊸≡¨meta) @

af ← loader.SplitTsvKeepEmpty¨accounts ⋄ names ← ⊑¨af
fromIdx ← ⊑names⊐⟨2⊑jf⟩ ⋄ toIdx ← ⊑names⊐⟨3⊑jf⟩
{𝕊: Fail "journal account is unknown"}⍟((fromIdx≥≠names)∨(toIdx≥≠names)) @
fromMeta ← 1↓fromIdx⊑af ⋄ toMeta ← 1↓toIdx⊑af
{𝕊: Fail "income linkage requires from role=income"}⍟(¬∨´"role=income"⊸≡¨fromMeta) @
{𝕊: Fail "income linkage requires to role=asset type=liquid"}⍟((¬∨´"role=asset"⊸≡¨toMeta)∨(¬∨´"type=liquid"⊸≡¨toMeta)) @

opening ← cfg.BudgetOpening @
unassignedMask ← {f←𝕩 ⋄ (∨´"role=budget"⊸≡¨1↓f)∧(∨´"kind=unassigned"⊸≡¨1↓f)}¨af
openingMask ← opening⊸≡¨names
{𝕊: Fail "budget opening account must resolve exactly once"}⍟(1≠+´openingMask) @
{𝕊: Fail "budget unassigned account must resolve exactly once"}⍟(1≠+´unassignedMask) @
unassigned ← (⊑unassignedMask/↕≠names)⊑names
openingMeta ← 1↓(⊑openingMask/↕≠names)⊑af ⋄ unassignedMeta ← 1↓(⊑unassignedMask/↕≠names)⊑af
currencyMeta ← meta/˜{"currency=" txnid.StartsWith 𝕩}¨meta
{𝕊: Fail "journal currency must be explicit exactly once"}⍟(1≠≠currencyMeta) @
currencyToken ← ⊑currencyMeta
{𝕊: Fail "budget opening currency mismatch"}⍟(¬∨´currencyToken⊸≡¨openingMeta) @
{𝕊: Fail "budget unassigned currency mismatch"}⍟(¬∨´currencyToken⊸≡¨unassignedMeta) @
amountCheck ← validate.ValidateAmount 4⊑jf
{𝕊: Fail (1⊑amountCheck)}⍟(¬0⊑amountCheck) @

bf ← loader.SplitTsvKeepEmpty¨budgets
LegacyExact ← {𝕊 f: r←0 ⋄ {𝕊:r↩((0⊑f)≡0⊑jf)∧((2⊑f)≡opening)∧((3⊑f)≡unassigned)∧((4⊑f)≡4⊑jf)}⍟(5≤≠f) @ ⋄ r}
{𝕊: Fail "possible existing income companion lacks txn_id; refusing duplicate"}⍟(∨´LegacyExact¨bf) @
row ← render.RenderJournalRow {date⇐0⊑jf, memo⇐"通常収入を未割当へ反映", from⇐opening, to⇐unassigned, amount⇐4⊑jf, meta⇐⟨"txn_id="∾tid,currencyToken⟩}
•Out "OK"∾tab∾"APPEND"∾tab∾sys.DefaultBudgetAllocFile @
•Out row
