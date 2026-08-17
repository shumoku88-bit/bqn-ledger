# Strict source-local admission for canonical entitlement.journal.
#
# Grammar:
#   YYYY-MM-DD origin COMMODITY [memo]
#   YYYY-MM-DD transfer FROM -> TO QUANTITY COMMODITY [memo]
#
# Endpoints:
#   unallocated | <EnvelopeId>
#
# Output relation:
#   O axis (source order): date, date_ordinal, commodity, memo, source_line, source_event_id
#   T axis (source order): date, date_ordinal, from, to, amount_text,
#                          coefficient, scale, commodity, memo, source_line, source_event_id
# O and T are independent aligned column families; empty source retains both empty axes.
#
# StockOrigin Laws:
#   - Explicit first-class evidence: date, Commodity, memo/provenance
#   - Exactly 0 or 1 origin per Commodity (duplicate fails closed)
#   - Origin-only Commodity is valid
#   - Every transfer requires an explicit origin for its Commodity
#   - Origin date <= transfer date
#   - Never inferred from first transfer, period, config, Asset, or Account names
#   - Provenance retained through admission and report evidence
#
# Transfer Laws:
#   - Exact positive quantity (> 0), zero and negative forbidden
#   - from != to
#   - Direction is endpoint itself
#   - Referenced <EnvelopeId> must exist in stable historical identity universe
#   - Same-day effects combined before cumulative non-negative validation
#   - unallocated does not have a stored balance pool

parse ← •Import "../text/parse.bqn"
decimal ← •Import "exact_decimal.bqn"
dates ← •Import "date_ordinal.bqn"
scale ← •Import "exact_scale.bqn"

lf ← @+10
cr ← @+13
space ← @+32
tab ← @+9
empty ← ⟨⟩
sourceName ← "entitlement.journal"

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs: prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_entitlement_journal_admission",code⇐codeText,line⇐lineNumber,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

ParseLine ← {𝕊 line‿row‿envelopeHistory‿currencyRegistry:
  semicolon ← ⊑ ";"
  hash ← ⊑ "#"
  commentMask ← (line=semicolon) ∨ line=hash
  pos ← ⊑ (commentMask/↕≠line) ∾ ⟨≠line⟩
  codePart ← Trim pos↑line
  memoPart ← Trim (pos+1)↓line
  words ← space parse.Split codePart
  wordCount ← ≠words
  result ← {kind⇐"empty", origin⇐@, transfer⇐@, diagnostics⇐empty}

  {𝕊:
    isOrigin ← (2≤wordCount) ∧ ((1⊑words)≡"origin")
    isTransfer ← (2≤wordCount) ∧ ((1⊑words)≡"transfer")

    {𝕊:
      diagnostics ← empty
      dateStr ← 0⊑words
      dateValid ← (10=≠dateStr) ∧ (dates.IsValid dateStr)
      diagnostics ∾↩ AddIf ⟨¬dateValid, Diagnostic ⟨"entitlement_date_invalid",row,"StockOrigin date must be a valid YYYY-MM-DD date"⟩⟩
      shapeValid ← 3≤wordCount
      diagnostics ∾↩ AddIf ⟨¬shapeValid, Diagnostic ⟨"entitlement_syntax_invalid",row,"StockOrigin requires YYYY-MM-DD origin COMMODITY [memo]"⟩⟩
      commodity ← ""
      commValid ← 0
      {𝕊:
        commodity ↩ 2⊑words
        policy ← currencyRegistry.Policy commodity
        commValid ↩ policy.state ≡ "ok"
        diagnostics ∾↩ AddIf ⟨¬commValid, Diagnostic ⟨"entitlement_commodity_unknown",row,"StockOrigin commodity must be registry-supported"⟩⟩
      }⍟shapeValid @
      extraMemo ← Trim ∾{" "∾𝕩}¨3↓words
      fullMemo ← extraMemo
      {𝕊: fullMemo ↩ memoPart}⍟((0<≠memoPart) ∧ (0=≠extraMemo)) @
      {𝕊: fullMemo ↩ extraMemo∾" ; "∾memoPart}⍟((0<≠memoPart) ∧ (0<≠extraMemo)) @
      originItem ← @
      {𝕊:
        originItem ↩ {
          date⇐dateStr,
          date_ordinal⇐dates.Ordinal dateStr,
          commodity⇐commodity,
          memo⇐fullMemo,
          source_line⇐row,
          source_event_id⇐sourceName∾":line:"∾•Fmt row
        }
      }⍟(dateValid ∧ shapeValid ∧ commValid) @
      result ↩ {kind⇐"origin", origin⇐originItem, transfer⇐@, diagnostics⇐diagnostics}
    }⍟isOrigin @

    {𝕊:
      diagnostics ← empty
      dateStr ← 0⊑words
      dateValid ← (10=≠dateStr) ∧ (dates.IsValid dateStr)
      diagnostics ∾↩ AddIf ⟨¬dateValid, Diagnostic ⟨"entitlement_date_invalid",row,"transfer date must be a valid YYYY-MM-DD date"⟩⟩
      shapeValid ← (7≤wordCount) ∧ ((3⊑words)≡"->")
      diagnostics ∾↩ AddIf ⟨¬shapeValid, Diagnostic ⟨"entitlement_syntax_invalid",row,"transfer requires YYYY-MM-DD transfer FROM -> TO QUANTITY COMMODITY [memo]"⟩⟩
      transferItem ← @
      {𝕊:
        fromEndpoint ← 2⊑words
        toEndpoint ← 4⊑words
        amountStr ← 5⊑words
        commodity ← 6⊑words
        sameEndpoint ← fromEndpoint ≡ toEndpoint
        diagnostics ∾↩ AddIf ⟨sameEndpoint, Diagnostic ⟨"entitlement_transfer_same_endpoint",row,"transfer from and to endpoints must differ"⟩⟩
        knownIds ← envelopeHistory.registry.id
        fromValid ← (fromEndpoint ≡ "unallocated") ∨ (Contains ⟨fromEndpoint, knownIds⟩)
        toValid ← (toEndpoint ≡ "unallocated") ∨ (Contains ⟨toEndpoint, knownIds⟩)
        diagnostics ∾↩ AddIf ⟨¬fromValid, Diagnostic ⟨"envelope_id_unknown",row,"transfer from endpoint must be unallocated or a stable Envelope identity"⟩⟩
        diagnostics ∾↩ AddIf ⟨¬toValid, Diagnostic ⟨"envelope_id_unknown",row,"transfer to endpoint must be unallocated or a stable Envelope identity"⟩⟩
        parsedAmount ← decimal.Parse amountStr
        amountValid ← (parsedAmount.state ≡ "ok") ∧ (parsedAmount.coefficient > 0)
        diagnostics ∾↩ AddIf ⟨¬amountValid, Diagnostic ⟨"entitlement_transfer_amount_invalid",row,"transfer amount must be an exact strictly-positive decimal"⟩⟩
        policy ← currencyRegistry.Policy commodity
        commValid ← policy.state ≡ "ok"
        diagnostics ∾↩ AddIf ⟨¬commValid, Diagnostic ⟨"entitlement_commodity_unknown",row,"transfer commodity must be registry-supported"⟩⟩
        extraMemo ← Trim ∾{" "∾𝕩}¨7↓words
        fullMemo ← extraMemo
        {𝕊: fullMemo ↩ memoPart}⍟((0<≠memoPart) ∧ (0=≠extraMemo)) @
        {𝕊: fullMemo ↩ extraMemo∾" ; "∾memoPart}⍟((0<≠memoPart) ∧ (0<≠extraMemo)) @
        {𝕊:
          transferItem ↩ {
            date⇐dateStr,
            date_ordinal⇐dates.Ordinal dateStr,
            from⇐fromEndpoint,
            to⇐toEndpoint,
            amount_text⇐amountStr,
            coefficient⇐parsedAmount.coefficient,
            scale⇐parsedAmount.scale,
            commodity⇐commodity,
            memo⇐fullMemo,
            source_line⇐row,
            source_event_id⇐sourceName∾":line:"∾•Fmt row
          }
        }⍟(dateValid ∧ shapeValid ∧ (¬sameEndpoint) ∧ fromValid ∧ toValid ∧ amountValid ∧ commValid) @
      }⍟shapeValid @
      result ↩ {kind⇐"transfer", origin⇐@, transfer⇐transferItem, diagnostics⇐diagnostics}
    }⍟isTransfer @

    {𝕊:
      result ↩ {kind⇐"invalid", origin⇐@, transfer⇐@, diagnostics⇐⟨Diagnostic ⟨"entitlement_syntax_invalid",row,"unsupported entitlement line syntax; expected origin or transfer"⟩⟩}
    }⍟(¬(isOrigin ∨ isTransfer)) @
  }⍟(0<wordCount) @

  result
}

EmptyOrigins ← {𝕊:
  {
    count⇐0,
    index⇐empty,
    date⇐empty,
    date_ordinal⇐empty,
    commodity⇐empty,
    memo⇐empty,
    source_line⇐empty,
    source_event_id⇐empty
  }
}

EmptyTransfers ← {𝕊:
  {
    count⇐0,
    index⇐empty,
    date⇐empty,
    date_ordinal⇐empty,
    from⇐empty,
    to⇐empty,
    amount_text⇐empty,
    coefficient⇐empty,
    scale⇐empty,
    commodity⇐empty,
    memo⇐empty,
    source_line⇐empty,
    source_event_id⇐empty
  }
}

Admit ← {𝕊 raw‿envelopeHistory‿currencyRegistry:
  normalized ← (cr≠raw)/raw
  lines ← lf parse.SplitKeepEmpty normalized
  indices ← ↕≠lines

  parsedLines ← {𝕊 i: ParseLine ⟨i⊑lines, i+1, envelopeHistory, currencyRegistry⟩}¨indices
  diagnostics ← ∾ {𝕩.diagnostics}¨parsedLines

  rawOrigins ← ({ (𝕩.kind≡"origin") ∧ 𝕩.origin≢@ }¨parsedLines)/{𝕩.origin}¨parsedLines
  rawTransfers ← ({ (𝕩.kind≡"transfer") ∧ 𝕩.transfer≢@ }¨parsedLines)/{𝕩.transfer}¨parsedLines

  # Global StockOrigin laws
  {𝕊:
    originCommodities ← {𝕩.commodity}¨rawOrigins
    dupOrigins ← (≠originCommodities) ≠ ≠⍷originCommodities
    diagnostics ∾↩ AddIf ⟨dupOrigins, Diagnostic ⟨"entitlement_origin_duplicate",0,"duplicate StockOrigin declaration for Commodity"⟩⟩
  }⍟(0=≠diagnostics) @

  {𝕊:
    {𝕊 transfer:
      comm ← transfer.commodity
      matches ← ({𝕩.commodity≡comm}¨rawOrigins)/rawOrigins
      hasOrigin ← 1 = ≠matches
      diagnostics ∾↩ AddIf ⟨¬hasOrigin, Diagnostic ⟨"entitlement_origin_missing",transfer.source_line,"transfer requires explicit StockOrigin for Commodity "∾comm⟩⟩
      {𝕊:
        orig ← ⊑matches
        origAfter ← orig.date_ordinal > transfer.date_ordinal
        diagnostics ∾↩ AddIf ⟨origAfter, Diagnostic ⟨"entitlement_origin_after_transfer",transfer.source_line,"StockOrigin date must be on or before transfer date"⟩⟩
      }⍟hasOrigin @
    }¨rawTransfers
  }⍟(0=≠diagnostics) @

  # Historical Cumulative Nonnegative Law per envelope
  {𝕊:
    envelopeIds ← envelopeHistory.registry.id
    envelopeCount ← ≠envelopeIds
    {𝕊 envId:
      matchingTransfers ← ({ (𝕩.from≡envId) ∨ 𝕩.to≡envId }¨rawTransfers)/rawTransfers
      {𝕊:
        comms ← ⍷ {𝕩.commodity}¨matchingTransfers
        {𝕊 comm:
          commTransfers ← ({𝕩.commodity≡comm}¨matchingTransfers)/matchingTransfers
          amounts ← { (𝕩.to≡envId) ? 𝕩.coefficient ; -𝕩.coefficient }¨commTransfers
          scales ← {𝕩.scale}¨commTransfers
          effectDatesAll ← {𝕩.date_ordinal}¨commTransfers
          envScale ← ⌈´0∾scales
          normResults ← amounts {scale.Normalize ⟨𝕨,𝕩,envScale⟩}¨ scales
          normOk ← ∧´1∾{𝕩.state≡"ok"}¨normResults
          diagnostics ∾↩ AddIf ⟨¬normOk, Diagnostic ⟨"coefficient_normalization_failed",0,"Entitlement transfer cannot normalize exactly"⟩⟩
          {𝕊:
            normAmounts ← {𝕩.coefficient}¨normResults
            order ← ⍋effectDatesAll
            sdates ← order⊏effectDatesAll ⋄ samounts ← order⊏normAmounts
            dayGroups ← ((⍷sdates)⊐sdates)⊔samounts
            daySums ← {scale.Sum (⍋𝕩)⊏𝕩}¨dayGroups
            sumsOk ← ∧´1∾{𝕩.state≡"ok"}¨daySums
            diagnostics ∾↩ AddIf ⟨¬sumsOk, Diagnostic ⟨"coefficient_sum_failed",0,"Envelope Entitlement exceeds exact range"⟩⟩
            {𝕊:
              dayTotals ← {𝕩.coefficient}¨daySums
              cumSum ← scale.Sum dayTotals
              cumOk ← cumSum.state ≡ "ok"
              diagnostics ∾↩ AddIf ⟨¬cumOk, Diagnostic ⟨"coefficient_sum_failed",0,"Envelope Entitlement exceeds exact range"⟩⟩
              {𝕊:
                prefixes ← 1↓+`0∾dayTotals
                isNegative ← ∨´0>prefixes
                diagnostics ∾↩ AddIf ⟨isNegative, Diagnostic ⟨"envelope_entitlement_negative",0,"Envelope Entitlement cannot become negative in historical admission"⟩⟩
              }⍟cumOk @
            }⍟sumsOk @
          }⍟normOk @
        }¨comms
      }⍟(0<≠matchingTransfers) @
    }¨envelopeIds
  }⍟(0=≠diagnostics) @

  ok ← 0=≠diagnostics
  admittedOrigins ← ok/rawOrigins
  admittedTransfers ← ok/rawTransfers

  declaredDomains ← ⍷ {𝕩.commodity}¨admittedOrigins

  originsCarrier ← EmptyOrigins @
  {𝕊:
    originsCarrier ↩ {
      count⇐≠admittedOrigins,
      index⇐↕≠admittedOrigins,
      date⇐{𝕩.date}¨admittedOrigins,
      date_ordinal⇐{𝕩.date_ordinal}¨admittedOrigins,
      commodity⇐{𝕩.commodity}¨admittedOrigins,
      memo⇐{𝕩.memo}¨admittedOrigins,
      source_line⇐{𝕩.source_line}¨admittedOrigins,
      source_event_id⇐{𝕩.source_event_id}¨admittedOrigins
    }
  }⍟ok @

  transfersCarrier ← EmptyTransfers @
  {𝕊:
    transfersCarrier ↩ {
      count⇐≠admittedTransfers,
      index⇐↕≠admittedTransfers,
      date⇐{𝕩.date}¨admittedTransfers,
      date_ordinal⇐{𝕩.date_ordinal}¨admittedTransfers,
      from⇐{𝕩.from}¨admittedTransfers,
      to⇐{𝕩.to}¨admittedTransfers,
      amount_text⇐{𝕩.amount_text}¨admittedTransfers,
      coefficient⇐{𝕩.coefficient}¨admittedTransfers,
      scale⇐{𝕩.scale}¨admittedTransfers,
      commodity⇐{𝕩.commodity}¨admittedTransfers,
      memo⇐{𝕩.memo}¨admittedTransfers,
      source_line⇐{𝕩.source_line}¨admittedTransfers,
      source_event_id⇐{𝕩.source_event_id}¨admittedTransfers
    }
  }⍟ok @

  {
    state⇐ok ⊑ "error"‿"ok",
    source_name⇐sourceName,
    declared_domains⇐declaredDomains,
    origins⇐originsCarrier,
    transfers⇐transfersCarrier,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
