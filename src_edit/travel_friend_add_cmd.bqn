# travel_friend_add_cmd.bqn
# I/O boundary for friend_travel_events.tsv validation and APPEND protocol.

loader ← •Import "../src/application/source_io.bqn"
source ← •Import "../src/editor/friend_travel_source_event.bqn"

args ← •args
tab ← @+9
file ← "friend_travel_events.tsv"

FailDiagnostics ← {𝕊 diagnostics:
  {•Out "ERROR"∾tab∾𝕩.code∾tab∾𝕩.field∾tab∾𝕩.message}¨ diagnostics
  •Exit 1
}

{𝕊 ⋄ •Out "ERROR"∾tab∾"usage" ⋄ •Exit 2}⍟(2>≠args) @
base ← 0⊑args
mode ← 1⊑args
lines ← loader.ReadLinesOptional (base∾"/"∾file)

{𝕊:
  result ← source.ValidateExisting lines
  {𝕊 ⋄ FailDiagnostics result.diagnostics}⍟(result.state≢"ok") @
  •Out "OK"∾tab∾"VALID"∾tab∾file∾tab∾•Fmt result.event_count
  •Exit 0
}⍟(mode≡"validate") @

{𝕊 ⋄ •Out "ERROR"∾tab∾"usage" ⋄ •Exit 2}⍟((mode≢"add")∨11≠≠args) @
event ← {
  date⇐2⊑args, party⇐3⊑args, item_or_category⇐4⊑args, original_amount⇐5⊑args,
  original_currency⇐6⊑args, payer⇐7⊑args, trip_id⇐8⊑args,
  source_event_id⇐9⊑args, status⇐10⊑args
}
result ← source.ValidateAndPreview {event⇐event, existing_lines⇐lines}
{𝕊 ⋄ FailDiagnostics result.diagnostics}⍟(result.state≢"ok") @
•Out "OK"∾tab∾"APPEND"∾tab∾file
•Out ⊑result.preview_rows
