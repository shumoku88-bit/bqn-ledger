# Strict pure accounts.tsv admission for canonical ledger facts.
# Currency is mandatory; role may be absent only as explicit unclassified evidence.

empty ← ⟨⟩
tab ← @+9
knownMetadata ← ⟨
  "role","currency","type","budget","budget_group","spend_class","kind",
  "envelope_role","fixed","group","due_day","due_month_offset","payment_account"
⟩

SplitKeepEmpty ← {𝕊 sep‿text:
  groups ← (+`sep=text)⊔text
  {(sep≠𝕩)/𝕩}¨groups
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Ignored ← {𝕊 line: (0=≠line) ∨ ((0<≠line) ∧ ((⊑line)∊"#\\")) }
Diagnostic ← {𝕊 severityText‿codeText‿row‿messageText:
  {severity⇐severityText,stage⇐"ledger_account_admission",code⇐codeText,source_row⇐row,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyAccounts ← {𝕊:
  {
    count⇐0,index⇐empty,key⇐empty,currency⇐empty,role⇐empty,type⇐empty,
    budget⇐empty,budget_group⇐empty,spend_class⇐empty,kind⇐empty,
    envelope_role⇐empty,metadata⇐empty,source_row⇐empty
  }
}
MetaValues ← {𝕊 key‿metadata: {𝕩.value}¨({𝕩.key≡key}¨metadata)/metadata}
MetaOr ← {𝕊 key‿metadata‿fallback:
  values ← MetaValues ⟨key,metadata⟩
  result ← fallback
  {𝕊: result↩⊑values}⍟(1=≠values) @
  result
}

ParseMetadata ← {𝕊 token‿row:
  diagnostics ← empty
  positions ← ('='=token)/↕≠token
  key ← "" ⋄ value ← ""
  diagnostics ∾↩ AddIf ⟨1≠≠positions,Diagnostic ⟨"error","account_metadata_shape_invalid",row,"account metadata must use one key=value separator"⟩⟩
  {𝕊:
    p ← ⊑positions
    key↩p↑token ⋄ value↩(p+1)↓token
  }⍟(1=≠positions) @
  diagnostics ∾↩ AddIf ⟨(1=≠positions) ∧ ((0=≠key) ∨ 0=≠value),Diagnostic ⟨"error","account_metadata_shape_invalid",row,"account metadata key and value must be nonempty"⟩⟩
  diagnostics ∾↩ AddIf ⟨(0<≠key) ∧ ¬Contains ⟨key,knownMetadata⟩,Diagnostic ⟨"error","account_metadata_unsupported",row,"account metadata key is not admitted"⟩⟩
  item ← @
  {𝕊: item↩{key⇐key,value⇐value}}⍟(0=≠diagnostics) @
  {diagnostics⇐diagnostics,item⇐item}
}

Admit ← {𝕊 lines‿registry:
  diagnostics ← empty
  rows ← empty
  {𝕊 i:
    line ← i⊑lines
    row ← i+1
    {𝕊:
      fields ← SplitKeepEmpty ⟨tab,line⟩
      key ← ⊑fields
      rowDiagnostics ← empty
      rowDiagnostics ∾↩ AddIf ⟨0=≠key,Diagnostic ⟨"error","account_key_empty",row,"account key must be nonempty"⟩⟩
      rowDiagnostics ∾↩ AddIf ⟨∨´0∾' '=key,Diagnostic ⟨"error","account_key_space_invalid",row,"account key must not contain ASCII spaces"⟩⟩
      metadata ← empty
      {𝕊 token:
        parsed ← ParseMetadata ⟨token,row⟩
        rowDiagnostics ∾↩ parsed.diagnostics
        {𝕊: metadata∾↩⟨parsed.item⟩}⍟(parsed.item≢@) @
      }¨1↓fields
      metadataKeys ← {𝕩.key}¨metadata
      rowDiagnostics ∾↩ AddIf ⟨(≠metadataKeys)≠≠⍷metadataKeys,Diagnostic ⟨"error","account_metadata_duplicate",row,"account metadata keys must be unique"⟩⟩
      currency ← MetaOr ⟨"currency",metadata,""⟩
      role ← MetaOr ⟨"role",metadata,""⟩
      rowDiagnostics ∾↩ AddIf ⟨0=≠currency,Diagnostic ⟨"error","account_currency_missing",row,"account currency must be explicit"⟩⟩
      policy ← registry.Policy currency
      rowDiagnostics ∾↩ AddIf ⟨(0<≠currency) ∧ policy.state≢"ok",Diagnostic ⟨"error","account_currency_unsupported",row,"account currency must be registry-supported"⟩⟩
      {𝕊: rowDiagnostics∾↩⟨Diagnostic ⟨"warning","account_role_unclassified",row,"missing role remains unclassified"⟩⟩}⍟(0=≠role) @
      diagnostics ∾↩ rowDiagnostics
      hasError ← ∨´0∾{𝕩.severity≡"error"}¨rowDiagnostics
      {𝕊:
        rows∾↩⟨{
          key⇐key,currency⇐currency,role⇐role,
          type⇐MetaOr ⟨"type",metadata,""⟩,
          budget⇐MetaOr ⟨"budget",metadata,""⟩,
          budget_group⇐MetaOr ⟨"budget_group",metadata,""⟩,
          spend_class⇐MetaOr ⟨"spend_class",metadata,""⟩,
          kind⇐MetaOr ⟨"kind",metadata,""⟩,
          envelope_role⇐MetaOr ⟨"envelope_role",metadata,""⟩,
          metadata⇐metadata,source_row⇐row
        }⟩
      }⍟(¬hasError) @
    }⍟(¬Ignored line) @
  }¨↕≠lines

  keys ← {𝕩.key}¨rows
  duplicate ← (≠keys)≠≠⍷keys
  diagnostics ∾↩ AddIf ⟨duplicate,Diagnostic ⟨"error","account_key_duplicate",0,"account keys must be unique"⟩⟩
  hasError ← ∨´0∾{𝕩.severity≡"error"}¨diagnostics
  accounts ← EmptyAccounts @
  {𝕊:
    accounts↩{
      count⇐≠rows,index⇐↕≠rows,key⇐{𝕩.key}¨rows,currency⇐{𝕩.currency}¨rows,
      role⇐{𝕩.role}¨rows,type⇐{𝕩.type}¨rows,budget⇐{𝕩.budget}¨rows,
      budget_group⇐{𝕩.budget_group}¨rows,spend_class⇐{𝕩.spend_class}¨rows,
      kind⇐{𝕩.kind}¨rows,envelope_role⇐{𝕩.envelope_role}¨rows,
      metadata⇐{𝕩.metadata}¨rows,source_row⇐{𝕩.source_row}¨rows
    }
  }⍟(¬hasError) @
  {state⇐hasError⊑"ok"‿"error",accounts⇐accounts,diagnostics⇐diagnostics}
}

{Admit⇐Admit}
