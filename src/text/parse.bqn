# Pure bounded text splitting and integer parsing shared by application/editor code.
# File, path, shell, clock, and process I/O are outside this module.

{
  Split ⇐ {
    sep ← 𝕨
    mask ← sep = 𝕩
    groups ← (+` mask) ⊔ 𝕩
    parts ← {(sep ≠ 𝕩)/𝕩}¨ groups
    (0 < ≠¨ parts) / parts
  }

  SplitKeepEmpty ⇐ {
    sep ← 𝕨
    mask ← sep = 𝕩
    groups ← (+` mask) ⊔ 𝕩
    {(sep ≠ 𝕩)/𝕩}¨ groups
  }

  ToNum ⇐ {
    isneg ← '-' = ⊑𝕩
    s ← isneg ↓ 𝕩
    digits ← s - ⊑"0"
    value ← +´digits × 10⋆⌽↕≠s
    (1-2×isneg) × value
  }
}
