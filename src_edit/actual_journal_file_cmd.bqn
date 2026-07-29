# Emit the one configured native Journal file relative to the supplied base.
actualConfig ← •Import "../src/application/actual_journal_config.bqn"
args ← •args
{𝕊: •Out "ERROR: expected base" ⋄ •Exit 2}⍟(1≠≠args) @
resolved ← actualConfig.Resolve ⊑args
•Out resolved.file
