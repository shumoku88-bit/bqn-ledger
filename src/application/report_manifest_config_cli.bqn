# CLI adapter for one explicit configured report request manifest.
config ← •Import "report_manifest_config.bqn"
args ← •args
tab ← @+9
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected MANIFEST_CONFIG human|compact" ⋄ •Exit 2}⍟(2≠≠args) @
configSource ← 0⊑args
surface ← 1⊑args
{𝕊:•Out "ERROR"∾tab∾"surface"∾tab∾"expected human or compact" ⋄ •Exit 2}⍟(¬∨´surface⊸≡¨⟨"human","compact"⟩) @
resolved ← config.Load configSource
•Out (surface≡"human")⊑resolved.compact_file‿resolved.human_file
