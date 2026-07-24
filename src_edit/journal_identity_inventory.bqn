# src_edit/journal_identity_inventory.bqn
# Pure inventory, reference index, generator analysis, and classification owner for Journal event identities.

util ← •Import "../src_next/util.bqn"

lf ← @+10
tab ← @+9

JoinLines ← {
  sep ← lf
  (0 = ≠ 𝕩) ◶ ⟨{ 1 ↓ ∾ (sep⊸∾)¨ 𝕩 }, { "" }⟩ 𝕩
}

Join ← {
  sep ← 𝕨
  (0 = ≠ 𝕩) ◶ ⟨{ 1 ↓ ∾ (sep⊸∾)¨ 𝕩 }, { "" }⟩ 𝕩
}

IsLegacyEntryId ← {𝕊 id:
  (30 = ≠ id) ∧ ("entry-" ≡ 6 ↑ id) ∧ ∧´ 1 ∾ ((6 ↓ id) ∊ "0123456789abcdef")
}

IsHex ← {𝕊 text:
  (0 < ≠ text) ∧ ∧´ 1 ∾ text ∊ "0123456789abcdefABCDEF"
}

HasPrefix ← { 𝕨 ≡ (≠ 𝕨) ↑ 𝕩 }

ClassifyLexicalFamily ← {𝕊 id:
  (0 = ≠ id) ◶ ⟨
    {𝕊:
      isLegacy ← IsLegacyEntryId id
      isLegacy ◶ ⟨
        {𝕊:
          hasDash ← 0 < +´ 0 ∾ '-' = id
          hasDash ◶ ⟨
            {𝕊:
              isOpaque ← IsHex id
              isOpaque ◶ ⟨
                {𝕊:
                  hasAlpha ← 0 < +´ 0 ∾ id ∊ "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                  hasAlpha ◶ ⟨{𝕊:"OTHER"}, {𝕊:"SEMANTIC_TEXT"}⟩ @
                },
                {𝕊:"OPAQUE_HEX"}
              ⟩ @
            },
            {𝕊:
              dashIndices ← (id = '-') / ↕ ≠ id
              firstDash ← ⊑ dashIndices
              prefix ← (firstDash + 1) ↑ id
              suffix ← (firstDash + 1) ↓ id
              isSuffixHex ← IsHex suffix
              isSuffixHex ◶ ⟨{𝕊:"PREFIXED_OTHER"}, {𝕊:"PREFIXED_HEX"}⟩ @
            }
          ⟩ @
        },
        {𝕊:"LEGACY_ENTRY_24HEX"}
      ⟩ @
    },
    {𝕊:"NONE"}
  ⟩ @
}

GetMetaVal ← {
  key ← 𝕨 ⋄ metadata ← 𝕩
  matching ← ({key ≡ 𝕩.key}¨ metadata) / metadata
  (0 = ≠ matching) ◶ ⟨{𝕊:(⊑ matching).value}, {𝕊:""}⟩ @
}

HasMetaKey ← {
  k ← 𝕨
  0 < +´ 0 ∾ {k ≡ 𝕩.key}¨ 𝕩
}

# Extracts incoming reference info across all transactions
BuildReferenceIndex ← {𝕊 transactions:
  recognizedRefKeys ← "actual-event-id" ‿ "source-event-id" ‿ "original-event-id" ‿ "reversal-of" ‿ "parent-event-id" ‿ "related-event-id"
  # Returns list of {target_id, ref_key, source_ordinal, source_layer}
  refs ← ⟨⟩
  {𝕊 idx:
    tx ← idx ⊑ transactions
    # Check all metadata items
    {𝕊 meta:
      key ← meta.key
      val ← meta.value
      isRefKey ← 0 < +´ 0 ∾ {key ≡ 𝕩}¨ recognizedRefKeys
      {𝕊:
        refs ∾↩ ⟨{
          target_id⇐val,
          ref_key⇐key,
          source_ordinal⇐idx + 1,
          source_layer⇐tx.layer_name
        }⟩
      }⍟(isRefKey ∧ (0 < ≠ val)) @
    }¨ tx.metadata
  }¨ ↕ ≠ transactions
  refs
}

ClassifyProvenance ← {𝕊 tx‿lexFamily:
  id ← tx.source_event_id
  (tx.identity_kind ≡ "physical_fallback") ◶ ⟨
    {𝕊:
      (lexFamily ≡ "LEGACY_ENTRY_24HEX") ◶ ⟨
        {𝕊:
          ("tx-" HasPrefix id) ◶ ⟨
            {𝕊:
              (("friend-" HasPrefix id) ∨ ("exchange-" HasPrefix id) ∨ ("israel-" HasPrefix id)) ◶ ⟨
                {𝕊:
                  ("reverse-" HasPrefix id) ◶ ⟨
                    {𝕊:
                      (("plan-" HasPrefix id) ∨ (0 < ≠ tx.plan_id)) ◶ ⟨
                        {𝕊:"manual or unknown"},
                        {𝕊:"plan completion"}
                      ⟩ @
                    },
                    {𝕊:"reverse command"}
                  ⟩ @
                },
                {𝕊:"travel editor"}
              ⟩ @
            },
            {𝕊:"native durable editor"}
          ⟩ @
        },
        {𝕊:"TSV-to-Journal migration"}
      ⟩ @
    },
    {𝕊:"IDENTITY_FREE"}
  ⟩ @
}

ClassifyReconstructibility ← {𝕊 tx‿provenance‿lexFamily:
  (tx.identity_kind ≡ "physical_fallback") ◶ ⟨
    {𝕊:
      (provenance ≡ "reverse command") ◶ ⟨
        {𝕊:
          (lexFamily ≡ "LEGACY_ENTRY_24HEX") ◶ ⟨
            {𝕊:
              ((provenance ≡ "plan completion") ∨ (provenance ≡ "native durable editor") ∨ (provenance ≡ "travel editor")) ◶ ⟨
                {𝕊:"UNKNOWN"},
                {𝕊:"LIKELY_RECONSTRUCTIBLE"}
              ⟩ @
            },
            {𝕊:"NOT_RECONSTRUCTIBLE"}
          ⟩ @
        },
        {𝕊:"NOT_RECONSTRUCTIBLE"}
      ⟩ @
    },
    {𝕊:"IDENTITY_FREE"}
  ⟩ @
}

ClassifyDisposition ← {𝕊 tx‿incomingCount‿hasFunctionalLink‿reconstructibility:
  (tx.identity_kind ≡ "physical_fallback") ◶ ⟨
    {𝕊:
      (incomingCount > 0) ◶ ⟨
        {𝕊:
          hasFunctionalLink ◶ ⟨
            {𝕊:
              (reconstructibility ≡ "NOT_RECONSTRUCTIBLE") ◶ ⟨
                {𝕊:
                  ((reconstructibility ≡ "PROVEN_RECONSTRUCTIBLE") ∨ (reconstructibility ≡ "LIKELY_RECONSTRUCTIBLE")) ◶ ⟨
                    {𝕊:"REVIEW_UNKNOWN"},
                    {𝕊:"REVIEW_RECONSTRUCTIBLE"}
                  ⟩ @
                },
                {𝕊:"KEEP_NONRECONSTRUCTIBLE"}
              ⟩ @
            },
            {𝕊:"KEEP_FUNCTIONAL"}
          ⟩ @
        },
        {𝕊:"KEEP_REFERENCED"}
      ⟩ @
    },
    {𝕊:"IDENTITY_FREE"}
  ⟩ @
}

BuildInventory ← {𝕊 transactions:
  refIndex ← BuildReferenceIndex transactions
  
  {𝕊 idx:
    tx ← idx ⊑ transactions
    isDurable ← tx.identity_kind ≡ "durable"
    eventId ← isDurable ◶ ⟨{𝕊:""}, {𝕊:tx.source_event_id}⟩ @
    presence ← isDurable ⊑ "IDENTITY_FREE" ‿ "EXPLICIT_EVENT_ID"
    lexFamily ← isDurable ◶ ⟨{𝕊:"NONE"}, {𝕊:ClassifyLexicalFamily eventId}⟩ @
    
    # Incoming references targeting this tx's eventId
    incomingCount ← isDurable ◶ ⟨
      {𝕊:0},
      {𝕊:+´ 0 ∾ { (𝕩.target_id ≡ eventId) ∧ (𝕩.source_ordinal ≠ (idx + 1)) }¨ refIndex}
    ⟩ @
    
    # Outgoing functional links
    hasPlanId ← (0 < ≠ tx.plan_id) ∨ ("plan-id" HasMetaKey tx.metadata)
    hasTxnId ← (0 < ≠ tx.txn_id) ∨ ("txn-id" HasMetaKey tx.metadata)
    hasAllocId ← (0 < ≠ tx.allocation_id) ∨ ("allocation-id" HasMetaKey tx.metadata)
    hasActualEventId ← (0 < ≠ tx.actual_event_id) ∨ ("actual-event-id" HasMetaKey tx.metadata)
    hasExecEnv ← (0 < ≠ tx.execution_envelope) ∨ ("execution-envelope" HasMetaKey tx.metadata)
    hasSeries ← "series" HasMetaKey tx.metadata
    hasRecur ← "recur" HasMetaKey tx.metadata
    hasIncomeBudget ← "income-budget" HasMetaKey tx.metadata
    
    hasFunctionalLink ← hasPlanId ∨ hasTxnId ∨ hasAllocId ∨ hasActualEventId ∨ hasExecEnv ∨ hasSeries ∨ hasRecur ∨ hasIncomeBudget
    
    provenance ← ClassifyProvenance ⟨tx, lexFamily⟩
    reconstructibility ← ClassifyReconstructibility ⟨tx, provenance, lexFamily⟩
    disposition ← ClassifyDisposition ⟨tx, incomingCount, hasFunctionalLink, reconstructibility⟩
    
    {
      ordinal⇐idx + 1,
      presence⇐presence,
      event_id⇐eventId,
      lexical_family⇐lexFamily,
      incoming_reference_count⇐incomingCount,
      has_plan_id⇐hasPlanId,
      has_txn_id⇐hasTxnId,
      has_allocation_id⇐hasAllocId,
      has_actual_event_id⇐hasActualEventId,
      has_execution_envelope⇐hasExecEnv,
      has_series⇐hasSeries,
      has_recur⇐hasRecur,
      has_income_budget⇐hasIncomeBudget,
      has_functional_link⇐hasFunctionalLink,
      provenance⇐provenance,
      reconstructibility⇐reconstructibility,
      disposition⇐disposition,
      date⇐tx.date,
      description⇐tx.description
    }
  }¨ ↕ ≠ transactions
}

Summarize ← {𝕊 rows:
  CountPresence ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.presence ≡ val}¨ rows }
  CountFamily ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.lexical_family ≡ val}¨ rows }
  CountProvenance ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.provenance ≡ val}¨ rows }
  CountReconstructibility ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.reconstructibility ≡ val}¨ rows }
  CountDisposition ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.disposition ≡ val}¨ rows }

  {
    total_transactions⇐≠rows,
    identity_free⇐"IDENTITY_FREE" CountPresence rows,
    explicit_event_id⇐"EXPLICIT_EVENT_ID" CountPresence rows,
    
    family_none⇐"NONE" CountFamily rows,
    family_legacy_entry_24hex⇐"LEGACY_ENTRY_24HEX" CountFamily rows,
    family_prefixed_hex⇐"PREFIXED_HEX" CountFamily rows,
    family_prefixed_other⇐"PREFIXED_OTHER" CountFamily rows,
    family_opaque_hex⇐"OPAQUE_HEX" CountFamily rows,
    family_semantic_text⇐"SEMANTIC_TEXT" CountFamily rows,
    family_other⇐"OTHER" CountFamily rows,
    
    total_incoming_references⇐+´ 0 ∾ {𝕩.incoming_reference_count}¨ rows,
    transactions_with_references⇐+´ 0 ∾ {𝕩.incoming_reference_count > 0}¨ rows,
    
    has_plan_id_count⇐+´ 0 ∾ {𝕩.has_plan_id}¨ rows,
    has_txn_id_count⇐+´ 0 ∾ {𝕩.has_txn_id}¨ rows,
    has_allocation_id_count⇐+´ 0 ∾ {𝕩.has_allocation_id}¨ rows,
    has_actual_event_id_count⇐+´ 0 ∾ {𝕩.has_actual_event_id}¨ rows,
    has_execution_envelope_count⇐+´ 0 ∾ {𝕩.has_execution_envelope}¨ rows,
    has_series_count⇐+´ 0 ∾ {𝕩.has_series}¨ rows,
    has_recur_count⇐+´ 0 ∾ {𝕩.has_recur}¨ rows,
    has_income_budget_count⇐+´ 0 ∾ {𝕩.has_income_budget}¨ rows,
    
    prov_identity_free⇐"IDENTITY_FREE" CountProvenance rows,
    prov_tsv_migration⇐"TSV-to-Journal migration" CountProvenance rows,
    prov_native_editor⇐"native durable editor" CountProvenance rows,
    prov_travel_editor⇐"travel editor" CountProvenance rows,
    prov_reverse_cmd⇐"reverse command" CountProvenance rows,
    prov_plan_completion⇐"plan completion" CountProvenance rows,
    prov_manual_unknown⇐"manual or unknown" CountProvenance rows,
    
    recon_identity_free⇐"IDENTITY_FREE" CountReconstructibility rows,
    recon_proven⇐"PROVEN_RECONSTRUCTIBLE" CountReconstructibility rows,
    recon_likely⇐"LIKELY_RECONSTRUCTIBLE" CountReconstructibility rows,
    recon_not⇐"NOT_RECONSTRUCTIBLE" CountReconstructibility rows,
    recon_unknown⇐"UNKNOWN" CountReconstructibility rows,
    
    disp_identity_free⇐"IDENTITY_FREE" CountDisposition rows,
    disp_keep_referenced⇐"KEEP_REFERENCED" CountDisposition rows,
    disp_keep_functional⇐"KEEP_FUNCTIONAL" CountDisposition rows,
    disp_keep_nonreconstructible⇐"KEEP_NONRECONSTRUCTIBLE" CountDisposition rows,
    disp_review_reconstructible⇐"REVIEW_RECONSTRUCTIBLE" CountDisposition rows,
    disp_review_unknown⇐"REVIEW_UNKNOWN" CountDisposition rows
  }
}

FormatSummary ← {𝕊 s:
  lines ← ⟨
    "Journal Event Identity Inventory 002 Summary",
    "total_transactions=" ∾ •Fmt s.total_transactions,
    "identity_free=" ∾ •Fmt s.identity_free,
    "explicit_event_id=" ∾ •Fmt s.explicit_event_id,
    "",
    "[Lexical Families]",
    "family_none=" ∾ •Fmt s.family_none,
    "family_legacy_entry_24hex=" ∾ •Fmt s.family_legacy_entry_24hex,
    "family_prefixed_hex=" ∾ •Fmt s.family_prefixed_hex,
    "family_prefixed_other=" ∾ •Fmt s.family_prefixed_other,
    "family_opaque_hex=" ∾ •Fmt s.family_opaque_hex,
    "family_semantic_text=" ∾ •Fmt s.family_semantic_text,
    "family_other=" ∾ •Fmt s.family_other,
    "",
    "[Incoming References]",
    "total_incoming_references=" ∾ •Fmt s.total_incoming_references,
    "transactions_with_references=" ∾ •Fmt s.transactions_with_references,
    "",
    "[Outgoing Functional Links]",
    "has_plan_id=" ∾ •Fmt s.has_plan_id_count,
    "has_txn_id=" ∾ •Fmt s.has_txn_id_count,
    "has_allocation_id=" ∾ •Fmt s.has_allocation_id_count,
    "has_actual_event_id=" ∾ •Fmt s.has_actual_event_id_count,
    "has_execution_envelope=" ∾ •Fmt s.has_execution_envelope_count,
    "has_series=" ∾ •Fmt s.has_series_count,
    "has_recur=" ∾ •Fmt s.has_recur_count,
    "has_income_budget=" ∾ •Fmt s.has_income_budget_count,
    "",
    "[Provenance]",
    "prov_identity_free=" ∾ •Fmt s.prov_identity_free,
    "prov_tsv_migration=" ∾ •Fmt s.prov_tsv_migration,
    "prov_native_editor=" ∾ •Fmt s.prov_native_editor,
    "prov_travel_editor=" ∾ •Fmt s.prov_travel_editor,
    "prov_reverse_cmd=" ∾ •Fmt s.prov_reverse_cmd,
    "prov_plan_completion=" ∾ •Fmt s.prov_plan_completion,
    "prov_manual_unknown=" ∾ •Fmt s.prov_manual_unknown,
    "",
    "[Reconstructibility]",
    "recon_identity_free=" ∾ •Fmt s.recon_identity_free,
    "recon_proven=" ∾ •Fmt s.recon_proven,
    "recon_likely=" ∾ •Fmt s.recon_likely,
    "recon_not=" ∾ •Fmt s.recon_not,
    "recon_unknown=" ∾ •Fmt s.recon_unknown,
    "",
    "[Deletion Disposition]",
    "disp_identity_free=" ∾ •Fmt s.disp_identity_free,
    "disp_keep_referenced=" ∾ •Fmt s.disp_keep_referenced,
    "disp_keep_functional=" ∾ •Fmt s.disp_keep_functional,
    "disp_keep_nonreconstructible=" ∾ •Fmt s.disp_keep_nonreconstructible,
    "disp_review_reconstructible=" ∾ •Fmt s.disp_review_reconstructible,
    "disp_review_unknown=" ∾ •Fmt s.disp_review_unknown
  ⟩
  JoinLines lines
}

FormatTsv ← {𝕊 rows:
  header ← tab Join ⟨ "ordinal", "presence", "lexical_family", "incoming_reference_count", "has_plan_id", "has_txn_id", "has_allocation_id", "has_actual_event_id", "has_execution_envelope", "has_series", "has_recur", "has_income_budget", "provenance", "reconstructibility", "disposition" ⟩
  formattedRows ← {
    tab Join ⟨ •Fmt 𝕩.ordinal, 𝕩.presence, 𝕩.lexical_family, •Fmt 𝕩.incoming_reference_count, •Fmt 𝕩.has_plan_id, •Fmt 𝕩.has_txn_id, •Fmt 𝕩.has_allocation_id, •Fmt 𝕩.has_actual_event_id, •Fmt 𝕩.has_execution_envelope, •Fmt 𝕩.has_series, •Fmt 𝕩.has_recur, •Fmt 𝕩.has_income_budget, 𝕩.provenance, 𝕩.reconstructibility, 𝕩.disposition ⟩
  }¨ rows
  JoinLines (⟨header⟩ ∾ formattedRows)
}

{
  IsLegacyEntryId⇐IsLegacyEntryId,
  ClassifyLexicalFamily⇐ClassifyLexicalFamily,
  BuildReferenceIndex⇐BuildReferenceIndex,
  BuildInventory⇐BuildInventory,
  Summarize⇐Summarize,
  FormatSummary⇐FormatSummary,
  FormatTsv⇐FormatTsv
}
