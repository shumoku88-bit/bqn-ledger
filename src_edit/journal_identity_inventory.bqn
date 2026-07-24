# src_edit/journal_identity_inventory.bqn
# Pure inventory, reference index, and classification owner for Journal event identities.
#
# Lexical family is a syntax observation. It does not prove semantic meaning,
# provenance, reconstructibility, or deletion safety.
#
# Provenance may be verified, inferred, or unknown.
# Reconstructibility is not deletion authorization.

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

# Lexical family is a syntax observation only.
# TEXTUAL_OTHER means the ID contains alphabetic characters and no dashes;
# it does not prove the ID carries human-readable or business-meaningful content.
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
                  hasAlpha ◶ ⟨{𝕊:"OTHER"}, {𝕊:"TEXTUAL_OTHER"}⟩ @
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

# Provenance classification.
# Provenance confidence is always one of:
#   "not_applicable"    — identity-free transaction
#   "not_verified"      — no evidence of generation pipeline
#   "inferred_from_prefix" — ID prefix matches a known generator pattern
#   "inferred_from_plan_link" — plan-id presence suggests plan completion pipeline
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
                        {𝕊:⟨"UNKNOWN", "not_verified"⟩},
                        {𝕊:⟨"PLAN_COMPLETION_CANDIDATE", "inferred_from_plan_link"⟩}
                      ⟩ @
                    },
                    {𝕊:⟨"REVERSE_COMMAND_CANDIDATE", "inferred_from_prefix"⟩}
                  ⟩ @
                },
                {𝕊:⟨"TRAVEL_EDITOR_CANDIDATE", "inferred_from_prefix"⟩}
              ⟩ @
            },
            {𝕊:⟨"NATIVE_EDITOR_CANDIDATE", "inferred_from_prefix"⟩}
          ⟩ @
        },
        {𝕊:⟨"TSV_MIGRATION_CANDIDATE", "inferred_from_prefix"⟩}
      ⟩ @
    },
    {𝕊:⟨"IDENTITY_FREE", "not_applicable"⟩}
  ⟩ @
}

# Reconstructibility classification.
# This classification does not authorize deletion.
# It means only that a possible reconstruction path has been identified.
# Exact deterministic regeneration has not been verified.
#
# PROVEN_RECONSTRUCTIBLE requires:
#   same inputs produce the same ID,
#   the generating algorithm is identified,
#   all required inputs remain available.
ClassifyReconstructibility ← {𝕊 tx‿provenanceClass‿lexFamily:
  (tx.identity_kind ≡ "physical_fallback") ◶ ⟨
    {𝕊:
      (provenanceClass ≡ "REVERSE_COMMAND_CANDIDATE") ◶ ⟨
        {𝕊:
          (lexFamily ≡ "LEGACY_ENTRY_24HEX") ◶ ⟨
            {𝕊:
              ((provenanceClass ≡ "PLAN_COMPLETION_CANDIDATE") ∨ (provenanceClass ≡ "NATIVE_EDITOR_CANDIDATE") ∨ (provenanceClass ≡ "TRAVEL_EDITOR_CANDIDATE")) ◶ ⟨
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

  # Compute duplicate identity definitions:
  # Count event IDs that appear on more than one durable transaction
  durableIds ← ⟨⟩
  {𝕊 idx:
    tx ← idx ⊑ transactions
    isDurable ← tx.identity_kind ≡ "durable"
    {𝕊: durableIds ∾↩ ⟨tx.source_event_id⟩}⍟isDurable @
  }¨ ↕ ≠ transactions
  # Count unique IDs that appear more than once
  dupCount ← 0
  {𝕊 i:
    thisId ← i ⊑ durableIds
    # Only count on first occurrence to avoid double-counting
    isFirst ← i = ⊑ (thisId⊸≡¨ durableIds) / ↕ ≠ durableIds
    occurrences ← +´ 0 ∾ thisId⊸≡¨ durableIds
    {𝕊: dupCount +↩ 1}⍟(isFirst ∧ (occurrences > 1)) @
  }¨ ↕ ≠ durableIds

  # Compute dangling references: references targeting IDs not defined as any durable event-id
  danglingCount ← +´ 0 ∾ {¬ ∨´ (𝕩.target_id)⊸≡¨ durableIds}¨ refIndex

  # Compute self-references: references where source_ordinal's event-id equals target_id
  selfRefCount ← +´ 0 ∾ {
    srcIdx ← 𝕩.source_ordinal - 1
    srcTx ← srcIdx ⊑ transactions
    (srcTx.identity_kind ≡ "durable") ∧ (srcTx.source_event_id ≡ 𝕩.target_id)
  }¨ refIndex

  rows ← {𝕊 idx:
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

    provResult ← ClassifyProvenance ⟨tx, lexFamily⟩
    provenanceClass ← 0 ⊑ provResult
    provenanceConfidence ← 1 ⊑ provResult
    reconstructibility ← ClassifyReconstructibility ⟨tx, provenanceClass, lexFamily⟩
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
      provenance_class⇐provenanceClass,
      provenance_confidence⇐provenanceConfidence,
      reconstructibility⇐reconstructibility,
      disposition⇐disposition,
      date⇐tx.date,
      description⇐tx.description
    }
  }¨ ↕ ≠ transactions

  {
    rows⇐rows,
    duplicate_identity_definitions⇐dupCount,
    dangling_references⇐danglingCount,
    self_references⇐selfRefCount
  }
}

Summarize ← {𝕊 inv:
  rows ← inv.rows
  CountPresence ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.presence ≡ val}¨ rows }
  CountFamily ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.lexical_family ≡ val}¨ rows }
  CountProvenance ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.provenance_class ≡ val}¨ rows }
  CountConfidence ← { val ← 𝕨 ⋄ +´ 0 ∾ {𝕩.provenance_confidence ≡ val}¨ rows }
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
    family_textual_other⇐"TEXTUAL_OTHER" CountFamily rows,
    family_other⇐"OTHER" CountFamily rows,

    total_incoming_references⇐+´ 0 ∾ {𝕩.incoming_reference_count}¨ rows,
    transactions_with_references⇐+´ 0 ∾ {𝕩.incoming_reference_count > 0}¨ rows,
    duplicate_identity_definitions⇐inv.duplicate_identity_definitions,
    dangling_references⇐inv.dangling_references,
    self_references⇐inv.self_references,

    has_plan_id_count⇐+´ 0 ∾ {𝕩.has_plan_id}¨ rows,
    has_txn_id_count⇐+´ 0 ∾ {𝕩.has_txn_id}¨ rows,
    has_allocation_id_count⇐+´ 0 ∾ {𝕩.has_allocation_id}¨ rows,
    has_actual_event_id_count⇐+´ 0 ∾ {𝕩.has_actual_event_id}¨ rows,
    has_execution_envelope_count⇐+´ 0 ∾ {𝕩.has_execution_envelope}¨ rows,
    has_series_count⇐+´ 0 ∾ {𝕩.has_series}¨ rows,
    has_recur_count⇐+´ 0 ∾ {𝕩.has_recur}¨ rows,
    has_income_budget_count⇐+´ 0 ∾ {𝕩.has_income_budget}¨ rows,

    prov_identity_free⇐"IDENTITY_FREE" CountProvenance rows,
    prov_tsv_migration_candidate⇐"TSV_MIGRATION_CANDIDATE" CountProvenance rows,
    prov_native_editor_candidate⇐"NATIVE_EDITOR_CANDIDATE" CountProvenance rows,
    prov_travel_editor_candidate⇐"TRAVEL_EDITOR_CANDIDATE" CountProvenance rows,
    prov_reverse_cmd_candidate⇐"REVERSE_COMMAND_CANDIDATE" CountProvenance rows,
    prov_plan_completion_candidate⇐"PLAN_COMPLETION_CANDIDATE" CountProvenance rows,
    prov_unknown⇐"UNKNOWN" CountProvenance rows,

    confidence_not_applicable⇐"not_applicable" CountConfidence rows,
    confidence_not_verified⇐"not_verified" CountConfidence rows,
    confidence_inferred_from_prefix⇐"inferred_from_prefix" CountConfidence rows,
    confidence_inferred_from_plan_link⇐"inferred_from_plan_link" CountConfidence rows,

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
    "family_textual_other=" ∾ •Fmt s.family_textual_other,
    "family_other=" ∾ •Fmt s.family_other,
    "",
    "[Incoming References]",
    "total_incoming_references=" ∾ •Fmt s.total_incoming_references,
    "transactions_with_references=" ∾ •Fmt s.transactions_with_references,
    "duplicate_identity_definitions=" ∾ •Fmt s.duplicate_identity_definitions,
    "dangling_references=" ∾ •Fmt s.dangling_references,
    "self_references=" ∾ •Fmt s.self_references,
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
    "prov_tsv_migration_candidate=" ∾ •Fmt s.prov_tsv_migration_candidate,
    "prov_native_editor_candidate=" ∾ •Fmt s.prov_native_editor_candidate,
    "prov_travel_editor_candidate=" ∾ •Fmt s.prov_travel_editor_candidate,
    "prov_reverse_cmd_candidate=" ∾ •Fmt s.prov_reverse_cmd_candidate,
    "prov_plan_completion_candidate=" ∾ •Fmt s.prov_plan_completion_candidate,
    "prov_unknown=" ∾ •Fmt s.prov_unknown,
    "",
    "[Provenance Confidence]",
    "confidence_not_applicable=" ∾ •Fmt s.confidence_not_applicable,
    "confidence_not_verified=" ∾ •Fmt s.confidence_not_verified,
    "confidence_inferred_from_prefix=" ∾ •Fmt s.confidence_inferred_from_prefix,
    "confidence_inferred_from_plan_link=" ∾ •Fmt s.confidence_inferred_from_plan_link,
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

FormatTsv ← {𝕊 inv:
  rows ← inv.rows
  header ← tab Join ⟨ "ordinal", "presence", "lexical_family", "incoming_reference_count", "has_plan_id", "has_txn_id", "has_allocation_id", "has_actual_event_id", "has_execution_envelope", "has_series", "has_recur", "has_income_budget", "provenance_class", "provenance_confidence", "reconstructibility", "disposition" ⟩
  formattedRows ← {
    tab Join ⟨ •Fmt 𝕩.ordinal, 𝕩.presence, 𝕩.lexical_family, •Fmt 𝕩.incoming_reference_count, •Fmt 𝕩.has_plan_id, •Fmt 𝕩.has_txn_id, •Fmt 𝕩.has_allocation_id, •Fmt 𝕩.has_actual_event_id, •Fmt 𝕩.has_execution_envelope, •Fmt 𝕩.has_series, •Fmt 𝕩.has_recur, •Fmt 𝕩.has_income_budget, 𝕩.provenance_class, 𝕩.provenance_confidence, 𝕩.reconstructibility, 𝕩.disposition ⟩
  }¨ rows
  JoinLines (⟨header⟩ ∾ formattedRows)
}

{
  IsLegacyEntryId⇐IsLegacyEntryId,
  ClassifyLexicalFamily⇐ClassifyLexicalFamily,
  BuildReferenceIndex⇐BuildReferenceIndex,
  ClassifyProvenance⇐ClassifyProvenance,
  BuildInventory⇐BuildInventory,
  Summarize⇐Summarize,
  FormatSummary⇐FormatSummary,
  FormatTsv⇐FormatTsv
}
