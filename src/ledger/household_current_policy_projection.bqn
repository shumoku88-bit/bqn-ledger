# Pure current-policy view of the shared canonical household.toml source.
# Historical Envelope evidence is physically co-located in household.toml but is
# not owned by household_policy_admission.bqn. Remove only the explicitly known
# envelope-history sections; unrelated unknown sections remain visible and are
# therefore still rejected by the strict current-policy owner.

lf ← @+10 ⋄ cr ← @+13 ⋄ space ← @+32 ⋄ tab ← @+9
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs: prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text: groups ← (+`sep=text)⊔text ⋄ {(sep≠𝕩)/𝕩}¨groups}
FirstOrSpace ← {𝕊 text: ⊑text∾⟨space⟩}

IsHeader ← {𝕊 text:
  t ← Trim text
  (2≤≠t) ∧ ('['=FirstOrSpace t) ∧ ']'=FirstOrSpace⌽t
}

IsEnvelopeHistoryHeader ← {𝕊 text:
  Contains ⟨Trim text,⟨
    "[envelope-history]",
    "[[envelope-history.expense-routing]]",
    "[[envelope-history.fulfillment-routing]]"
  ⟩⟩
}

CurrentPolicy ← {𝕊 raw:
  lines ← SplitKeepEmpty ⟨lf,(cr≠raw)/raw⟩
  header ← IsHeader¨lines
  segmentIds ← +`header
  historyIds ← (IsEnvelopeHistoryHeader¨lines)/segmentIds
  historical ← {Contains ⟨𝕩,historyIds⟩}¨segmentIds
  kept ← (¬historical)/lines
  ∾{𝕩∾⟨lf⟩}¨kept
}

{CurrentPolicy⇐CurrentPolicy}
