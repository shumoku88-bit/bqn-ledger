# format.bqn
# Minimal formatting helpers for src_next human-readable output.
# Terminal styling and coloring helpers (disabled in engine, presentation layer's responsibility).

# ANSI color codes (ESC = @ + 27) - Disabled inside BQN engine.
# Presentation layer (shell UI) handles coloring.
c_reset   ← ""
c_bold    ← ""
c_dim     ← ""
c_red     ← ""
c_green   ← ""
c_yellow  ← ""
c_blue    ← ""
c_magenta ← ""
c_cyan    ← ""

# Color control. BQN cannot read NO_COLOR directly, so CLI/wrapper code calls
# SetColorEnabled 0 when color should be suppressed.
enabled ← 1
SetColorEnabled ← { enabled ↩ 𝕩 }
AnsiColorEnabled ← {𝕊: enabled }

# Terminal styling helpers (disabled in engine; returns plain text)
Wrap    ← {𝕊 code‿text: enabled ⊑ ⟨text, code ∾ text ∾ c_reset⟩ }
Bold    ← { Wrap ⟨c_bold, 𝕩⟩ }
Dim     ← { Wrap ⟨c_dim, 𝕩⟩ }
Red     ← { Wrap ⟨c_red, 𝕩⟩ }
Green   ← { Wrap ⟨c_green, 𝕩⟩ }
Yellow  ← { Wrap ⟨c_yellow, 𝕩⟩ }
Blue    ← { Wrap ⟨c_blue, 𝕩⟩ }
Magenta ← { Wrap ⟨c_magenta, 𝕩⟩ }
Cyan    ← { Wrap ⟨c_cyan, 𝕩⟩ }

# Semantic helpers. Report code should prefer these over raw colors so future
# theme work can be localized here.
Ok     ← { Green 𝕩 }
Warn   ← { Yellow 𝕩 }
Bad    ← { Red 𝕩 }
Info   ← { Cyan 𝕩 }
Muted  ← { Dim 𝕩 }
Accent ← { Blue 𝕩 }
Future ← { Magenta 𝕩 }

# Visual width (ASCII=1, CJK=2), summed over all characters
# NOTE: does NOT account for ANSI escape sequences.
# Callers that mix colors with VWidth/PadV should strip escapes first.
VWidth ← { +´ ⥊ (1 + 127 < 𝕩-@) }

# Pad to visual width (right-pad with spaces)
PadV ← {
  n ← 0⊑𝕩 ⋄ s ← 1⊑𝕩
  ws ← VWidth¨ s
  cum ← +` ws
  mask ← cum ≤ n
  idxs ← mask / ↕ ≠ mask
  t ← 1 + ⌈´ idxs ∾ ⟨ ¯1 ⟩
  pre ← t ↑ s
  wpre ← +´ t ↑ ws
  pre ∾ (n - wpre) ⥊ " "
}

# Right-align integer in fixed width
PadL ← {
  w ← 0⊑𝕩 ⋄ x ← 1⊑𝕩
  s ← •Fmt x
  ((0 ⌈ w - ≠ s) ⥊ " ") ∾ s
}

# Format integer in 12-char right-aligned field; red if negative
FmtAmt ← {
  s ← PadL ⟨12, 𝕩⟩
  (𝕩 < 0) ⊑ ⟨s, Bad s⟩
}

# Range display: "start〜end"
RangeDisp ← { (0⊑𝕩) ∾ "〜" ∾ (1⊑𝕩) }

# Section header (bold)
Section ← { Bold 𝕩 }

{ VWidth ⇐ VWidth, PadV ⇐ PadV, PadL ⇐ PadL, FmtAmt ⇐ FmtAmt, RangeDisp ⇐ RangeDisp, Section ⇐ Section,
  SetColorEnabled ⇐ SetColorEnabled, AnsiColorEnabled ⇐ AnsiColorEnabled,
  c_reset ⇐ c_reset, c_bold ⇐ c_bold, c_dim ⇐ c_dim, c_red ⇐ c_red, c_green ⇐ c_green, c_yellow ⇐ c_yellow, c_blue ⇐ c_blue, c_magenta ⇐ c_magenta, c_cyan ⇐ c_cyan,
  Bold ⇐ Bold, Dim ⇐ Dim, Red ⇐ Red, Green ⇐ Green, Yellow ⇐ Yellow, Blue ⇐ Blue, Magenta ⇐ Magenta, Cyan ⇐ Cyan,
  Ok ⇐ Ok, Warn ⇐ Warn, Bad ⇐ Bad, Info ⇐ Info, Muted ⇐ Muted, Accent ⇐ Accent, Future ⇐ Future }
