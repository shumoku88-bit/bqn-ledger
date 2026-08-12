# Pure strict ownership/linkage admission for Daily Target application scopes.

exact ← •Import "../ledger/exact_decimal.bqn"
parse ← •Import "../text/parse.bqn"
empty ← ⟨⟩ ⋄ tab ← @+9
header ← "kind"∾tab∾"scope_id"∾tab∾"account_key"∾tab∾"plan_id"∾tab∾"excluded_amount"∾tab∾"currency"∾tab∾"reservation_ref"
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿row‿message:
  {severity⇐"error",stage⇐"application_daily_scope_admission",code⇐code,source_row⇐row,message⇐message}
}
EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,kind⇐empty,scope_id⇐empty,account_key⇐empty,plan_id⇐empty,
    excluded_coefficient⇐empty,excluded_scale⇐empty,currency⇐empty,reservation_ref⇐empty,
    source_row⇐empty,source_ref⇐empty
  }
}
Admit ← {𝕊 lines‿registry:
  diagnostics ← empty
  hasHeader ← 0<≠lines ⋄ headerValid ← 0
  {𝕊:headerValid↩(⊑lines)≡header}⍟hasHeader @
  diagnostics∾↩(¬hasHeader)/⟨Diagnostic ⟨"daily_scope_header_missing",0,"daily scope source requires exact header"⟩⟩
  diagnostics∾↩(hasHeader ∧ ¬headerValid)/⟨Diagnostic ⟨"daily_scope_header_invalid",1,"daily scope header is not exact"⟩⟩

  AdmitRow ← {𝕊 i:
    sourceRow ← i+1 ⋄ fields ← tab parse.SplitKeepEmpty i⊑lines
    rowDiagnostics ← empty ⋄ items ← empty
    rowDiagnostics∾↩(7≠≠fields)/⟨Diagnostic ⟨"daily_scope_row_shape_invalid",sourceRow,"daily scope row requires seven fields"⟩⟩
    {𝕊:
      kind‿scopeId‿accountKey‿planId‿amountText‿currency‿reservationRef ← fields
      knownKind ← Contains ⟨kind,⟨"asset","obligation"⟩⟩
      rowDiagnostics∾↩(¬knownKind)/⟨Diagnostic ⟨"daily_scope_kind_invalid",sourceRow,"kind must be asset or obligation"⟩⟩
      rowDiagnostics∾↩(0=≠scopeId)/⟨Diagnostic ⟨"daily_scope_id_empty",sourceRow,"scope_id must be nonempty"⟩⟩
      coefficient ← 0 ⋄ scale ← 0
      {𝕊:
        shapeInvalid ← (0=≠accountKey) ∨ (0<≠planId) ∨ (0<≠amountText) ∨ (0<≠currency) ∨ 0<≠reservationRef
        rowDiagnostics∾↩shapeInvalid/⟨Diagnostic ⟨"daily_asset_shape_invalid",sourceRow,"asset requires only scope_id and account_key"⟩⟩
      }⍟(kind≡"asset") @
      {𝕊:
        rowDiagnostics∾↩((0<≠accountKey) ∨ 0=≠planId)/⟨Diagnostic ⟨"daily_obligation_shape_invalid",sourceRow,"obligation requires plan_id and no account_key"⟩⟩
        reservationPresent ← 0<≠amountText
        paired ← reservationPresent=(0<≠currency)
        rowDiagnostics∾↩(¬paired)/⟨Diagnostic ⟨"daily_reservation_currency_pair_invalid",sourceRow,"excluded amount and currency must be paired"⟩⟩
        referenceMismatch ← (0<≠reservationRef)≠reservationPresent
        rowDiagnostics∾↩referenceMismatch/⟨
          Diagnostic ⟨"daily_reservation_reference_invalid",sourceRow,"reservation_ref must accompany excluded amount"⟩
        ⟩
        {𝕊:
          parsed ← exact.Parse amountText ⋄ policy ← registry.Policy currency
          valid ← (parsed.state≡"ok") ∧ (policy.state≡"ok")
          {𝕊:
            finite ← policy.max_fraction_digits≠¯1
            valid↩(¬finite) ∨ parsed.scale≤policy.max_fraction_digits
          }⍟valid @
          rowDiagnostics∾↩(¬valid)/⟨Diagnostic ⟨"daily_reservation_amount_invalid",sourceRow,"excluded amount must be positive exact currency amount"⟩⟩
          {𝕊:
            rowDiagnostics∾↩(parsed.coefficient≤0)/⟨Diagnostic ⟨"daily_reservation_amount_invalid",sourceRow,"excluded amount must be positive"⟩⟩
            coefficient↩parsed.coefficient ⋄ scale↩parsed.scale
          }⍟valid @
        }⍟reservationPresent @
      }⍟(kind≡"obligation") @
      {𝕊:
        items↩⟨{
          kind⇐kind,scope_id⇐scopeId,account_key⇐accountKey,plan_id⇐planId,
          excluded_coefficient⇐coefficient,excluded_scale⇐scale,currency⇐currency,
          reservation_ref⇐reservationRef,source_row⇐sourceRow,
          source_ref⇐"daily_target_scope.tsv:row:"∾•Fmt sourceRow
        }⟩
      }⍟(0=≠rowDiagnostics) @
    }⍟(7=≠fields) @
    {diagnostics⇐rowDiagnostics,items⇐items}
  }

  rowResults ← AdmitRow¨1↓↕≠lines
  diagnostics∾↩∾{𝕩.diagnostics}¨rowResults
  admitted ← ∾{𝕩.items}¨rowResults
  ids ← {𝕩.scope_id}¨admitted
  diagnostics∾↩((≠ids)≠≠⍷ids)/⟨Diagnostic ⟨"daily_scope_id_duplicate",0,"scope_id must be unique"⟩⟩
  reservationRefs ← ({0<≠𝕩.reservation_ref}¨admitted)/{𝕩.reservation_ref}¨admitted
  diagnostics∾↩((≠reservationRefs)≠≠⍷reservationRefs)/⟨Diagnostic ⟨"daily_reservation_reference_duplicate",0,"reservation_ref cannot be reused"⟩⟩
  rows ← EmptyRows @ ⋄ ok ← 0=≠diagnostics
  {𝕊:
    rows↩{
      count⇐≠admitted,index⇐↕≠admitted,kind⇐{𝕩.kind}¨admitted,scope_id⇐{𝕩.scope_id}¨admitted,
      account_key⇐{𝕩.account_key}¨admitted,plan_id⇐{𝕩.plan_id}¨admitted,
      excluded_coefficient⇐{𝕩.excluded_coefficient}¨admitted,excluded_scale⇐{𝕩.excluded_scale}¨admitted,
      currency⇐{𝕩.currency}¨admitted,reservation_ref⇐{𝕩.reservation_ref}¨admitted,
      source_row⇐{𝕩.source_row}¨admitted,source_ref⇐{𝕩.source_ref}¨admitted
    }
  }⍟ok @
  {state⇐ok⊑"error"‿"ok",rows⇐rows,diagnostics⇐diagnostics}
}

{header⇐header,Admit⇐Admit}
