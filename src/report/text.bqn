# Narrow destination report text primitives proved by multiple section renderers.
# No accounting, source, section label, color, or terminal-state policy.

amount ← •Import "../ledger/amount_text.bqn"

VWidth ← {+´⥊1+127<𝕩-@}
PadRight ← {𝕊 width‿text: text∾(0⌈width-VWidth text)⥊' '}
PadLeft ← {𝕊 width‿text: ((0⌈width-VWidth text)⥊' ')∾text}

FormatAmount ← {𝕊 coefficient‿scale‿style:
  plain ← amount.Format ⟨coefficient,scale⟩
  parenthesized ← (style≡"parentheses") ∧ ('-'≡0⊑plain)
  parenthesized◶⟨{𝕊:plain},{𝕊:"("∾(1↓plain)∾")"}⟩ @
}

# Plain deterministic table over already-formatted text cells.
RenderTable ← {𝕊 headers‿rows‿rightAligned:
  columnCount ← ≠headers
  widths ← {𝕊 column: ⌈´⟨VWidth column⊑headers⟩∾{VWidth column⊑𝕩}¨rows}¨↕columnCount
  RenderRow ← {𝕊 row:
    cells ← {𝕊 column:
      width ← column⊑widths ⋄ value ← column⊑row
      cell ← PadRight ⟨width,value⟩
      {𝕊: cell↩PadLeft ⟨width,value⟩}⍟(column∊rightAligned) @
      cell
    }¨↕columnCount
    ∾{𝕊 column: ((column>0)/" | ")∾column⊑cells}¨↕columnCount
  }
  separator ← ∾{𝕊 column: ((column>0)/"-+-")∾((column⊑widths)⥊'-')}¨↕columnCount
  (RenderRow headers)∾(@+10)∾separator∾(@+10)∾∾{(RenderRow 𝕩)∾(@+10)}¨rows
}

{VWidth⇐VWidth,PadRight⇐PadRight,PadLeft⇐PadLeft,RenderTable⇐RenderTable,FormatAmount⇐FormatAmount}
