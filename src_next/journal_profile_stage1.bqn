# journal_profile_stage1.bqn
# Test-only parser for the public Minimal BQN Journal Profile Stage 0 subset.
#
# This module is deliberately not connected to production source routing.
# It parses declarations and explicit journal transaction blocks into a small
# Transaction IR, fails closed on unsupported or ambiguous evidence, and can
# project valid transactions into a signed event x account matrix.

util ← •Import "util.bqn"
decimal ← •Import "exact_decimal.bqn"
dates ← •Import "date.bqn"

empty ← ⟨⟩
lf ← @+10
cr ← @+13
space ← @+32

supportedMetadata ← ⟨
  <"action", <"receipt-id", <"event-id", <"layer", <"plan-id",
  <"execution-envelope", <"allocation-id", <"agreement-id"
⟩
supportedLayers ← ⟨<"actual", <"plan", <"budget"⟩

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error", stage⇐"journal_profile_stage1", code⇐codeText, line⇐lineNumber, message⇐messageText}
}

AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

TrimLeft ← {𝕊 xs:
  prefix ← ∧` (xs = space)
  (+´ prefix) ↓ xs
}

TrimRight ← {𝕊 xs:
  suffix ← ∧` ((⌽ xs) = space)
  ((≠ xs) - +´ suffix) ↑ xs
}

Trim ← { TrimRight TrimLeft 𝕩 }

StartsWith ← {𝕊 prefix‿text:
  prefix ≡ (≠ prefix) ↑ text
}

IsOneOf ← {𝕊 text‿boxedValues:
  ∨´ 0 ∾ {text ≡ >𝕩}¨ boxedValues
}

Paragraphs ← {𝕊 raw:
  cleaned ← (cr ≠ raw) / raw
  lines ← <¨ (lf util.SplitKeepEmpty cleaned)
  groups ← empty
  current ← empty
  startLine ← 0

  Flush ← {𝕊 endLine:
    {𝕊:
      groups ∾↩ ⟨{lines⇐current, start_line⇐startLine, end_line⇐endLine}⟩
      current ↩ empty
    }⍟(0 < ≠ current) @
  }

  {𝕊 i:
    line ← > i ⊑ lines
    blank ← 0 = ≠ Trim line
    {𝕊: Flush i}⍟blank @
    {𝕊:
      {𝕊: startLine ↩ i + 1}⍟(0 = ≠ current) @
      current ∾↩ ⟨<line⟩
    }⍟(¬ blank) @
  }¨ ↕ ≠ lines

  Flush ≠ lines
  groups
}

FirstLine ← { Trim > ⊑ 𝕩.lines }

IsDateHeader ← {𝕊 text:
  enough ← 10 < ≠ text
  separator ← space = 10 ⊑ (text ∾ " ")
  enough ∧ separator ∧ dates.IsValidDateText 10 ↑ text
}

ParseHeader ← {𝕊 group:
  text ← FirstLine group
  dateText ← 10 ↑ text
  tail ← TrimLeft 10 ↓ text
  marker ← ⊑ (tail ∾ " ")
  description ← TrimLeft 1 ↓ tail
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬ dates.IsValidDateText dateText, Diagnostic ⟨"header_date_invalid", group.start_line, "transaction header date must be a valid YYYY-MM-DD date"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ marker ∊ "*!", Diagnostic ⟨"header_status_invalid", group.start_line, "transaction header status must be * or !"⟩⟩
  diagnostics ∾↩ AddIf ⟨0 = ≠ description, Diagnostic ⟨"header_description_missing", group.start_line, "transaction header description must be nonempty"⟩⟩
  {date⇐dateText, status_marker⇐marker, description⇐description, diagnostics⇐diagnostics}
}

ParseDeclarations ← {𝕊 groups:
  diagnostics ← empty
  accounts ← empty
  commodities ← empty
  transactionGroups ← empty

  {𝕊 group:
    first ← FirstLine group
    isComment ← ';' = ⊑ (first ∾ ";")
    isCommodity ← StartsWith ⟨"commodity ", first⟩
    isAccount ← StartsWith ⟨"account ", first⟩
    isTransaction ← IsDateHeader first
    recognized ← isComment ∨ isCommodity ∨ isAccount ∨ isTransaction

    diagnostics ∾↩ AddIf ⟨¬ recognized, Diagnostic ⟨"unsupported_group", group.start_line, "unsupported top-level journal group"⟩⟩

    {𝕊:
      fields ← space util.Split first
      validShape ← 2 = ≠ fields
      commodityText ← ""
      {𝕊: commodityText ↩ 1 ⊑ fields}⍟validShape @
      diagnostics ∾↩ AddIf ⟨¬ validShape, Diagnostic ⟨"commodity_shape_invalid", group.start_line, "commodity declaration must contain exactly one commodity"⟩⟩
      diagnostics ∾↩ AddIf ⟨validShape ∧ commodityText ≢ "JPY", Diagnostic ⟨"commodity_unsupported", group.start_line, "Stage 1 supports only JPY declarations"⟩⟩
      {𝕊: commodities ∾↩ ⟨{commodity⇐commodityText, source_line⇐group.start_line}⟩}⍟(validShape ∧ commodityText ≡ "JPY") @
    }⍟isCommodity @

    {𝕊:
      key ← Trim (≠ "account ") ↓ first
      body ← 1 ↓ group.lines
      bodyValid ← ∧´ {𝕊 lineBox: ';' = ⊑ ((Trim >lineBox) ∾ ";") }¨ body
      diagnostics ∾↩ AddIf ⟨(0 = ≠ key) ∨ (space ∊ key), Diagnostic ⟨"account_key_invalid", group.start_line, "account declaration must contain one nonempty account key"⟩⟩
      diagnostics ∾↩ AddIf ⟨¬ bodyValid, Diagnostic ⟨"account_body_unsupported", group.start_line, "account declaration body may contain comment metadata only"⟩⟩
      {𝕊: accounts ∾↩ ⟨{account_key⇐key, source_line⇐group.start_line}⟩}⍟((0 < ≠ key) ∧ ¬ space ∊ key ∧ bodyValid) @
    }⍟isAccount @

    {𝕊: transactionGroups ∾↩ ⟨group⟩}⍟isTransaction @
  }¨ groups

  accountKeys ← {<𝕩.account_key}¨ accounts
  commodityKeys ← {<𝕩.commodity}¨ commodities
  diagnostics ∾↩ AddIf ⟨(≠ accountKeys) ≠ ≠ ⍷ accountKeys, Diagnostic ⟨"account_duplicate", 0, "account declarations must be unique"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠ commodityKeys) ≠ ≠ ⍷ commodityKeys, Diagnostic ⟨"commodity_duplicate", 0, "commodity declarations must be unique"⟩⟩
  diagnostics ∾↩ AddIf ⟨0 = ≠ commodities, Diagnostic ⟨"commodity_missing", 0, "Stage 1 requires a JPY commodity declaration"⟩⟩

  {diagnostics⇐diagnostics, accounts⇐accounts, commodities⇐commodities, transaction_groups⇐transactionGroups}
}

HasAccount ← {𝕊 accountKey‿accounts:
  ∨´ 0 ∾ {accountKey ≡ 𝕩.account_key}¨ accounts
}

HasCommodity ← {𝕊 commodityText‿commodities:
  ∨´ 0 ∾ {commodityText ≡ 𝕩.commodity}¨ commodities
}

ParseMetadata ← {𝕊 lineText‿lineNumber:
  diagnostics ← empty
  trimmed ← Trim lineText
  content ← Trim 1 ↓ trimmed
  colonPositions ← (':' = content) / ↕ ≠ content
  key ← ""
  value ← ""
  {𝕊:
    idx ← ⊑ colonPositions
    key ↩ Trim idx ↑ content
    value ↩ Trim (idx + 1) ↓ content
  }⍟(0 < ≠ colonPositions) @
  diagnostics ∾↩ AddIf ⟨0 = ≠ colonPositions, Diagnostic ⟨"metadata_colon_missing", lineNumber, "metadata must use '; key: value'"⟩⟩
  diagnostics ∾↩ AddIf ⟨(0 < ≠ colonPositions) ∧ ((0 = ≠ key) ∨ (0 = ≠ value)), Diagnostic ⟨"metadata_shape_invalid", lineNumber, "metadata key and value must be nonempty"⟩⟩
  diagnostics ∾↩ AddIf ⟨(0 < ≠ key) ∧ ¬ IsOneOf ⟨key, supportedMetadata⟩, Diagnostic ⟨"metadata_unsupported", lineNumber, "unsupported Stage 1 metadata key"⟩⟩
  metadata ← @
  {𝕊: metadata ↩ {key⇐key, value⇐value, source_line⇐lineNumber}}⍟(0 = ≠ diagnostics) @
  {diagnostics⇐diagnostics, metadata⇐metadata}
}

ParsePosting ← {𝕊 lineText‿lineNumber‿accounts‿commodities:
  diagnostics ← empty
  trimmed ← Trim lineText
  fields ← space util.Split trimmed
  validShape ← 3 = ≠ fields
  accountKey ← ""
  amountText ← ""
  commodityText ← ""
  {𝕊:
    accountKey ↩ 0 ⊑ fields
    amountText ↩ 1 ⊑ fields
    commodityText ↩ 2 ⊑ fields
  }⍟validShape @

  diagnostics ∾↩ AddIf ⟨¬ validShape, Diagnostic ⟨"posting_shape_invalid", lineNumber, "posting must contain account, explicit amount, and commodity"⟩⟩

  isNegative ← '-' = ⊑ (amountText ∾ "0")
  unsignedText ← isNegative ↓ amountText
  parsed ← decimal.Parse unsignedText
  exactInteger ← (parsed.state ≡ "ok") ∧ (0 = parsed.scale)
  delta ← 0
  {𝕊: delta ↩ (1 - 2 × isNegative) × parsed.coefficient}⍟exactInteger @

  diagnostics ∾↩ AddIf ⟨validShape ∧ ¬ exactInteger, Diagnostic ⟨"posting_amount_invalid", lineNumber, "posting amount must be an explicit exact integer"⟩⟩
  diagnostics ∾↩ AddIf ⟨validShape ∧ exactInteger ∧ 0 = delta, Diagnostic ⟨"posting_amount_zero", lineNumber, "posting amount must be nonzero"⟩⟩
  diagnostics ∾↩ AddIf ⟨validShape ∧ ¬ HasAccount ⟨accountKey, accounts⟩, Diagnostic ⟨"posting_account_unknown", lineNumber, "posting account must be declared"⟩⟩
  diagnostics ∾↩ AddIf ⟨validShape ∧ ¬ HasCommodity ⟨commodityText, commodities⟩, Diagnostic ⟨"posting_commodity_unknown", lineNumber, "posting commodity must be declared"⟩⟩

  posting ← @
  {𝕊:
    posting ↩ {account_key⇐accountKey, delta⇐delta, commodity⇐commodityText, amount_text⇐amountText, source_line⇐lineNumber}
  }⍟(0 = ≠ diagnostics) @
  {diagnostics⇐diagnostics, posting⇐posting}
}

MetaValues ← {𝕊 key‿metadata:
  mask ← {key ≡ 𝕩.key}¨ metadata
  {𝕩.value}¨ mask / metadata
}

MetaOr ← {𝕊 key‿metadata‿fallback:
  values ← MetaValues ⟨key, metadata⟩
  result ← fallback
  {𝕊: result ↩ ⊑ values}⍟(0 < ≠ values) @
  result
}

ParseTransaction ← {𝕊 group‿accounts‿commodities:
  header ← ParseHeader group
  diagnostics ← header.diagnostics
  metadata ← empty
  rawPostings ← empty
  body ← 1 ↓ group.lines

  {𝕊 i:
    lineText ← > i ⊑ body
    lineNumber ← group.start_line + i + 1
    indented ← space = ⊑ (lineText ∾ " ")
    trimmed ← Trim lineText
    isMetadata ← ';' = ⊑ (trimmed ∾ ";")
    diagnostics ∾↩ AddIf ⟨¬ indented, Diagnostic ⟨"transaction_body_not_indented", lineNumber, "transaction metadata and postings must be indented"⟩⟩

    {𝕊:
      parsedMeta ← ParseMetadata ⟨lineText, lineNumber⟩
      diagnostics ∾↩ parsedMeta.diagnostics
      {𝕊: metadata ∾↩ ⟨parsedMeta.metadata⟩}⍟(parsedMeta.metadata ≢ @) @
    }⍟(indented ∧ isMetadata) @

    {𝕊:
      parsedPosting ← ParsePosting ⟨lineText, lineNumber, accounts, commodities⟩
      diagnostics ∾↩ parsedPosting.diagnostics
      {𝕊: rawPostings ∾↩ ⟨parsedPosting.posting⟩}⍟(parsedPosting.posting ≢ @) @
    }⍟(indented ∧ ¬ isMetadata) @
  }¨ ↕ ≠ body

  metadataKeys ← {<𝕩.key}¨ metadata
  diagnostics ∾↩ AddIf ⟨(≠ metadataKeys) ≠ ≠ ⍷ metadataKeys, Diagnostic ⟨"metadata_duplicate", group.start_line, "metadata keys must be unique within one event"⟩⟩

  layer ← MetaOr ⟨"layer", metadata, "actual"⟩
  eventId ← MetaOr ⟨"event-id", metadata, ""⟩
  planId ← MetaOr ⟨"plan-id", metadata, ""⟩
  allocationId ← MetaOr ⟨"allocation-id", metadata, ""⟩
  executionEnvelope ← MetaOr ⟨"execution-envelope", metadata, ""⟩

  diagnostics ∾↩ AddIf ⟨¬ IsOneOf ⟨layer, supportedLayers⟩, Diagnostic ⟨"layer_unsupported", group.start_line, "layer must be actual, plan, or budget"⟩⟩
  diagnostics ∾↩ AddIf ⟨(layer ≡ "plan") ∧ (0 = ≠ eventId), Diagnostic ⟨"plan_event_id_missing", group.start_line, "plan events require explicit event-id"⟩⟩
  diagnostics ∾↩ AddIf ⟨(layer ≡ "plan") ∧ (0 = ≠ planId), Diagnostic ⟨"plan_id_missing", group.start_line, "plan events require plan-id"⟩⟩
  diagnostics ∾↩ AddIf ⟨(layer ≡ "budget") ∧ (0 = ≠ eventId), Diagnostic ⟨"budget_event_id_missing", group.start_line, "budget events require explicit event-id"⟩⟩
  diagnostics ∾↩ AddIf ⟨(layer ≡ "budget") ∧ (0 = ≠ allocationId), Diagnostic ⟨"allocation_id_missing", group.start_line, "budget events require allocation-id"⟩⟩
  diagnostics ∾↩ AddIf ⟨0 = ≠ rawPostings, Diagnostic ⟨"posting_missing", group.start_line, "transaction must contain at least one posting"⟩⟩
  diagnostics ∾↩ AddIf ⟨0 ≠ +´ 0 ∾ {𝕩.delta}¨ rawPostings, Diagnostic ⟨"event_unbalanced", group.start_line, "transaction posting deltas must sum to zero"⟩⟩

  sourceEventId ← eventId
  identityKind ← "durable"
  {𝕊:
    sourceEventId ↩ "stage0-line-" ∾ •Fmt group.start_line
    identityKind ↩ "physical_fallback"
  }⍟(0 = ≠ eventId) @

  postings ← {
    i ← 𝕩
    rawPosting ← i ⊑ rawPostings
    side ← (0 < rawPosting.delta) ⊑ "credit"‿"debit"
    {
      account_key⇐rawPosting.account_key,
      delta⇐rawPosting.delta,
      commodity⇐rawPosting.commodity,
      amount_text⇐rawPosting.amount_text,
      side⇐side,
      posting_index⇐i,
      posting_id⇐sourceEventId ∾ ":" ∾ •Fmt i,
      source_line⇐rawPosting.source_line
    }
  }¨ ↕ ≠ rawPostings

  transaction ← @
  {𝕊:
    transaction ↩ {
      source_event_id⇐sourceEventId,
      identity_kind⇐identityKind,
      source_start_line⇐group.start_line,
      source_end_line⇐group.end_line,
      date⇐header.date,
      status_marker⇐header.status_marker,
      description⇐header.description,
      layer_name⇐layer,
      plan_id⇐planId,
      allocation_id⇐allocationId,
      execution_envelope⇐executionEnvelope,
      metadata⇐metadata,
      postings⇐postings
    }
  }⍟(0 = ≠ diagnostics) @

  {state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok", diagnostics⇐diagnostics, transaction⇐transaction}
}

CrossLinkDiagnostics ← {𝕊 transactions:
  diagnostics ← empty
  durableTransactions ← ({𝕩.identity_kind ≡ "durable"}¨ transactions) / transactions
  durableIds ← {<𝕩.source_event_id}¨ durableTransactions
  diagnostics ∾↩ AddIf ⟨(≠ durableIds) ≠ ≠ ⍷ durableIds, Diagnostic ⟨"event_id_duplicate", 0, "durable event-id values must be unique"⟩⟩

  plans ← ({𝕩.layer_name ≡ "plan"}¨ transactions) / transactions
  planIds ← {<𝕩.plan_id}¨ plans
  diagnostics ∾↩ AddIf ⟨(≠ planIds) ≠ ≠ ⍷ planIds, Diagnostic ⟨"plan_id_duplicate", 0, "plan-id values must identify one plan event"⟩⟩

  actualCompletions ← ({(𝕩.layer_name ≡ "actual") ∧ 0 < ≠ 𝕩.plan_id}¨ transactions) / transactions
  {𝕊 actual:
    matching ← ({(𝕩.layer_name ≡ "plan") ∧ (𝕩.plan_id ≡ actual.plan_id)}¨ transactions) / transactions
    diagnostics ∾↩ AddIf ⟨1 ≠ ≠ matching, Diagnostic ⟨"plan_completion_target_invalid", actual.source_start_line, "actual plan-id must match exactly one plan event"⟩⟩
    {𝕊:
      plan ← ⊑ matching
      diagnostics ∾↩ AddIf ⟨plan.execution_envelope ≢ actual.execution_envelope, Diagnostic ⟨"execution_envelope_mismatch", actual.source_start_line, "plan and completion execution-envelope values must match"⟩⟩
    }⍟(1 = ≠ matching) @
  }¨ actualCompletions

  diagnostics
}

Parse ← {𝕊 raw:
  groups ← Paragraphs raw
  declarations ← ParseDeclarations groups
  diagnostics ← declarations.diagnostics
  transactions ← empty

  {𝕊 group:
    parsed ← ParseTransaction ⟨group, declarations.accounts, declarations.commodities⟩
    diagnostics ∾↩ parsed.diagnostics
    {𝕊: transactions ∾↩ ⟨parsed.transaction⟩}⍟(parsed.transaction ≢ @) @
  }¨ declarations.transaction_groups

  diagnostics ∾↩ CrossLinkDiagnostics transactions
  {
    state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok",
    diagnostics⇐diagnostics,
    accounts⇐declarations.accounts,
    commodities⇐declarations.commodities,
    transactions⇐transactions
  }
}

BuildMatrix ← {𝕊 transactions‿boxedAccountKeys:
  {
    transaction ← 𝕩
    {
      accountKey ← >𝕩
      mask ← {accountKey ≡ 𝕩.account_key}¨ transaction.postings
      +´ 0 ∾ {𝕩.delta}¨ mask / transaction.postings
    }¨ boxedAccountKeys
  }¨ transactions
}

{
  Parse⇐Parse,
  BuildMatrix⇐BuildMatrix
}
