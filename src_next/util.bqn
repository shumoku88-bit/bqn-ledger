# util.bqn
# Minimal utilities migrated from old src/core/core.bqn.
# Used by date.bqn and config.bqn in src_next/.

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

  LoadChars ⇐ {
    file_path ← 𝕩
    sh ← •SH ⟨"cat", file_path⟩
    (0 = 0 ⊑ sh) ◶ ⟨
      { 𝕊 ⋄
        •Out "ERROR: Could not read file: " ∾ file_path
        •Exit 1
      },
      { 𝕊 ⋄ 1 ⊑ sh }
    ⟩ @
  }

  LoadLines ⇐ {
    raw ← LoadChars 𝕩
    clean ← ((@+13) ≠ raw) / raw
    lines ← (@+10) Split clean
    IsData ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ ⊑"\\") ∧ (⊑ 𝕩 ≠ '#')) ; 0 }
    keep ← IsData ¨ lines
    keep / lines
  }
}
