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
registryMod ← •Import "../src/ledger/currency_registry.bqn"
admission ← •Import "../src/ledger/issue_admission.bqn"
amountText ← •Import "../src/ledger/amount_text.bqn"

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

# Keep physical lines only so the admitted relation can retain real source_row
# coordinates. Header/schema/lifecycle/date/amount meaning belongs to admission.
ResolvePath ← {
  path ← 𝕩
  is_abs ← (0 < ≠ path) ∧ (("/" ≡ 1 ↑ path) ∨ ("~" ≡ 1 ↑ path))
  is_abs ◶ ⟨ { 𝕊 ⋄ •wdpath ∾ "/" ∾ path }, { 𝕊 ⋄ path } ⟩ @
}
ReadSourceLinesOptional ← {
  full ← ResolvePath 𝕩
  (•file.Exists full) ◶ ⟨
    {𝕊 ⋄ ⟨⟩},
    {𝕊 ⋄
      raw ← loader.ReadRaw full
      stripped ← ((@+13) ≠ raw) / raw
      (@+10) loader.SplitKeepEmpty stripped
    }
  ⟩ @
}

sourceLines ← ReadSourceLinesOptional issuePath
registryResult ← registryMod.Build loader.ReadLines "config/currencies.tsv"
{𝕊 ⋄ Fail "currency registry invalid"}⍟(registryResult.state≢"ok") @
result ← admission.Admit ⟨sourceLines,registryResult.registry⟩
{𝕊 ⋄ Fail (⊑result.diagnostics).message}⍟(result.state≢"ok") @
issues ← result.issues
openIndices ← ("open"⊸≡¨issues.status) / issues.index

AmountFor ← {𝕊 i:
  text ← ""
  {𝕊:text↩amountText.Format ⟨i⊑issues.coefficient,i⊑issues.scale⟩}⍟(i⊑issues.amount_present) @
  text
}
Display ← {𝕊 displayIndex‿i:
  (•Fmt displayIndex) ∾ " | line " ∾ (•Fmt i⊑issues.source_row) ∾ " | " ∾
    (i⊑issues.date) ∾ " | " ∾ (i⊑issues.title) ∾ " | " ∾ (AmountFor i) ∾ " | " ∾
    (i⊑issues.details) ∾ " | due: " ∾ (i⊑issues.due)
}
PrintTsv ← {𝕊 displayIndex‿i:
  display ← Display ⟨displayIndex,i⟩
  •Out tab Join ⟨
    •Fmt displayIndex,
    i⊑issues.date,
    i⊑issues.title,
    AmountFor i,
    i⊑issues.details,
    display,
    i⊑issues.due
  ⟩
}
PrintText ← {𝕊 displayIndex‿i: •Out Display ⟨displayIndex,i⟩}

pairs ← {𝕊 j:⟨j+1,j⊑openIndices⟩}¨↕≠openIndices
(format ≡ "tsv") ◶ ⟨
  {𝕊 ⋄ PrintText¨pairs},
  {𝕊 ⋄ PrintTsv¨pairs}
⟩ @
