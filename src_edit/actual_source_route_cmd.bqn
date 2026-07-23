# Emit the explicitly configured actual-source route for shell orchestration.
config ← •Import "../src_next/config.bqn"
args ← •args
{𝕊: •Out "ERROR: expected base" ⋄ •Exit 2}⍟(1≠≠args) @
route ← config.LoadActualSource ⊑args
mode ← route.mode
valid ← ∨´mode⊸≡¨⟨"tsv","journal"⟩
{𝕊: •Out "ERROR: ACTUAL_SOURCE must be tsv or journal" ⋄ •Exit 1}⍟(¬valid) @
file ← (mode≡"journal")⊑⟨"journal.tsv",route.file⟩
{𝕊: •Out "ERROR: ACTUAL_JOURNAL_FILE is required" ⋄ •Exit 1}⍟(0=≠file) @
•Out mode∾(@+9)∾file
