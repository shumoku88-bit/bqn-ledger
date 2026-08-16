surface ← •Import "household_surface.bqn"
args ← •args
text ← "" ⋄ matched ← 0
{𝕊:text↩surface.FormatTsv @ ⋄ matched↩1}⍟(0=≠args) @
{𝕊:text↩surface.FormatActionsTsv ⟨1⊑args,2⊑args⟩ ⋄ matched↩1}⍟((3=≠args) ∧ "actions"≡0⊑args) @
{𝕊:•Out "ERROR: expected no arguments or: actions DOMAIN OPERATION" ⋄ •Exit 2}⍟(¬matched) @
•Out ¯1↓text
