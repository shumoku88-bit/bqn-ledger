# journal_source_integrity.bqn
# Pure, mixed-currency-safe integrity validation for ordinary journal source.

validate ← •Import "validate.bqn"
decimal ← •Import "../src_next/exact_decimal.bqn"
admission ← •Import "../src_next/source_currency_admission.bqn"
ak ← •Import "../src_next/account_key.bqn"
util ← •Import "../src_next/util.bqn"

empty ← ⟨⟩
tab ← @+9
IsIgnored ← {𝕊 line:
  ignored ← 0=≠line
  {𝕊: ignored ↩ ((⊑line)='#') ∨ ((⊑line)=⊑"\\")}⍟(0<≠line) @
  ignored
}
Diagnostic ← {𝕊 codeText‿row:
  {severity⇐"error", stage⇐"journal_source_integrity", code⇐codeText, source_file⇐"journal.tsv", source_row⇐row, message⇐"journal.tsv row "∾(•Fmt row)∾": "∾codeText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩ }

Check ← {𝕊 request:
  accountData ← (¬IsIgnored¨request.account_lines)/request.account_lines
  snapshot ← {sources⇐⟨{source_file⇐"journal.tsv", required⇐1, lines⇐request.journal_lines}⟩}
  admitted ← admission.Admit ⟨admission.policy.legacy_compatibility, request.account_lines, snapshot⟩
  diagnostics ← admitted.diagnostics
  resolved ← ak.Resolve accountData
  names ← resolved.accounts
  currencies ← resolved.currencies
  evidenceIndex ← 0
  validRows ← 0

  {𝕊 indexed:
    row‿line ← indexed
    {𝕊:
      fields ← tab util.SplitKeepEmpty line
      diagnostics ∾↩ AddIf ⟨5>≠fields, Diagnostic ⟨"row_column_count_invalid", row⟩⟩
      {𝕊:
        dateText ← 0⊑fields ⋄ from ← 2⊑fields ⋄ to ← 3⊑fields ⋄ amount ← 4⊑fields ⋄ metadata ← 5↓fields
        rowCurrency ← (evidenceIndex⊑admitted.admitted_row_evidence).currency
        evidenceIndex +↩ 1
        dateCheck ← validate.ValidateDate dateText
        amountParsed ← decimal.Parse amount
        metaCheck ← validate.ValidateMeta metadata
        fromIdx ← ⊑names⊐⟨from⟩ ⋄ toIdx ← ⊑names⊐⟨to⟩
        diagnostics ∾↩ AddIf ⟨¬⊑dateCheck, Diagnostic ⟨"row_date_invalid", row⟩⟩
        diagnostics ∾↩ AddIf ⟨amountParsed.state≢"ok", Diagnostic ⟨"row_amount_invalid", row⟩⟩
        diagnostics ∾↩ AddIf ⟨¬⊑metaCheck, Diagnostic ⟨"row_metadata_invalid", row⟩⟩
        diagnostics ∾↩ AddIf ⟨fromIdx≥≠names, Diagnostic ⟨"row_from_account_unknown", row⟩⟩
        diagnostics ∾↩ AddIf ⟨toIdx≥≠names, Diagnostic ⟨"row_to_account_unknown", row⟩⟩
        {𝕊: diagnostics ∾↩ AddIf ⟨(fromIdx⊑currencies)≢rowCurrency, Diagnostic ⟨"row_from_currency_mismatch", row⟩⟩}⍟(fromIdx<≠names) @
        {𝕊: diagnostics ∾↩ AddIf ⟨(toIdx⊑currencies)≢rowCurrency, Diagnostic ⟨"row_to_currency_mismatch", row⟩⟩}⍟(toIdx<≠names) @
        precisionCheck ← validate.ValidateExactAmountForCurrency rowCurrency‿amount
        diagnostics ∾↩ AddIf ⟨¬⊑precisionCheck, Diagnostic ⟨"row_currency_amount_invalid", row⟩⟩
        validRows +↩ 1
      }⍟((5≤≠fields) ∧ (admitted.state≡"ok")) @
    }⍟(¬IsIgnored line) @
  }¨ (<˘(↕≠request.journal_lines)∾˘request.journal_lines)

  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {state⇐state, diagnostics⇐diagnostics, row_count⇐(state≡"ok")×validRows}
}

{Check⇐Check}
