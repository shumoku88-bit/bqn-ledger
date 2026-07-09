# src_edit/issue_list_cmd.bqn
# Read-only BQN command for `tools/edit-bqn issue list`.
#
# Input args:
#   <baseDir> <format: tsv|text>
#
# `--format tsv` is a UI contract used by tools/add-ui.sh issue-close selection:
#   number date title amount memo display

loader ← •Import "../src_next/loader.bqn"

args ← •args
tab ← @+9

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

IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }

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

# Drop the TSV header when present.
bodyLines ← (0 < ≠ allLines) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allLines} ⟩ @
bodyNums ← (0 < ≠ allNums) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allNums} ⟩ @

ParseIssueRow ← {𝕊 index:
  line ← index ⊑ bodyLines
  lineNum ← index ⊑ bodyNums
  fields ← loader.SplitTsvKeepEmpty line
  {𝕊 ⋄ Fail "issues.tsv line has fewer than 5 tab-separated columns"}⍟(5 > ≠ fields) @
  {
    lineNum ⇐ lineNum ⋄
    fields ⇐ fields ⋄
    date ⇐ 0 ⊑ fields ⋄
    status ⇐ 1 ⊑ fields ⋄
    title ⇐ 2 ⊑ fields ⋄
    amount ⇐ 3 ⊑ fields ⋄
    memo ⇐ 4 ⊑ fields
  }
}

allIssues ← ParseIssueRow¨ ↕ ≠ bodyLines
openIssues ← ({𝕩.status ≡ "open"}¨ allIssues) / allIssues

Display ← {𝕊 r:
  (•Fmt r.lineNum) ∾ " | " ∾ r.date ∾ " | " ∾ r.title ∾ " | " ∾ r.amount ∾ " | " ∾ r.memo
}

PrintTsv ← {𝕊 index:
  r ← index ⊑ openIssues
  n ← index + 1
  •Out tab Join ⟨(•Fmt n), r.date, r.title, r.amount, r.memo, Display r⟩
}

PrintText ← {𝕊 index:
  r ← index ⊑ openIssues
  •Out (Display r)
}

(format ≡ "tsv") ◶ ⟨
  {𝕊 ⋄ PrintText¨ ↕ ≠ openIssues},
  {𝕊 ⋄ PrintTsv¨ ↕ ≠ openIssues}
⟩ @
