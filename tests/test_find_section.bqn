# test_find_section.bqn
lib ← {
  ToNum ⇐ {
    isneg ← '-' = ⊑ 𝕩
    s ← isneg ↓ 𝕩
    d ← s - ⊑"0"
    val ← +´ d × 10 ⋆ ⌽ ↕ ≠ s
    (1 - 2 × isneg) × val
  }
}

sec_keys ← ⟨"snapshot","ytd","balances","cycle","envelopes","planned","recent","check","outlook","daily-trend","cycle-consult","cashflow","residual"⟩
sec_alias_keys ← ⟨"overview","summary","accounts","account","balance","budget","budgets","plan","plans","schedule","validation","trend","consult","advice","risk","forecast","drift","diff"⟩
sec_alias_idx ← ⟨0,0,2,2,2,4,4,5,5,5,7,9,10,10,11,11,12,12⟩

FindSectionIdx ← {
  tok ← 𝕩
  Numeric ← { 𝕊 ⋄
    n ← lib.ToNum tok
    ((0 < n) ∧ n ≤ ≠ sec_keys) ? n - 1 ; ¯1
  }
  NonNumeric ← { 𝕊 ⋄
    idxM ← ⊑ sec_keys ⊐ ⟨ tok ⟩
    (idxM < ≠ sec_keys) ◶ ⟨
      { 𝕊 ⋄
        idxA ← ⊑ sec_alias_keys ⊐ ⟨ tok ⟩
        (idxA < ≠ sec_alias_keys) ◶ ⟨ { 𝕊 ⋄ ¯1 }, { 𝕊 ⋄ idxA ⊑ sec_alias_idx } ⟩ @
      },
      { 𝕊 ⋄ idxM }
    ⟩ @
  }
  
  isNum ← (0 < ≠ tok) ∧ ∧´ tok ∊ "0123456789"
  (isNum ◶ ⟨ NonNumeric, Numeric ⟩) @
}

# Test cases
•Out "Test 1: '1' -> " ∾ •Fmt FindSectionIdx "1"
•Out "Test 2: '13' -> " ∾ •Fmt FindSectionIdx "13"
•Out "Test 3: '0' -> " ∾ •Fmt FindSectionIdx "0"
•Out "Test 4: '14' -> " ∾ •Fmt FindSectionIdx "14"
•Out "Test 5: 'snapshot' -> " ∾ •Fmt FindSectionIdx "snapshot"
•Out "Test 6: 'residual' -> " ∾ •Fmt FindSectionIdx "residual"
•Out "Test 7: 'overview' -> " ∾ •Fmt FindSectionIdx "overview"
•Out "Test 8: 'diff' -> " ∾ •Fmt FindSectionIdx "diff"
•Out "Test 9: 'unknown' -> " ∾ •Fmt FindSectionIdx "unknown"
