# Source-independent destination section metadata CLI.

metadata ← •Import "../report/section_metadata.bqn"
args ← •args ⋄ format ← "tsv"
{𝕊:
  {𝕊:•Out "ERROR: expected --format tsv|json" ⋄ •Exit 2}⍟(2≠≠args) @
  {𝕊:•Out "ERROR: expected --format tsv|json" ⋄ •Exit 2}⍟((0⊑args)≢"--format") @
  format↩1⊑args
}⍟(0<≠args) @
{𝕊:•Out "ERROR: unsupported format: "∾format ⋄ •Exit 2}⍟(¬∨´format⊸≡¨⟨"tsv","json"⟩) @
text ← metadata.FormatTsv @
{𝕊:text↩metadata.FormatJson @}⍟(format≡"json") @
•Out ¯1↓text
