# Strict pure admission for one fixed-width Plan or Budget TSV source.
# Input: lines, source policy, admitted Account table, currency registry.
# No paths, defaults, report context, clock, or cross-source fallback are accepted.

exact ← •Import "exact_decimal.bqn"
dates ← •Import "date_ordinal.bqn"
empty ← ⟨⟩
tab ← @+9

SplitKeepEmpty ← {𝕊 sep‿text:
  groups ← (+`sep=text)⊔text
  {(sep≠𝕩)/𝕩}¨groups
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result∾↩⟨item⟩}⍟(¬Contains ⟨item,result⟩) @}¨items
  result
}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Ignored ← {𝕊 line: (0=≠line) ∨ ((0<≠line) ∧ ((⊑line)∊"#\\")) }
Diagnostic ← {𝕊 codeText‿row‿messageText:
  {severity⇐"error",stage⇐"ledger_companion_admission",code⇐codeText,source_row⇐row,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
MetaValues ← {𝕊 key‿metadata: {𝕩.value}¨({𝕩.key≡key}¨metadata)/metadata}
MetaOr ← {𝕊 key‿metadata‿fallback:
  values ← MetaValues ⟨key,metadata⟩
  result ← fallback
  {𝕊: result↩⊑values}⍟(1=≠values) @
  result
}

ParseMetadata ← {𝕊 token‿row‿knownKeys:
  diagnostics ← empty
  positions ← ('='=token)/↕≠token
  key ← "" ⋄ value ← ""
  diagnostics ∾↩ AddIf ⟨1≠≠positions,Diagnostic ⟨"companion_metadata_shape_invalid",row,"metadata must use one key=value separator"⟩⟩
  {𝕊: p←⊑positions ⋄ key↩p↑token ⋄ value↩(p+1)↓token}⍟(1=≠positions) @
  diagnostics ∾↩ AddIf ⟨(1=≠positions) ∧ ((0=≠key) ∨ 0=≠value),Diagnostic ⟨"companion_metadata_shape_invalid",row,"metadata key and value must be nonempty"⟩⟩
  diagnostics ∾↩ AddIf ⟨(0<≠key) ∧ ¬Contains ⟨key,knownKeys⟩,Diagnostic ⟨"companion_metadata_unsupported",row,"metadata key is not admitted for this source"⟩⟩
  item ← @
  {𝕊: item↩{key⇐key,value⇐value}}⍟(0=≠diagnostics) @
  {diagnostics⇐diagnostics,item⇐item}
}

# policy fields:
#   source_name, layer_name, require_plan_id, known_metadata
Admit ← {𝕊 lines‿policy‿accounts‿registry:
  diagnostics ← empty
  transactions ← empty
  domains ← empty
  accountKeys ← accounts.key
  accountCurrencies ← accounts.currency

  {𝕊 i:
    line ← i⊑lines
    {𝕊:
      row ← i+1
      fields ← SplitKeepEmpty ⟨tab,line⟩
      rowDiagnostics ← empty
      rowDiagnostics ∾↩ AddIf ⟨5>≠fields,Diagnostic ⟨"companion_field_count_invalid",row,"row requires date, memo, from account, to account, and amount"⟩⟩
      date ← "" ⋄ memo ← "" ⋄ fromAccount ← "" ⋄ toAccount ← "" ⋄ amountText ← ""
      metadataTokens ← empty
      {𝕊:
        date↩0⊑fields ⋄ memo↩1⊑fields ⋄ fromAccount↩2⊑fields ⋄ toAccount↩3⊑fields ⋄ amountText↩4⊑fields
        metadataTokens↩5↓fields
      }⍟(5≤≠fields) @
      rowDiagnostics ∾↩ AddIf ⟨¬dates.IsValid date,Diagnostic ⟨"companion_date_invalid",row,"date must be strict valid ISO Gregorian text"⟩⟩
      rowDiagnostics ∾↩ AddIf ⟨0=≠memo,Diagnostic ⟨"companion_memo_empty",row,"memo must be nonempty"⟩⟩
      rowDiagnostics ∾↩ AddIf ⟨0=≠fromAccount,Diagnostic ⟨"companion_from_account_empty",row,"from account must be nonempty"⟩⟩
      rowDiagnostics ∾↩ AddIf ⟨0=≠toAccount,Diagnostic ⟨"companion_to_account_empty",row,"to account must be nonempty"⟩⟩

      metadata ← empty
      {𝕊 token:
        parsedMeta ← ParseMetadata ⟨token,row,policy.known_metadata⟩
        rowDiagnostics ∾↩ parsedMeta.diagnostics
        {𝕊: metadata∾↩⟨parsedMeta.item⟩}⍟(parsedMeta.item≢@) @
      }¨metadataTokens
      metadataKeys ← {𝕩.key}¨metadata
      rowDiagnostics ∾↩ AddIf ⟨(≠metadataKeys)≠≠Unique metadataKeys,Diagnostic ⟨"companion_metadata_duplicate",row,"metadata keys must be unique"⟩⟩

      currency ← MetaOr ⟨"currency",metadata,""⟩
      planId ← MetaOr ⟨"plan_id",metadata,""⟩
      rowDiagnostics ∾↩ AddIf ⟨0=≠currency,Diagnostic ⟨"companion_currency_missing",row,"row currency must be explicit"⟩⟩
      currencyPolicy ← registry.Policy currency
      rowDiagnostics ∾↩ AddIf ⟨(0<≠currency) ∧ currencyPolicy.state≢"ok",Diagnostic ⟨"companion_currency_unsupported",row,"row currency must be registry-supported"⟩⟩
      rowDiagnostics ∾↩ AddIf ⟨policy.require_plan_id ∧ 0=≠planId,Diagnostic ⟨"plan_id_missing",row,"Plan row requires durable plan_id metadata"⟩⟩

      amount ← exact.Parse amountText
      rowDiagnostics ∾↩ AddIf ⟨amount.state≢"ok",Diagnostic ⟨"companion_amount_invalid",row,"amount must be an exact unsigned decimal"⟩⟩
      {𝕊:
        rowDiagnostics ∾↩ AddIf ⟨amount.coefficient≤0,Diagnostic ⟨"companion_amount_nonpositive",row,"amount must be greater than zero"⟩⟩
        rowDiagnostics ∾↩ AddIf ⟨(currencyPolicy.state≡"ok") ∧ (currencyPolicy.max_fraction_digits≠¯1) ∧ amount.scale>currencyPolicy.max_fraction_digits,Diagnostic ⟨"companion_amount_precision_exceeded",row,"amount precision exceeds currency policy"⟩⟩
      }⍟(amount.state≡"ok") @

      fromKnown ← Contains ⟨fromAccount,accountKeys⟩
      toKnown ← Contains ⟨toAccount,accountKeys⟩
      rowDiagnostics ∾↩ AddIf ⟨¬fromKnown,Diagnostic ⟨"companion_from_account_unknown",row,"from account must occur in admitted Account facts"⟩⟩
      rowDiagnostics ∾↩ AddIf ⟨¬toKnown,Diagnostic ⟨"companion_to_account_unknown",row,"to account must occur in admitted Account facts"⟩⟩
      {𝕊:
        fromCurrency ← (IndexOf ⟨fromAccount,accountKeys⟩)⊑accountCurrencies
        rowDiagnostics∾↩AddIf ⟨fromCurrency≢currency,Diagnostic ⟨"companion_from_account_currency_mismatch",row,"from account currency must equal row currency"⟩⟩
      }⍟(fromKnown ∧ 0<≠currency) @
      {𝕊:
        toCurrency ← (IndexOf ⟨toAccount,accountKeys⟩)⊑accountCurrencies
        rowDiagnostics∾↩AddIf ⟨toCurrency≢currency,Diagnostic ⟨"companion_to_account_currency_mismatch",row,"to account currency must equal row currency"⟩⟩
      }⍟(toKnown ∧ 0<≠currency) @

      diagnostics ∾↩ rowDiagnostics
      {𝕊:
        sourceId ← policy.source_name∾":row:"∾•Fmt row
        identityKind ← "physical_snapshot"
        {𝕊: sourceId↩policy.source_name∾":plan_id:"∾planId ⋄ identityKind↩"durable_relation"}⍟policy.require_plan_id @
        debit ← {
          account_key⇐toAccount,normalized_coefficient⇐amount.coefficient,
          source_coefficient⇐amount.coefficient,source_scale⇐amount.scale,amount_text⇐amountText,
          side⇐"debit",posting_index⇐0,posting_id⇐sourceId∾":0",source_line⇐row
        }
        credit ← {
          account_key⇐fromAccount,normalized_coefficient⇐-amount.coefficient,
          source_coefficient⇐-amount.coefficient,source_scale⇐amount.scale,amount_text⇐amountText,
          side⇐"credit",posting_index⇐1,posting_id⇐sourceId∾":1",source_line⇐row
        }
        transactions∾↩⟨{
          source_event_id⇐sourceId,identity_kind⇐identityKind,source_start_line⇐row,source_end_line⇐row,
          date⇐date,status_marker⇐"",description⇐memo,layer_name⇐policy.layer_name,
          txn_id⇐"",plan_id⇐planId,allocation_id⇐"",execution_envelope⇐"",actual_event_id⇐"",
          metadata⇐metadata,domain⇐currency,calculation_scale⇐amount.scale,postings⇐⟨debit,credit⟩
        }⟩
        {𝕊: domains∾↩⟨currency⟩}⍟(¬Contains ⟨currency,domains⟩) @
      }⍟(0=≠rowDiagnostics) @
    }⍟(¬Ignored line) @
  }¨↕≠lines

  ids ← {𝕩.source_event_id}¨transactions
  diagnostics ∾↩ AddIf ⟨(≠ids)≠≠Unique ids,Diagnostic ⟨"companion_identity_duplicate",0,"canonical companion transaction identities must be unique"⟩⟩
  hasError ← 0<≠diagnostics
  admittedTransactions ← hasError⊑transactions‿empty
  admittedDomains ← hasError⊑domains‿empty
  {
    state⇐hasError⊑"ok"‿"error",transactions⇐admittedTransactions,
    declared_domains⇐admittedDomains,
    source_name⇐policy.source_name,layer_name⇐policy.layer_name,diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
