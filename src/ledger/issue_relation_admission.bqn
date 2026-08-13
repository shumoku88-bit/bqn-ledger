# Pure admission/rendering for the proposed non-canonical Issue relation history source.
#
# This owner defines only the six-coordinate relation syntax. It is deliberately
# not registered as a canonical Household source and owns no writer or UI path.

dates ← •Import "date_ordinal.bqn"

empty ← ⟨⟩
tab ← @+9
space ← @+32
lf ← @+10
cr ← @+13
header ← ⟨"relation_event_id","recorded_on","issue_id","relation_kind","target_id","details"⟩
planKinds ← ⟨"concerns-plan","planned-as","planning-withdrawn"⟩
actualKinds ← ⟨"realized-as","funded-by"⟩
kinds ← planKinds∾actualKinds

Tsv ← {𝕊 fields: 1↓∾tab⊸∾¨fields}
headerLine ← Tsv header
SplitKeepEmpty ← {𝕊 separator‿text:
  groups ← (+`separator=text)⊔text
  {(separator≠𝕩)/𝕩}¨groups
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IsWhitespace ← {𝕊 c: (c=space) ∨ (c=tab) ∨ (c=lf) ∨ c=cr}
IdentityValid ← {𝕊 value: (0<≠value) ∧ ¬∨´0∾IsWhitespace¨value}
DetailsValid ← {𝕊 value:
  noControl ← ¬∨´0∾((lf⊸=)∨(cr⊸=)∨(tab⊸=))¨value
  edgeSpace ← (0<≠value) ∧ ((space=⊑value) ∨ space=⊑⌽value)
  noControl ∧ ¬edgeSpace
}
Ignored ← {𝕊 line:
  first ← ⊑(line∾" ")
  (0=≠line) ∨ first='#'
}
Diagnostic ← {𝕊 code‿row‿message:
  {severity⇐"error",stage⇐"ledger_issue_relation_admission",code⇐code,source_row⇐row,message⇐message}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyRelations ← {𝕊:
  {
    count⇐0,index⇐empty,relation_event_id⇐empty,recorded_on⇐empty,
    issue_id⇐empty,relation_kind⇐empty,target_id⇐empty,details⇐empty
  }
}

Admit ← {𝕊 lines:
  sourceRows ← 1+↕≠lines
  ignored ← Ignored¨lines
  dataLines ← (¬ignored)/lines
  dataSourceRows ← (¬ignored)/sourceRows
  hasData ← 0<≠dataLines

  headerText ← ⊑(dataLines∾⟨""⟩)
  headerRow ← ⊑(dataSourceRows∾⟨1⟩)
  headerOk ← (¬hasData) ∨ headerText≡headerLine
  headerDiagnostics ← AddIf ⟨¬headerOk,Diagnostic ⟨"issue_relation_header_invalid",headerRow,"Issue relation header must match the six-coordinate contract"⟩⟩

  rowLines ← hasData↓dataLines
  rowSourceRows ← hasData↓dataSourceRows
  ParseRow ← {𝕊 i:
    line ← i⊑rowLines
    sourceRow ← i⊑rowSourceRows
    fields ← SplitKeepEmpty ⟨tab,line⟩
    diagnostics ← AddIf ⟨6≠≠fields,Diagnostic ⟨"issue_relation_field_count_invalid",sourceRow,"Issue relation rows require six coordinates"⟩⟩
    item ← @
    {𝕊:
      relationEventId‿recordedOn‿issueId‿relationKind‿targetId‿details ← fields
      kindOk ← Contains ⟨relationKind,kinds⟩
      diagnostics ∾↩ AddIf ⟨¬IdentityValid relationEventId,Diagnostic ⟨"issue_relation_event_identity_invalid",sourceRow,"relation_event_id must be nonempty and contain no whitespace"⟩⟩
      diagnostics ∾↩ AddIf ⟨¬dates.IsValid recordedOn,Diagnostic ⟨"issue_relation_recorded_on_invalid",sourceRow,"recorded_on must be strict Gregorian text"⟩⟩
      diagnostics ∾↩ AddIf ⟨¬IdentityValid issueId,Diagnostic ⟨"issue_relation_issue_identity_invalid",sourceRow,"issue_id must be nonempty and contain no whitespace"⟩⟩
      diagnostics ∾↩ AddIf ⟨¬kindOk,Diagnostic ⟨"issue_relation_kind_invalid",sourceRow,"relation_kind must use the closed Issue relation vocabulary"⟩⟩
      diagnostics ∾↩ AddIf ⟨¬IdentityValid targetId,Diagnostic ⟨"issue_relation_target_identity_invalid",sourceRow,"target_id must be nonempty and contain no whitespace"⟩⟩
      diagnostics ∾↩ AddIf ⟨¬DetailsValid details,Diagnostic ⟨"issue_relation_details_invalid",sourceRow,"details must not contain controls or surrounding spaces"⟩⟩
      {𝕊:
        item↩{
          relation_event_id⇐relationEventId,recorded_on⇐recordedOn,issue_id⇐issueId,
          relation_kind⇐relationKind,target_id⇐targetId,details⇐details
        }
      }⍟(0=≠diagnostics) @
    }⍟(6=≠fields) @
    {diagnostics⇐diagnostics,item⇐item}
  }

  parsedRows ← ParseRow¨↕≠rowLines
  rowDiagnostics ← ∾{𝕩.diagnostics}¨parsedRows
  items ← {𝕩.item}¨parsedRows
  rows ← ({𝕩≢@}¨items)/items
  eventIds ← {𝕩.relation_event_id}¨rows
  duplicateDiagnostics ← AddIf ⟨(≠eventIds)≠≠⍷eventIds,Diagnostic ⟨"issue_relation_event_identity_duplicate",0,"relation_event_id values must be unique"⟩⟩
  diagnostics ← headerDiagnostics∾rowDiagnostics∾duplicateDiagnostics

  relations ← EmptyRelations @
  {𝕊:
    relations↩{
      count⇐≠rows,index⇐↕≠rows,
      relation_event_id⇐{𝕩.relation_event_id}¨rows,
      recorded_on⇐{𝕩.recorded_on}¨rows,
      issue_id⇐{𝕩.issue_id}¨rows,
      relation_kind⇐{𝕩.relation_kind}¨rows,
      target_id⇐{𝕩.target_id}¨rows,
      details⇐{𝕩.details}¨rows
    }
  }⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",relations⇐relations,diagnostics⇐diagnostics}
}

Render ← {𝕊 relations:
  Row ← {𝕊 i:
    Tsv ⟨
      i⊑relations.relation_event_id,
      i⊑relations.recorded_on,
      i⊑relations.issue_id,
      i⊑relations.relation_kind,
      i⊑relations.target_id,
      i⊑relations.details
    ⟩
  }
  ⟨headerLine⟩∾Row¨↕relations.count
}

{Admit⇐Admit,Render⇐Render,Header⇐headerLine}
