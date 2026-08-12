# Source-independent destination section metadata CLI.

metadata ← •Import "../report/section_metadata.bqn"
args ← •args
Usage ← {𝕊:•Out "ERROR: expected --format tsv|json" ⋄ •Exit 2}
ParseFormat ← {𝕊 arguments:
  (2=≠arguments)◶⟨
    {𝕊:Usage @},
    {𝕊:
      ((0⊑arguments)≡"--format")◶⟨
        {𝕊:Usage @},
        {𝕊:1⊑arguments}
      ⟩ @
    }
  ⟩ @
}
format ← (0=≠args)◶⟨{𝕊:ParseFormat args},{𝕊:"tsv"}⟩ @
{𝕊:•Out "ERROR: unsupported format: "∾format ⋄ •Exit 2}⍟(¬∨´format⊸≡¨⟨"tsv","json"⟩) @
text ← (format≡"json")◶⟨{𝕊:metadata.FormatTsv @},{𝕊:metadata.FormatJson @}⟩ @
•Out ¯1↓text
