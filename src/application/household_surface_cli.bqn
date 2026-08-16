surface ← •Import "household_surface.bqn"
tab ← @+9 ⋄ lf ← @+10

FormatActionTable ← {𝕊 table:
  header ← ∾⟨"action_index",tab,"domain_key",tab,"operation_key",tab,"scope",tab,"action_key",tab,"action_label",tab,"action_kind",lf⟩
  rows ← {𝕊 i:
    ∾⟨
      •Fmt i,tab,i⊑table.domain_key,tab,i⊑table.operation_key,tab,i⊑table.scope,tab,
      i⊑table.action_key,tab,i⊑table.action_label,tab,i⊑table.action_kind,lf
    ⟩
  }¨table.index
  ∾⟨header,∾rows⟩
}

args ← •args
text ← "" ⋄ matched ← 0
{𝕊:text↩surface.FormatTsv @ ⋄ matched↩1}⍟(0=≠args) @
{𝕊:
  {𝕊:text↩FormatActionTable surface.Actions @ ⋄ matched↩1}⍟("actions"≡0⊑args) @
}⍟(1=≠args) @
{𝕊:
  {𝕊:•Out "ERROR: expected no arguments, actions, or: actions DOMAIN OPERATION" ⋄ •Exit 2}⍟(¬"actions"≡0⊑args) @
  text↩surface.FormatActionsTsv ⟨1⊑args,2⊑args⟩
  matched↩1
}⍟(3=≠args) @
{𝕊:•Out "ERROR: expected no arguments, actions, or: actions DOMAIN OPERATION" ⋄ •Exit 2}⍟(¬matched) @
•Out ¯1↓text
