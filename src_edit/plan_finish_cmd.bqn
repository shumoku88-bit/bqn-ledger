# src_edit/plan_finish_cmd.bqn
# BQN command for experimental `tools/edit-bqn plan finish`.
#
# Input args:
#   <baseDir> <index: 0 or number> <planId: "" or id> <actualDate> <actualAmount: "" or amount>
#
# Stdout protocol on success:
#   OK\tAPPEND\tjournal.tsv
#   <complete TSV row>
#
# Stdout protocol on validation error (with non-zero exit):
#   ERROR\t<message>

loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
plan_id ← •Import "plan_id.bqn"
config ← •Import "../src_next/config.bqn"
date ← •Import "../src_next/date.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: plan_finish_cmd.bqn <baseDir> <index> <planId> <actualDate> <actualAmount>"}⍟(5 ≠ ≠ args) @

baseDir ← 0 ⊑ args
indexStr ← 1 ⊑ args
targetPlanID ← 2 ⊑ args
actualDate ← 3 ⊑ args
actualAmount ← 4 ⊑ args

# パース処理
lib ← •Import "../src_next/util.bqn"
index ← lib.ToNum indexStr

# パス解決
ResolvePath ← { baseDir ∾ "/" ∾ 𝕩 }

# データの読み込み
planPath ← ResolvePath (sys.DefaultPlanFile @)
journalPath ← ResolvePath (sys.DefaultJournalFile @)

LoadAccountsList ← {𝕩 ⋄
  path ← ResolvePath (sys.DefaultAccountsFile @)
  lines ← loader.ReadLinesOptional path
  IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }
  dataLines ← (IsDataLine¨ lines) / lines
  fields ← loader.SplitTsvKeepEmpty¨ dataLines
  nonEmpty ← (0 < ≠¨ fields) / fields
  {⊑ 𝕩}¨ nonEmpty
}
accounts ← LoadAccountsList @

# completed plan IDs のロード
journalLines ← loader.ReadLinesOptional journalPath
completedIDsAll ← plan_id.ExtractPlanId¨ journalLines
completedIDs ← (0 < ≠¨ completedIDsAll) / completedIDsAll

# planLines のロード
IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }
planLinesRaw ← loader.ReadLinesOptional planPath
lineNumsRaw ← 1 + ↕ ≠ planLinesRaw
mask ← IsDataLine¨ planLinesRaw
planLines ← mask / planLinesRaw
lineNums ← mask / lineNumsRaw

# ValidatePlanFields
ValidatePlanFields ← {𝕊 fields:
  {𝕊 ⋄ Fail "plan.tsv line has fewer than 5 tab-separated columns"}⍟(5 > ≠ fields) @
  dateCheck ← validate.ValidateDate (0 ⊑ fields)
  {𝕊 ⋄ Fail (1 ⊑ dateCheck)}⍟(¬ 0 ⊑ dateCheck) @
  fromCheck ← validate.ValidateAccount "from"‿(2 ⊑ fields)‿accounts
  {𝕊 ⋄ Fail (1 ⊑ fromCheck)}⍟(¬ 0 ⊑ fromCheck) @
  toCheck ← validate.ValidateAccount "to"‿(3 ⊑ fields)‿accounts
  {𝕊 ⋄ Fail (1 ⊑ toCheck)}⍟(¬ 0 ⊑ toCheck) @
  amountCheck ← validate.ValidateAmount (4 ⊑ fields)
  {𝕊 ⋄ Fail (1 ⊑ amountCheck)}⍟(¬ 0 ⊑ amountCheck) @
  metaCheck ← validate.ValidateMeta (5 ↓ fields)
  {𝕊 ⋄ Fail (1 ⊑ metaCheck)}⍟(¬ 0 ⊑ metaCheck) @
  1
}

ParsePlanRow ← {𝕊 idx:
  line ← idx ⊑ planLines
  lineNum ← idx ⊑ lineNums
  fields ← loader.SplitTsvKeepEmpty line
  pid ← plan_id.ExtractPlanId line
  missingID ← 0 = ≠ pid
  invalidID ← (¬ missingID) ◶ ⟨ {𝕊 ⋄ 0}, {𝕊 ⋄ ¬ (0 ⊑ plan_id.ValidatePlanIDFormat pid)} ⟩ @
  closed ← (¬ missingID) ◶ ⟨ {𝕊 ⋄ 0}, {𝕊 ⋄ ∨´ pid ⊸ ≡¨ completedIDs} ⟩ @
  ⟨lineNum, <fields, closed, <pid, missingID, invalidID⟩
}

allPlans ← ParsePlanRow¨ ↕ ≠ planLines
# Closedでないプラン
plans ← (¬ {2⊑𝕩}¨ allPlans) / allPlans

# ターゲットの特定
selected ← ⟨⟩
(index > 0) ◶ ⟨
  { 𝕊 ⋄
    # planIdによる検索
    {𝕊 ⋄ Fail ("plan_id not found or already closed: " ∾ targetPlanID)}⍟(0 = ≠ plans) @
    matching ← { (3⊑𝕩) ≡ <targetPlanID }¨ plans
    {𝕊 ⋄ Fail ("plan_id not found or already closed: " ∾ targetPlanID)}⍟(¬ ∨´ matching) @
    selected ↩ ⊑ matching / plans
  },
  { 𝕊 ⋄
    # indexによる検索
    {𝕊 ⋄ Fail ("invalid plan index: " ∾ (•Fmt index) ∾ " (available: 1-" ∾ (•Fmt ≠ plans) ∾ ")")}⍟((index < 1) ∨ (index > ≠ plans)) @
    selected ↩ (index-1) ⊑ plans
  }
⟩ @

# 選択されたプランの属性
lineNum ‿ fieldsBox ‿ closed ‿ pidBox ‿ missingID ‿ invalidID ← selected
fields ← > fieldsBox
pid ← > pidBox

# プランとしての適合性チェック
{𝕊 ⋄ Fail "plan is already closed"}⍟closed @
{𝕊 ⋄ Fail "cannot finish plan without plan_id"}⍟missingID @
{𝕊 ⋄ Fail ("cannot finish plan with invalid plan_id: " ∾ pid)}⍟invalidID @

# 元のフィールドのバリデーション
validationOk ← ValidatePlanFields fields

# actualDate のバリデーション
dateCheck ← validate.ValidateDate actualDate
{𝕊 ⋄ Fail (1 ⊑ dateCheck)}⍟(¬ 0 ⊑ dateCheck) @

# 未来日付チェック
today ← date.Today @
{𝕊 ⋄ Fail ("payment date cannot be in the future: " ∾ actualDate)}⍟((date.Ordinal actualDate) > date.Ordinal today) @

# actualAmount: empty means preserve the planned amount; non-empty is the observed amount.
amountToUse ← (0 = ≠ actualAmount) ◶ ⟨ {𝕊 ⋄ actualAmount}, {𝕊 ⋄ 4 ⊑ fields} ⟩ @
actualAmountCheck ← validate.ValidateAmount amountToUse
{𝕊 ⋄ Fail (1 ⊑ actualAmountCheck)}⍟(¬ 0 ⊑ actualAmountCheck) @

# ジャーナル用メタデータの構築
meta ← 5 ↓ fields
IsPlanId ← { (8 ≤ ≠ 𝕩) ? "plan_id=" plan_id.StartsWith 𝕩 ; 0 }
hasPlanId ← ∨´ IsPlanId¨ meta
metaToUse ← hasPlanId ◶ ⟨ { 𝕊 ⋄ ⟨"plan_id=" ∾ pid⟩ ∾ meta }, { 𝕊 ⋄ meta } ⟩ @

# ジャーナル行のレンダリング
row ← render.RenderJournalRow {
  date ⇐ actualDate ⋄
  memo ⇐ 1 ⊑ fields ⋄
  from ⇐ 2 ⊑ fields ⋄
  to ⇐ 3 ⊑ fields ⋄
  amount ⇐ amountToUse ⋄
  meta ⇐ metaToUse
}

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ sys.DefaultJournalFile @
•Out row
