# src_edit/issue_list_cmd.bqn
# Read-only BQN command for `tools/edit-bqn issue list`.
#
# Input args:
#   <baseDir> <format: tsv|text>
#
# `--format tsv` is a UI contract used by tools/add-ui.sh issue-close selection:
#   number date title amount memo display due
# The first six fields remain in their established order; due is appended.
# number is the 1-based ordinal within current open issues, matching issue close --index.

loader ← •Import "../src/application/source_io.bqn"
validate ← •Import "validate.bqn"

args ← •args
tab ← @+9
legacyHeader ← ⟨"issue_id","status","date","category","title","amount","currency","details"⟩
dueHeader ← ⟨"issue_id","status","date","due","category","title","amount","currency","details"⟩
closedHeader ← ⟨"issue_id","status","date","due","closed","category","title","amount","currency","details"⟩

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: issue_list_cmd.bqn <baseDir> <format: tsv|text>"}⍟(2 ≠ ≠ args) @

baseDir ← 0 ⊑ args
format ← 1 ⊑ args
validFormat ← ∨´ format ⊸ ≡¨ "tsv"‿"text"
{𝕊 ⋄ Fail ("invalid format: " ∾ format ∾ " (expected 'tsv' or 'text')")}⍟(¬ validFormat) @

issuePath ← baseDir ∾ "/issues.tsv"

Join ← {
  sep ← 𝕨
  list ← 𝕩
  (0 = ≠ list) ◶ ⟨ { 𝕊 ⋄ 1↓ ∾ (sep ⊸ ∾) ¨ list }, { 𝕊 ⋄ ""} ⟩ @
}

IsDataLine ← { (0 < ≠𝕩) ? ((⊑𝕩 ≠ '#') ∧ (⊑𝕩 ≠ ⊑"\\")) ; 0 }

ResolvePath ← {
  path ← 𝕩
  is_abs ← (0 < ≠ path) ∧ (("/" ≡ 1 ↑ path) ∨ ("~" ≡ 1 ↑ path))
  is_abs ◶ ⟨ { 𝕊 ⋄ •wdpath ∾ "/" ∾ path }, { 𝕊 ⋄ path } ⟩ @
}

ReadDataLinesWithNumsOptional ← {
  full ← ResolvePath 𝕩
  (•file.Exists full) ◶ ⟨
    {𝕊 ⋄ ⟨⟨⟩,⟨⟩⟩},
    {𝕊 ⋄
      raw ← loader.ReadRaw full
      stripped ← ((@+13) ≠ raw) / raw
      lines ← (@+10) loader.SplitKeepEmpty stripped
      nums ← 1 + ↕ ≠ lines
      mask ← IsDataLine¨ lines
      ⟨mask / lines, mask / nums⟩
    }
  ⟩ @
}

lineData ← ReadDataLinesWithNumsOptional issuePath
allLines ← 0 ⊑ lineData
allNums ← 1 ⊑ lineData

headerFields ← ⟨⟩
{𝕊:headerFields↩loader.SplitTsvKeepEmpty ⊑allLines}⍟(0<≠allLines) @
legacySchema ← headerFields≡legacyHeader
dueSchema ← headerFields≡dueHeader
closedSchema ← headerFields≡closedHeader
headerOk ← (0=≠allLines) ∨ legacySchema ∨ dueSchema ∨ closedSchema
{𝕊 ⋄ Fail "issues.tsv header must match the supported eight-, nine-, or ten-column schema"}⍟(¬headerOk) @
expectedCount ← 8 + dueSchema + 2×closedSchema

# Drop the TSV header when present.
bodyLines ← (0 < ≠ allLines) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allLines} ⟩ @
bodyNums ← (0 < ≠ allNums) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allNums} ⟩ @

ParseIssueRow ← {𝕊 index:
  line ← index ⊑ bodyLines
  lineNum ← index ⊑ bodyNums
  fields ← loader.SplitTsvKeepEmpty line
  {𝕊 ⋄ Fail "issues.tsv row width must match its header"}⍟(expectedCount ≠ ≠ fields) @
  statusRaw ← 1⊑fields
  closedFallback ← (statusRaw≡"open")⊑⟨"undetermined","none"⟩
  normalized ← fields
  {𝕊:normalized↩(3↑fields)∾⟨"undetermined",closedFallback⟩∾3↓fields}⍟legacySchema @
  {𝕊:normalized↩(4↑fields)∾⟨closedFallback⟩∾4↓fields}⍟dueSchema @
  issueId‿status‿date‿due‿closed‿category‿title‿amount‿currency‿memo ← normalized
  dueOk ← (due≡"none") ∨ (due≡"undetermined") ∨ 0⊑validate.ValidateDate due
  {𝕊 ⋄ Fail "issues.tsv due must be none, undetermined, or a strict Gregorian date"}⍟(¬dueOk) @
  closedOk ← (closed≡"none") ∨ (closed≡"undetermined") ∨ 0⊑validate.ValidateDate closed
  {𝕊 ⋄ Fail "issues.tsv closed must be none, undetermined, or a strict Gregorian date"}⍟(¬closedOk) @
  lifecycleOk ← (status≡"open") = (closed≡"none")
  {𝕊 ⋄ Fail "issues.tsv status and closed lifecycle disagree"}⍟(¬lifecycleOk) @
  {
    lineNum ⇐ lineNum ⋄
    fields ⇐ fields ⋄
    issue_id ⇐ issueId ⋄
    status ⇐ status ⋄
    date ⇐ date ⋄
    due ⇐ due ⋄
    closed ⇐ closed ⋄
    category ⇐ category ⋄
    title ⇐ title ⋄
    amount ⇐ amount ⋄
    currency ⇐ currency ⋄
    memo ⇐ memo
  }
}

allIssues ← ParseIssueRow¨ ↕ ≠ bodyLines
openIssues ← ({𝕩.status ≡ "open"}¨ allIssues) / allIssues

Display ← {
  n ← 𝕨
  r ← 𝕩
  (•Fmt n) ∾ " | line " ∾ (•Fmt r.lineNum) ∾ " | " ∾ r.date ∾ " | " ∾ r.title ∾ " | " ∾ r.amount ∾ " | " ∾ r.memo ∾ " | due: " ∾ r.due
}

PrintTsv ← {𝕊 index:
  r ← index ⊑ openIssues
  n ← index + 1
  •Out tab Join ⟨(•Fmt n), r.date, r.title, r.amount, r.memo, n Display r, r.due⟩
}

PrintText ← {𝕊 index:
  r ← index ⊑ openIssues
  n ← index + 1
  •Out (n Display r)
}

(format ≡ "tsv") ◶ ⟨
  {𝕊 ⋄ PrintText¨ ↕ ≠ openIssues},
  {𝕊 ⋄ PrintTsv¨ ↕ ≠ openIssues}
⟩ @
