# Emit the one configured native Journal file relative to the supplied base.
config ← •Import "../src_next/config.bqn"
args ← •args
{𝕊: •Out "ERROR: expected base" ⋄ •Exit 2}⍟(1≠≠args) @
resolved ← config.LoadActualJournal ⊑args
•Out resolved.file
