# Canonical pure structure admission for one already domain-normalized Journal
# transaction partition. It replaces use of a broad historical parser profile in
# complete admission. Currency amount/account proof remains owned by semantic
# admission; this owner validates transaction grammar, metadata, side and identity.

dates ← •Import "date_ordinal.bqn"
empty ← ⟨⟩
lf ← @+10
cr ← @+13
space ← @+32

supportedMetadata ← ⟨
  "action","receipt-id","event-id","layer","plan-id","execution-envelope",
  "allocation-id","agreement-id","actual-event-id","tax","biz","invoice",
  "note","due-on","receipt","txn-id","party","trip-id","payment","cashflow",
  "currency","income-budget","recur","series"
⟩
supportedLayers ← ⟨"actual","plan","budget"⟩

TrimLeft ← {𝕊 xs: (+´∧`xs=space)↓xs }
TrimRight ← {𝕊 xs: ((≠xs)-+´∧`⌽xs=space)↑xs }
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text:
  groups ← (+`sep=text)⊔text
  {(sep≠𝕩)/𝕩}¨groups
}
Split ← {𝕊 sep‿text:
  parts ← SplitKeepEmpty ⟨sep,text⟩
  (0<≠¨parts)/parts
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
StartsWith ← {𝕊 prefix‿text: prefix≡(≠prefix)↑text}
ToNum ← {𝕊 text: +´(text-⊑"0")×10⋆⌽↕≠text}
IsDigits ← {𝕊 text: (0<≠text) ∧ ∧´text∊"0123456789"}
Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_journal_transaction_structure",code⇐codeText,line⇐lineNumber,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
IsDateHeader ← {𝕊 text: (10<≠text) ∧ (space=10⊑(text∾11⥊space)) ∧ dates.IsValid 10↑text}

MetaValues ← {𝕊 key‿metadata: {𝕩.value}¨({key≡𝕩.key}¨metadata)/metadata}
MetaOr ← {𝕊 key‿metadata‿fallback:
  values ← MetaValues ⟨key,metadata⟩
  result ← fallback
  {𝕊: result↩⊑values}⍟(0<≠values) @
  result
}

ParseMetadata ← {𝕊 text‿lineNumber:
  diagnostics ← empty
  content ← Trim 1↓Trim text
  positions ← (':'=content)/↕≠content
  key ← "" ⋄ value ← ""
  diagnostics ∾↩ AddIf ⟨0=≠positions,Diagnostic ⟨"metadata_colon_missing",lineNumber,"metadata must use '; key: value'"⟩⟩
  {𝕊:
    p ← ⊑positions
    key↩Trim p↑content
    value↩Trim (p+1)↓content
  }⍟(0<≠positions) @
  diagnostics ∾↩ AddIf ⟨(0<≠positions) ∧ ((0=≠key) ∨ 0=≠value),Diagnostic ⟨"metadata_shape_invalid",lineNumber,"metadata key and value must be nonempty"⟩⟩
  diagnostics ∾↩ AddIf ⟨(0<≠key) ∧ ¬Contains ⟨key,supportedMetadata⟩,Diagnostic ⟨"metadata_unsupported",lineNumber,"metadata key is not admitted"⟩⟩
  valueOk ← 1
  {𝕊: valueOk↩Contains ⟨value,⟨"private","business","mixed"⟩⟩}⍟(key≡"tax") @
  {𝕊: valueOk↩Contains ⟨value,⟨"0","1"⟩⟩}⍟(key≡"biz") @
  {𝕊: valueOk↩Contains ⟨value,⟨"none","ok"⟩⟩}⍟(key≡"invoice") @
  {𝕊: valueOk↩dates.IsValid value}⍟(key≡"due-on") @
  {𝕊: valueOk↩Contains ⟨value,⟨"cash","card","debit"⟩⟩}⍟(key≡"payment") @
  {𝕊: valueOk↩value≡"fixed_obligation"}⍟(key≡"cashflow") @
  {𝕊: valueOk↩Contains ⟨value,⟨"JPY","ILS","USD"⟩⟩}⍟(key≡"currency") @
  {𝕊: valueOk↩Contains ⟨value,⟨"unassigned","exclude"⟩⟩}⍟(key≡"income-budget") @
  diagnostics ∾↩ AddIf ⟨¬valueOk,Diagnostic ⟨"metadata_value_invalid",lineNumber,"metadata value is not admitted"⟩⟩
  item ← @
  {𝕊: item↩{key⇐key,value⇐value,source_line⇐lineNumber}}⍟(0=≠diagnostics) @
  {diagnostics⇐diagnostics,item⇐item}
}

ParsePosting ← {𝕊 text‿lineNumber:
  diagnostics ← empty
  fields ← Split ⟨space,Trim text⟩
  diagnostics ∾↩ AddIf ⟨3≠≠fields,Diagnostic ⟨"posting_shape_invalid",lineNumber,"posting must contain account, explicit integer amount, and normalized commodity"⟩⟩
  posting ← @
  {𝕊:
    account ← 0⊑fields ⋄ amountText ← 1⊑fields ⋄ commodity ← 2⊑fields
    negative ← '-'=⊑(amountText∾"0")
    magnitudeText ← negative↓amountText
    amountOk ← IsDigits magnitudeText
    coefficient ← 0
    {𝕊: coefficient↩(1-2×negative)×ToNum magnitudeText}⍟amountOk @
    diagnostics ∾↩ AddIf ⟨¬amountOk,Diagnostic ⟨"posting_amount_invalid",lineNumber,"normalized structural amount must be an exact integer"⟩⟩
    diagnostics ∾↩ AddIf ⟨amountOk ∧ 0=coefficient,Diagnostic ⟨"posting_amount_zero",lineNumber,"posting amount must be nonzero"⟩⟩
    diagnostics ∾↩ AddIf ⟨commodity≢"JPY",Diagnostic ⟨"posting_structural_commodity_invalid",lineNumber,"normalized structural commodity must be JPY"⟩⟩
    {𝕊: posting↩{account_key⇐account,delta⇐coefficient,commodity⇐commodity,amount_text⇐amountText,source_line⇐lineNumber}}⍟(0=≠diagnostics) @
  }⍟(3=≠fields) @
  {diagnostics⇐diagnostics,posting⇐posting}
}

Parse ← {𝕊 raw:
  lines ← SplitKeepEmpty ⟨lf,(cr≠raw)/raw⟩
  starts ← (IsDateHeader¨Trim¨lines)/↕≠lines
  diagnostics ← empty
  trimmedLines ← Trim¨lines
  declaredAccounts ← {8↓𝕩}¨({StartsWith ⟨"account ",𝕩⟩}¨trimmedLines)/trimmedLines
  declaredCommodities ← {10↓𝕩}¨({StartsWith ⟨"commodity ",𝕩⟩}¨trimmedLines)/trimmedLines
  diagnostics ∾↩ AddIf ⟨(≠declaredAccounts)≠≠⍷declaredAccounts,Diagnostic ⟨"account_duplicate",0,"account declarations must be unique"⟩⟩
  diagnostics ∾↩ AddIf ⟨⟨"JPY"⟩≢declaredCommodities,Diagnostic ⟨"commodity_declaration_invalid",0,"normalized partition must declare JPY exactly once"⟩⟩
  diagnostics ∾↩ AddIf ⟨1≠≠starts,Diagnostic ⟨"transaction_count_invalid",0,"one normalized partition must contain exactly one transaction"⟩⟩
  transaction ← @
  {𝕊:
    start ← ⊑starts
    headerText ← Trim start⊑lines
    rawTail ← TrimLeft 10↓start⊑lines
    tail ← TrimLeft 10↓headerText
    marker ← ⊑(tail∾" ")
    delimiter ← space=1⊑(rawTail∾"  ")
    description ← (1+delimiter)↓tail
    diagnostics ∾↩ AddIf ⟨¬marker∊"*!",Diagnostic ⟨"header_status_invalid",start+1,"transaction status must be * or !"⟩⟩
    diagnostics ∾↩ AddIf ⟨¬delimiter,Diagnostic ⟨"header_description_delimiter_missing",start+1,"status must be followed by one ASCII space"⟩⟩
    diagnostics ∾↩ AddIf ⟨0=≠description,Diagnostic ⟨"header_description_missing",start+1,"transaction description must be nonempty"⟩⟩

    nonblank ← (0<≠¨Trim¨lines)/↕≠lines
    finish ← 1+⊑⌽nonblank
    metadata ← empty ⋄ rawPostings ← empty
    bodyCount ← 0⌈(finish-start)-1
    bodyIndices ← (start+1)+↕bodyCount
    {𝕊 i:
      original ← i⊑lines
      trimmed ← Trim original
      indented ← space=⊑(original∾" ")
      isMetadata ← ';'=⊑(trimmed∾";")
      diagnostics ∾↩ AddIf ⟨¬indented,Diagnostic ⟨"transaction_body_not_indented",i+1,"transaction metadata and postings must be indented"⟩⟩
      {𝕊:
        parsed ← ParseMetadata ⟨original,i+1⟩
        diagnostics ∾↩ parsed.diagnostics
        {𝕊: metadata∾↩⟨parsed.item⟩}⍟(parsed.item≢@) @
      }⍟(indented ∧ isMetadata) @
      {𝕊:
        parsed ← ParsePosting ⟨original,i+1⟩
        diagnostics ∾↩ parsed.diagnostics
        {𝕊: rawPostings∾↩⟨parsed.posting⟩}⍟(parsed.posting≢@) @
      }⍟(indented ∧ ¬isMetadata) @
    }¨ bodyIndices

    {𝕊 posting:
      diagnostics ∾↩ AddIf ⟨¬Contains ⟨posting.account_key,declaredAccounts⟩,Diagnostic ⟨"posting_account_unknown",posting.source_line,"posting account must be declared in the Journal"⟩⟩
    }¨rawPostings
    keys ← {𝕩.key}¨metadata
    diagnostics ∾↩ AddIf ⟨(≠keys)≠≠⍷keys,Diagnostic ⟨"metadata_duplicate",start+1,"metadata keys must be unique within one transaction"⟩⟩
    layer ← MetaOr ⟨"layer",metadata,"actual"⟩
    eventId ← MetaOr ⟨"event-id",metadata,""⟩
    planId ← MetaOr ⟨"plan-id",metadata,""⟩
    allocationId ← MetaOr ⟨"allocation-id",metadata,""⟩
    executionEnvelope ← MetaOr ⟨"execution-envelope",metadata,""⟩
    actualEventId ← MetaOr ⟨"actual-event-id",metadata,""⟩
    txnId ← MetaOr ⟨"txn-id",metadata,""⟩
    diagnostics ∾↩ AddIf ⟨¬Contains ⟨layer,supportedLayers⟩,Diagnostic ⟨"layer_unsupported",start+1,"layer must be actual, plan, or budget"⟩⟩
    diagnostics ∾↩ AddIf ⟨(layer≡"plan") ∧ 0=≠eventId,Diagnostic ⟨"plan_event_id_missing",start+1,"plan events require event-id"⟩⟩
    diagnostics ∾↩ AddIf ⟨(layer≡"plan") ∧ 0=≠planId,Diagnostic ⟨"plan_id_missing",start+1,"plan events require plan-id"⟩⟩
    budgetLinkCount ← (0<≠allocationId) + 0<≠actualEventId
    diagnostics ∾↩ AddIf ⟨(layer≡"budget") ∧ 0=≠eventId,Diagnostic ⟨"budget_event_id_missing",start+1,"budget events require event-id"⟩⟩
    diagnostics ∾↩ AddIf ⟨(layer≡"budget") ∧ 0=budgetLinkCount,Diagnostic ⟨"budget_link_missing",start+1,"budget events require allocation-id or actual-event-id"⟩⟩
    diagnostics ∾↩ AddIf ⟨(layer≡"budget") ∧ 1<budgetLinkCount,Diagnostic ⟨"budget_link_ambiguous",start+1,"budget events require exactly one link"⟩⟩
    diagnostics ∾↩ AddIf ⟨(layer≢"budget") ∧ 0<≠actualEventId,Diagnostic ⟨"actual_event_link_layer_invalid",start+1,"actual-event-id is valid only on budget events"⟩⟩
    diagnostics ∾↩ AddIf ⟨0=≠rawPostings,Diagnostic ⟨"posting_missing",start+1,"transaction must contain postings"⟩⟩
    diagnostics ∾↩ AddIf ⟨0≠+´0∾{𝕩.delta}¨rawPostings,Diagnostic ⟨"event_unbalanced",start+1,"transaction postings must sum to zero"⟩⟩

    sourceEventId ← eventId ⋄ identityKind ← "durable"
    {𝕊: sourceEventId↩"stage0-line-"∾•Fmt start+1 ⋄ identityKind↩"physical_fallback"}⍟(0=≠eventId) @
    postings ← {𝕊 i:
      rawPosting ← i⊑rawPostings
      {
        account_key⇐rawPosting.account_key,delta⇐rawPosting.delta,commodity⇐rawPosting.commodity,
        amount_text⇐rawPosting.amount_text,side⇐(0<rawPosting.delta)⊑"credit"‿"debit",
        posting_index⇐i,posting_id⇐sourceEventId∾":"∾•Fmt i,source_line⇐rawPosting.source_line
      }
    }¨↕≠rawPostings
    {𝕊:
      transaction↩{
        source_event_id⇐sourceEventId,identity_kind⇐identityKind,
        source_start_line⇐start+1,source_end_line⇐finish,date⇐10↑headerText,
        status_marker⇐marker,description⇐description,layer_name⇐layer,txn_id⇐txnId,
        plan_id⇐planId,allocation_id⇐allocationId,execution_envelope⇐executionEnvelope,
        actual_event_id⇐actualEventId,metadata⇐metadata,postings⇐postings
      }
    }⍟(0=≠diagnostics) @
  }⍟(1=≠starts) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",diagnostics⇐diagnostics,transactions⇐(transaction≢@)/⟨transaction⟩}
}

{Parse⇐Parse}
