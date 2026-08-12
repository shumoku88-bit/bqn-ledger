# Strict pure admission for the non-accounting issues.tsv source.

exact ← •Import "exact_decimal.bqn"
dates ← •Import "date_ordinal.bqn"
empty ← ⟨⟩
tab ← @+9
legacyHeader ← ⟨"issue_id","status","date","category","title","amount","currency","details"⟩
dueHeader ← ⟨"issue_id","status","date","due","category","title","amount","currency","details"⟩
closedHeader ← ⟨"issue_id","status","date","due","closed","category","title","amount","currency","details"⟩
statuses ← ⟨"open","resolved","dropped"⟩

SplitKeepEmpty ← {𝕊 separator‿text:
  groups ← (+`separator=text)⊔text
  {(separator≠𝕩)/𝕩}¨groups
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Ignored ← {𝕊 line:
  first ← ⊑(line∾" ")
  (0=≠line) ∨ (first='#') ∨ first=⊑"\\"
}
Diagnostic ← {𝕊 code‿row‿message:
  {severity⇐"error",stage⇐"ledger_issue_admission",code⇐code,source_row⇐row,message⇐message}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyIssues ← {𝕊:
  {
    count⇐0,index⇐empty,issue_id⇐empty,status⇐empty,date⇐empty,date_ordinal⇐empty,
    due⇐empty,due_ordinal⇐empty,closed⇐empty,closed_ordinal⇐empty,
    category⇐empty,title⇐empty,amount_present⇐empty,coefficient⇐empty,scale⇐empty,
    currency⇐empty,details⇐empty,source_row⇐empty,source_ref⇐empty
  }
}

Admit ← {𝕊 lines‿registry:
  sourceRows ← 1+↕≠lines
  ignored ← Ignored¨lines
  dataMask ← ¬ignored
  dataLines ← dataMask/lines
  dataSourceRows ← dataMask/sourceRows

  sourceAbsent ← 0=≠lines
  headerLine ← ⊑(dataLines∾⟨""⟩)
  headerRow ← ⊑(dataSourceRows∾⟨1⟩)
  headerFields ← SplitKeepEmpty ⟨tab,headerLine⟩
  legacySchema ← headerFields≡legacyHeader
  dueSchema ← headerFields≡dueHeader
  closedSchema ← headerFields≡closedHeader
  headerOk ← sourceAbsent ∨ legacySchema ∨ dueSchema ∨ closedSchema
  headerDiagnostics ← AddIf ⟨¬headerOk,Diagnostic ⟨"issue_header_invalid",headerRow,"issues.tsv header must match the supported eight-, nine-, or ten-column schema"⟩⟩

  rowLines ← 1↓dataLines
  rowSourceRows ← 1↓dataSourceRows
  expectedCount ← 8 + dueSchema + 2×closedSchema
  ParseRow ← {𝕊 i:
    line ← i⊑rowLines ⋄ sourceRow ← i⊑rowSourceRows
    fields ← SplitKeepEmpty ⟨tab,line⟩
    rowDiagnostics ← AddIf ⟨expectedCount≠≠fields,Diagnostic ⟨"issue_field_count_invalid",sourceRow,"issue row width must match the admitted issues.tsv header"⟩⟩
    item ← @
    {𝕊:
      statusRaw ← 1⊑fields
      closedFallback ← (statusRaw≡"open")⊑⟨"undetermined","none"⟩
      normalized ← fields
      {𝕊:normalized↩(3↑fields)∾⟨"undetermined",closedFallback⟩∾3↓fields}⍟legacySchema @
      {𝕊:normalized↩(4↑fields)∾⟨closedFallback⟩∾4↓fields}⍟dueSchema @
      issueId‿status‿date‿due‿closed‿category‿title‿amountText‿currency‿details ← normalized
      statusOk ← Contains ⟨status,statuses⟩
      rowDiagnostics∾↩AddIf ⟨0=≠issueId,Diagnostic ⟨"issue_identity_missing",sourceRow,"issue_id must be nonempty"⟩⟩
      rowDiagnostics∾↩AddIf ⟨¬statusOk,Diagnostic ⟨"issue_status_invalid",sourceRow,"status must be open, resolved, or dropped"⟩⟩
      dateValid ← dates.IsValid date
      rowDiagnostics∾↩AddIf ⟨(0<≠date) ∧ ¬dateValid,Diagnostic ⟨"issue_date_invalid",sourceRow,"date must be empty or strict Gregorian text"⟩⟩
      dueDateValid ← dates.IsValid due
      dueOk ← (due≡"none") ∨ (due≡"undetermined") ∨ dueDateValid
      rowDiagnostics∾↩AddIf ⟨¬dueOk,Diagnostic ⟨"issue_due_invalid",sourceRow,"due must be none, undetermined, or strict Gregorian text"⟩⟩
      closedDateValid ← dates.IsValid closed
      closedOk ← (closed≡"none") ∨ (closed≡"undetermined") ∨ closedDateValid
      rowDiagnostics∾↩AddIf ⟨¬closedOk,Diagnostic ⟨"issue_closed_invalid",sourceRow,"closed must be none, undetermined, or strict Gregorian text"⟩⟩
      lifecycleOk ← (status≡"open") = (closed≡"none")
      rowDiagnostics∾↩AddIf ⟨statusOk ∧ closedOk ∧ ¬lifecycleOk,Diagnostic ⟨"issue_closed_status_mismatch",sourceRow,"open issues require closed=none; resolved/dropped issues require a date or undetermined"⟩⟩
      {𝕊:
        rowDiagnostics∾↩AddIf ⟨(dates.Ordinal closed)<dates.Ordinal date,Diagnostic ⟨"issue_closed_before_recorded",sourceRow,"closed date cannot precede recorded date"⟩⟩
      }⍟(closedDateValid ∧ dateValid) @
      rowDiagnostics∾↩AddIf ⟨0=≠category,Diagnostic ⟨"issue_category_missing",sourceRow,"category must be nonempty"⟩⟩
      rowDiagnostics∾↩AddIf ⟨0=≠title,Diagnostic ⟨"issue_title_missing",sourceRow,"title must be nonempty"⟩⟩
      amountPresent ← 0<≠amountText
      amountPairInvalid ← amountPresent≠0<≠currency
      rowDiagnostics∾↩AddIf ⟨amountPairInvalid,Diagnostic ⟨"issue_amount_currency_pair_invalid",sourceRow,"amount and currency must both be present or empty"⟩⟩
      parsed ← {state⇐"absent",coefficient⇐empty,scale⇐empty}
      {𝕊:
        parsed↩exact.Parse amountText
        rowDiagnostics∾↩AddIf ⟨parsed.state≢"ok",Diagnostic ⟨"issue_amount_invalid",sourceRow,"amount must be an exact unsigned decimal"⟩⟩
        policy ← registry.Policy currency
        rowDiagnostics∾↩AddIf ⟨policy.state≢"ok",Diagnostic ⟨"issue_currency_unsupported",sourceRow,"currency must be registry-supported"⟩⟩
        {𝕊:
          precisionInvalid ← (policy.max_fraction_digits≠¯1) ∧ parsed.scale>policy.max_fraction_digits
          rowDiagnostics∾↩AddIf ⟨precisionInvalid,Diagnostic ⟨"issue_amount_precision_exceeded",sourceRow,"amount precision exceeds currency policy"⟩⟩
        }⍟((parsed.state≡"ok") ∧ policy.state≡"ok") @
      }⍟amountPresent @
      {𝕊:
        dateOrdinal ← empty
        {𝕊:dateOrdinal↩dates.Ordinal date}⍟(0<≠date) @
        dueOrdinal ← empty
        {𝕊:dueOrdinal↩dates.Ordinal due}⍟dueDateValid @
        closedOrdinal ← empty
        {𝕊:closedOrdinal↩dates.Ordinal closed}⍟closedDateValid @
        item↩{
          issue_id⇐issueId,status⇐status,date⇐date,date_ordinal⇐dateOrdinal,
          due⇐due,due_ordinal⇐dueOrdinal,closed⇐closed,closed_ordinal⇐closedOrdinal,
          category⇐category,title⇐title,amount_present⇐amountPresent,
          coefficient⇐parsed.coefficient,scale⇐parsed.scale,currency⇐currency,
          details⇐details,source_row⇐sourceRow,source_ref⇐"issues.tsv:row:"∾•Fmt sourceRow
        }
      }⍟(0=≠rowDiagnostics) @
    }⍟(expectedCount=≠fields) @
    {diagnostics⇐rowDiagnostics,item⇐item}
  }

  parsedRows ← ParseRow¨↕≠rowLines
  rowDiagnostics ← ∾{𝕩.diagnostics}¨parsedRows
  items ← {𝕩.item}¨parsedRows
  rows ← ({𝕩≢@}¨items)/items
  ids ← {𝕩.issue_id}¨rows
  duplicateDiagnostics ← AddIf ⟨(≠ids)≠≠⍷ids,Diagnostic ⟨"issue_identity_duplicate",0,"issue_id values must be unique"⟩⟩
  diagnostics ← headerDiagnostics∾rowDiagnostics∾duplicateDiagnostics

  table ← EmptyIssues @
  {𝕊:
    table↩{
      count⇐≠rows,index⇐↕≠rows,issue_id⇐{𝕩.issue_id}¨rows,status⇐{𝕩.status}¨rows,
      date⇐{𝕩.date}¨rows,date_ordinal⇐{𝕩.date_ordinal}¨rows,
      due⇐{𝕩.due}¨rows,due_ordinal⇐{𝕩.due_ordinal}¨rows,
      closed⇐{𝕩.closed}¨rows,closed_ordinal⇐{𝕩.closed_ordinal}¨rows,
      category⇐{𝕩.category}¨rows,title⇐{𝕩.title}¨rows,
      amount_present⇐{𝕩.amount_present}¨rows,coefficient⇐{𝕩.coefficient}¨rows,
      scale⇐{𝕩.scale}¨rows,currency⇐{𝕩.currency}¨rows,details⇐{𝕩.details}¨rows,
      source_row⇐{𝕩.source_row}¨rows,source_ref⇐{𝕩.source_ref}¨rows
    }
  }⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",issues⇐table,diagnostics⇐diagnostics}
}

{Admit⇐Admit}
