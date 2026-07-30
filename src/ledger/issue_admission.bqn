# Strict pure admission for the non-accounting issues.tsv source.

exact ← •Import "exact_decimal.bqn"
dates ← •Import "date_ordinal.bqn"
empty ← ⟨⟩
tab ← @+9
header ← ⟨"issue_id","status","date","category","title","amount","currency","details"⟩
statuses ← ⟨"open","resolved","dropped"⟩

SplitKeepEmpty ← {𝕊 separator‿text:
  groups ← (+`separator=text)⊔text
  {(separator≠𝕩)/𝕩}¨groups
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Ignored ← {𝕊 line: (0=≠line) ∨ ((0<≠line) ∧ (⊑line)∊"#\\")}
Diagnostic ← {𝕊 code‿row‿message:
  {severity⇐"error",stage⇐"ledger_issue_admission",code⇐code,source_row⇐row,message⇐message}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyIssues ← {𝕊:
  {
    count⇐0,index⇐empty,issue_id⇐empty,status⇐empty,date⇐empty,date_ordinal⇐empty,
    category⇐empty,title⇐empty,amount_present⇐empty,coefficient⇐empty,scale⇐empty,
    currency⇐empty,details⇐empty,source_row⇐empty,source_ref⇐empty
  }
}

Admit ← {𝕊 lines‿registry:
  diagnostics ← empty ⋄ rows ← empty
  dataLines ← empty ⋄ dataSourceRows ← empty
  {𝕊 i:
    {𝕊:dataLines∾↩⟨i⊑lines⟩ ⋄ dataSourceRows∾↩i+1}⍟(¬Ignored i⊑lines) @
  }¨↕≠lines
  sourceAbsent ← 0=≠lines
  headerOk ← sourceAbsent
  {𝕊:headerOk↩(SplitKeepEmpty ⟨tab,⊑dataLines⟩)≡header}⍟(0<≠dataLines) @
  headerRow ← 1
  {𝕊:headerRow↩⊑dataSourceRows}⍟(0<≠dataSourceRows) @
  diagnostics∾↩AddIf ⟨¬headerOk,Diagnostic ⟨"issue_header_invalid",headerRow,"issues.tsv header must match the strict eight-column schema"⟩⟩
  {𝕊 i:
    line ← i⊑1↓dataLines ⋄ sourceRow ← i⊑1↓dataSourceRows
    fields ← SplitKeepEmpty ⟨tab,line⟩
    rowDiagnostics ← empty
    rowDiagnostics∾↩AddIf ⟨8≠≠fields,Diagnostic ⟨"issue_field_count_invalid",sourceRow,"issue row requires exactly eight fields"⟩⟩
    {𝕊:
      issueId‿status‿date‿category‿title‿amountText‿currency‿details ← fields
      rowDiagnostics∾↩AddIf ⟨0=≠issueId,Diagnostic ⟨"issue_identity_missing",sourceRow,"issue_id must be nonempty"⟩⟩
      rowDiagnostics∾↩AddIf ⟨¬Contains ⟨status,statuses⟩,Diagnostic ⟨"issue_status_invalid",sourceRow,"status must be open, resolved, or dropped"⟩⟩
      rowDiagnostics∾↩AddIf ⟨(0<≠date) ∧ ¬dates.IsValid date,Diagnostic ⟨"issue_date_invalid",sourceRow,"date must be empty or strict Gregorian text"⟩⟩
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
      diagnostics∾↩rowDiagnostics
      {𝕊:
        dateOrdinal ← empty
        {𝕊:dateOrdinal↩dates.Ordinal date}⍟(0<≠date) @
        rows∾↩⟨{
          issue_id⇐issueId,status⇐status,date⇐date,date_ordinal⇐dateOrdinal,
          category⇐category,title⇐title,amount_present⇐amountPresent,
          coefficient⇐parsed.coefficient,scale⇐parsed.scale,currency⇐currency,details⇐details,
          source_row⇐sourceRow,source_ref⇐"issues.tsv:row:"∾•Fmt sourceRow
        }⟩
      }⍟(0=≠rowDiagnostics) @
    }⍟(8=≠fields) @
  }¨↕0⌈(≠dataLines)-1
  ids ← {𝕩.issue_id}¨rows
  diagnostics∾↩AddIf ⟨(≠ids)≠≠⍷ids,Diagnostic ⟨"issue_identity_duplicate",0,"issue_id values must be unique"⟩⟩
  table ← EmptyIssues @
  {𝕊:
    table↩{
      count⇐≠rows,index⇐↕≠rows,issue_id⇐{𝕩.issue_id}¨rows,status⇐{𝕩.status}¨rows,
      date⇐{𝕩.date}¨rows,date_ordinal⇐{𝕩.date_ordinal}¨rows,
      category⇐{𝕩.category}¨rows,title⇐{𝕩.title}¨rows,
      amount_present⇐{𝕩.amount_present}¨rows,coefficient⇐{𝕩.coefficient}¨rows,
      scale⇐{𝕩.scale}¨rows,currency⇐{𝕩.currency}¨rows,details⇐{𝕩.details}¨rows,
      source_row⇐{𝕩.source_row}¨rows,source_ref⇐{𝕩.source_ref}¨rows
    }
  }⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",issues⇐table,diagnostics⇐diagnostics}
}

{Admit⇐Admit}
