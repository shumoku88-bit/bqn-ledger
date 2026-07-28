# Narrow destination report text primitives proved by multiple section renderers.
# No accounting, source, section label, color, or terminal-state policy.

VWidth ← {+´⥊1+127<𝕩-@}
PadRight ← {𝕊 width‿text: text∾(0⌈width-VWidth text)⥊' '}
PadLeft ← {𝕊 width‿text: ((0⌈width-VWidth text)⥊' ')∾text}

{VWidth⇐VWidth,PadRight⇐PadRight,PadLeft⇐PadLeft}
