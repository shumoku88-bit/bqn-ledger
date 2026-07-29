# src_edit/journal_reconstructible_identity_cleanup.bqn
# Pure semantic owner and byte-preserving transformer for reconstructible Journal identity cleanup.
#
# Contract (Journal Reconstructible Identity Cleanup 001):
#   - Identifies non-functional migration identities for removal
#   - Preserves functional identities, purchase-shaped identities, and completion identities
#   - Preserves exact bytes of non-event-id lines and structure
#   - Validates accounting semantic parity and Cube / Posting IR equality

util ← •Import "../src/text/parse.bqn"
parser ← •Import "../src/editor/journal_profile.bqn"
inv ← •Import "journal_identity_inventory.bqn"

lf ← @+10

HasPrefix ← { 𝕨 ≡ (≠ 𝕨) ↑ 𝕩 }

IsRemovable ← { 𝕊 r:
  isExp ← r.presence ≡ "EXPLICIT_EVENT_ID"
  noRef ← 0 = r.incoming_reference_count
  noFunc ← ¬ r.has_functional_link
  notPurchase ← ¬ ("purchase-" HasPrefix r.event_id)
  notCompletion ← ¬ (("completion-" HasPrefix r.event_id) ∨ ("plan-" HasPrefix r.event_id))
  isMigration ← (r.lexical_family ≡ "TEXTUAL_OTHER") ∨ ("legacy:" HasPrefix r.event_id) ∨ (r.provenance_class ≡ "TSV_MIGRATION_CANDIDATE")
  isExp ∧ noRef ∧ noFunc ∧ notPurchase ∧ notCompletion ∧ isMigration
}

Analyze ← { 𝕊 raw‿profileName:
  parsed ← parser.ParseWithProfile ⟨raw, profileName⟩
  (parsed.state ≡ "ok") ◶ ⟨
    { 𝕊:
      { state⇐"error", code⇐"parse_failed", diagnostics⇐parsed.diagnostics }
    },
    { 𝕊:
      inventory ← inv.BuildInventory parsed.transactions
      rows ← inventory.rows
      removableMask ← IsRemovable¨ rows
      removableCount ← +´ removableMask

      preservedFunctionalCount ← +´ { 𝕩.disposition ≡ "KEEP_FUNCTIONAL" }¨ rows
      preservedPurchaseCount ← +´ { (𝕩.presence ≡ "EXPLICIT_EVENT_ID") ∧ ("purchase-" HasPrefix 𝕩.event_id) ∧ (¬ 𝕩.has_functional_link) }¨ rows
      explicitCount ← +´ { 𝕩.presence ≡ "EXPLICIT_EVENT_ID" }¨ rows
      identityFreeCount ← +´ { 𝕩.presence ≡ "IDENTITY_FREE" }¨ rows

      rejectedUnknownCount ← explicitCount - (removableCount + preservedFunctionalCount + preservedPurchaseCount)

      removableTxs ← removableMask / parsed.transactions
      removableLines ← {
        tx ← 𝕩
        meta ← ({𝕩.key ≡ "event-id"}¨ tx.metadata) / tx.metadata
        (⊑ meta).source_line
      }¨ removableTxs

      {
        state⇐"ok",
        parsed⇐parsed,
        inventory⇐inventory,
        total_transactions⇐≠rows,
        explicit_event_id⇐explicitCount,
        identity_free⇐identityFreeCount,
        removable_count⇐removableCount,
        preserved_functional⇐preservedFunctionalCount,
        preserved_purchase⇐preservedPurchaseCount,
        rejected_unknown⇐rejectedUnknownCount,
        removable_lines⇐removableLines
      }
    }
  ⟩ @
}

BuildCandidate ← { 𝕊 raw‿profileName‿expectedRemovalCount:
  an ← Analyze ⟨raw, profileName⟩
  (an.state ≡ "ok") ◶ ⟨
    { 𝕊: an },
    { 𝕊:
      (an.rejected_unknown = 0) ◶ ⟨
        { 𝕊: { state⇐"error", code⇐"rejected_unknown_present", message⇐"transactions with unknown/rejected explicit event-ids present", count⇐an.rejected_unknown } },
        { 𝕊:
          (an.removable_count = expectedRemovalCount) ◶ ⟨
            { 𝕊: { state⇐"error", code⇐"removal_count_mismatch", message⇐"actual removal count does not match expected removal count", expected⇐expectedRemovalCount, actual⇐an.removable_count } },
            { 𝕊:
              rawLines ← lf util.SplitKeepEmpty raw
              linesToRemove ← an.removable_lines - 1
              
              # Verify each line to remove is an event-id line
              validRemovalLines ← ∧´ {
                l ← > 𝕩 ⊑ rawLines
                (0 < +´ 0 ∾ ";" ⍷ l) ∧ (0 < +´ 0 ∾ "event-id" ⍷ l)
              }¨ linesToRemove

              (validRemovalLines) ◶ ⟨
                { 𝕊: { state⇐"error", code⇐"invalid_removal_lines", message⇐"target removal line does not match event-id line" } },
                { 𝕊:
                  keepMask ← ¬ (↕ ≠ rawLines) ∊ linesToRemove
                  newLines ← keepMask / rawLines
                  candidateRaw ← 1 ↓ ∾ (lf⊸∾)¨ newLines

                  # Preserve final newline if original had one
                  hasFinalLf ← (0 < ≠ raw) ∧ (lf = ¯1 ⊑ raw)
                  { candidateRaw ∾↩ lf }⍟(hasFinalLf ∧ ((0 = ≠ candidateRaw) ∨ (lf ≠ ¯1 ⊑ candidateRaw))) @

                  candParsed ← parser.ParseWithProfile ⟨candidateRaw, profileName⟩
                  (candParsed.state ≡ "ok") ◶ ⟨
                    { 𝕊: { state⇐"error", code⇐"candidate_parse_failed", message⇐"candidate failed to parse" } },
                    { 𝕊:
                      candInv ← inv.BuildInventory candParsed.transactions
                      candRows ← candInv.rows

                      txOrig ← an.parsed.transactions
                      txNew ← candParsed.transactions
                      txCountOk ← (≠ txOrig) = ≠ txNew

                      CheckTxParity ← {
                        o ← 0 ⊑ 𝕩 ⋄ n ← 1 ⊑ 𝕩
                        (o.date ≡ n.date) ∧ (o.status_marker ≡ n.status_marker) ∧ (o.description ≡ n.description) ∧ (o.layer_name ≡ n.layer_name) ∧ (o.txn_id ≡ n.txn_id) ∧ (o.plan_id ≡ n.plan_id) ∧ (o.allocation_id ≡ n.allocation_id) ∧ ((≠ o.postings) = ≠ n.postings)
                      }
                      pairs ← { idx ← 𝕩 ⋄ ⟨idx ⊑ txOrig, idx ⊑ txNew⟩ }¨ ↕ ≠ txOrig
                      txParityOk ← ∧´ CheckTxParity¨ pairs

                      newExplicitIdCount ← +´ { 𝕩.presence ≡ "EXPLICIT_EVENT_ID" }¨ candRows
                      newIdentityFreeCount ← +´ { 𝕩.presence ≡ "IDENTITY_FREE" }¨ candRows
                      newKeepFunctionalCount ← +´ { 𝕩.disposition ≡ "KEEP_FUNCTIONAL" }¨ candRows
                      newPreservedPurchaseCount ← +´ { (𝕩.presence ≡ "EXPLICIT_EVENT_ID") ∧ ("purchase-" HasPrefix 𝕩.event_id) ∧ (¬ 𝕩.has_functional_link) }¨ candRows

                      countsOk ← (newExplicitIdCount = (an.explicit_event_id - an.removable_count)) ∧ (newIdentityFreeCount = (an.identity_free + an.removable_count)) ∧ (newKeepFunctionalCount = an.preserved_functional) ∧ (newPreservedPurchaseCount = an.preserved_purchase)

                      (txCountOk ∧ txParityOk ∧ countsOk) ◶ ⟨
                        { 𝕊: { state⇐"error", code⇐"candidate_parity_failed", message⇐"candidate semantic parity check failed" } },
                        { 𝕊:
                          {
                            state⇐"ok",
                            candidate_raw⇐candidateRaw,
                            analysis_before⇐an,
                            analysis_after⇐{
                              total_transactions⇐≠candRows,
                              explicit_event_id⇐newExplicitIdCount,
                              identity_free⇐newIdentityFreeCount,
                              preserved_functional⇐newKeepFunctionalCount,
                              preserved_purchase⇐newPreservedPurchaseCount
                            }
                          }
                        }
                      ⟩ @
                    }
                  ⟩ @
                }
              ⟩ @
            }
          ⟩ @
        }
      ⟩ @
    }
  ⟩ @
}

{
  IsRemovable⇐IsRemovable,
  Analyze⇐Analyze,
  BuildCandidate⇐BuildCandidate
}
