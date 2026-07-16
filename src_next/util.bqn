# util.bqn
# Pure text and numeric helpers shared across src_next and src_edit.
# File, path, shell, clock, and process I/O belong to their dedicated owners.

{
  Split ⇐ {
    sep ← 𝕨
    mask ← sep = 𝕩
    groups ← (+` mask) ⊔ 𝕩
    parts ← { (sep ≠ 𝕩) / 𝕩 } ¨ groups
    (0 < ≠¨ parts) / parts
  }

  SplitKeepEmpty ⇐ {
    sep ← 𝕨
    mask ← sep = 𝕩
    groups ← (+` mask) ⊔ 𝕩
    { (sep ≠ 𝕩) / 𝕩 } ¨ groups
  }

  ToNum ⇐ {
    isneg ← '-' = ⊑ 𝕩
    s ← isneg ↓ 𝕩
    d ← s - ⊑"0"
    val ← +´ d × 10 ⋆ ⌽ ↕ ≠ s
    (1 - 2 × isneg) × val
  }
}
