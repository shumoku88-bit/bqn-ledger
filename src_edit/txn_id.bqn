# txn_id.bqn — stable transaction identity for retryable journal companions.
loader ← •Import "../src_next/loader.bqn"
planid ← •Import "plan_id.bqn"

StartsWith ⇐ planid.StartsWith
Extract ⇐ {𝕊 line:
  fields ← loader.SplitTsvKeepEmpty line
  meta ← (5<≠fields)⊑⟨⟨⟩,5↓fields⟩
  mask ← {"txn_id=" StartsWith 𝕩}¨meta
  value ← ""
  {𝕊: value ↩ 7↓⊑mask/meta}⍟(1=+´mask) @
  value
}

Generate ⇐ {𝕊 request:
  base ← "txn-" ∾ request.date ∾ "-" ∾ planid.Slugify request.memo
  exists ← ∨´base⊸≡¨request.existing_ids
  FindNext ← {𝕊 i:
    Pad2 ← {s←•Fmt 𝕩 ⋄ ((0⌈2-≠s)⥊'0')∾s}
    candidate ← base ∾ "-" ∾ Pad2 i
    (¬∨´candidate⊸≡¨request.existing_ids) ◶ ⟨{𝕊: FindNext i+1}, {𝕊: candidate}⟩ @
  }
  exists ◶ ⟨{𝕊: base}, {𝕊: FindNext 2}⟩ @
}
