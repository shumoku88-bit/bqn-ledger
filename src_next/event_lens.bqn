# event_lens.bqn
# Read-only Event Lens for Headless Kernel Evolution Phase D (Slice 1).
# Converts checked result to source-row-level readonly event records.

proj ← •Import "projection.bqn"

BuildRows ← {
  (𝕩.state ≢ "ok") ?
    { state ⇐ "error", message ⇐ "checked result state is not ok" } ;
    {𝕊 checkedResult:
      evidence ← checkedResult.row_evidence
      coefs ← checkedResult.arithmetic_evidence.normalized_coefficients
      proof ← checkedResult.arithmetic_currency_proof
      projRows ← checkedResult.posting_rows

      MakeLensRow ← {𝕊 ⟨row, coef⟩:
        srcFile ← row.source_file
        rowIdx ← row.source_row
        flds ← row.flds
        
        # 1. source dimensions
        srcId ← proj.FieldOrEmpty ⟨flds, 1⟩
        
        # 2. when
        date ← proj.FieldOrEmpty ⟨flds, 0⟩
        dateOk ← proj.IsValidDateText date
        when_state ← dateOk ⊑ ((0 = ≠ date) ⊑ "ambiguous"‿"absent")‿"direct"
        
        # 3. party
        metas ← 5 ↓ flds
        party_metas ← ( { "party=" ≡ (6 ⌊ ≠𝕩) ↑ 𝕩 } ¨ metas ) / metas
        party_tokens ← 6 ↓¨ party_metas
        
        party_value ← ""
        party_state ← "absent"
        {𝕊:
          val ← ⊑ party_tokens
          {𝕊:
            party_value ↩ val
            party_state ↩ "direct"
          } ⍟ (0 < ≠ val) @
        } ⍟ (1 = ≠ party_tokens) @
        {𝕊:
          party_state ↩ "ambiguous"
        } ⍟ (1 < ≠ party_tokens) @

        # 4. what
        memo ← proj.FieldOrEmpty ⟨flds, 1⟩
        what_state ← (0 = ≠ memo) ⊑ "ambiguous"‿"absent"

        # 5. where-to
        from_account ← proj.FieldOrEmpty ⟨flds, 2⟩
        where_to_value ← proj.FieldOrEmpty ⟨flds, 3⟩
        where_to_state ← (0 = ≠ where_to_value) ⊑ "direct"‿"absent"

        # 6. amount
        amount_text ← proj.FieldOrEmpty ⟨flds, 4⟩
        amount_coefficient ← coef
        amount_scale ← proof.amount_scale
        currency ← proof.domain
        amount_state ← "direct"

        # 7. action
        # Locate matching projection row to extract layer and kind
        matching_proj_rows ← ( ({𝕩.source_file}¨ projRows) ≡¨ <srcFile) ∧ (({𝕩.source_row}¨ projRows) = rowIdx)
        proj_row ← ⊑ matching_proj_rows / projRows
        
        layer ← proj_row.layer_name
        kind ← proj_row.kind
        action_value ← layer ∾ ":" ∾ kind
        action_state ← "derived"

        {
          source_file ⇐ srcFile,
          source_row ⇐ rowIdx,
          source_id ⇐ srcId,
          when_value ⇐ date,
          when_state ⇐ when_state,
          party_value ⇐ party_value,
          party_state ⇐ party_state,
          what_value ⇐ memo,
          what_state ⇐ what_state,
          from_account ⇐ from_account,
          where_to_value ⇐ where_to_value,
          where_to_state ⇐ where_to_state,
          amount_text ⇐ amount_text,
          amount_coefficient ⇐ amount_coefficient,
          amount_scale ⇐ amount_scale,
          currency ⇐ currency,
          amount_state ⇐ amount_state,
          action_value ⇐ action_value,
          action_state ⇐ action_state,
          layer ⇐ layer,
          kind ⇐ kind
        }
      }

      lens_rows ← {𝕊 i:
        row ← i ⊑ evidence
        coef ← i ⊑ coefs
        MakeLensRow ⟨row, coef⟩
      } ¨ ↕ ≠ evidence
      
      # Return structured success
      { state ⇐ "ok", rows ⇐ lens_rows }
    } 𝕩
}

{
  BuildRows ⇐ BuildRows
}
