# Open Plan -> observation-day historical routing -> Envelope Commitment.
# Plan lifecycle is role-neutral. Expense postings use Expense routing; positive
# non-Expense postings use stable PlanId Fulfillment routing. Current envelope.toml
# assignments are not an input.

planObservation ← •Import "plan_observation.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_commitment",code⇐code,message⇐message}}
AddIf ← {𝕊 bad‿d:bad/⟨d⟩}
EmptyManaged ← {𝕊:{count⇐0,index⇐empty,envelope_id⇐empty,commitment⇐empty,plan_contributors⇐empty,posting_contributors⇐empty,route_source_rows⇐empty}}
EmptyLane ← {𝕊:{count⇐0,index⇐empty,plan_id⇐empty,target_account_key⇐empty,coefficient⇐empty,contributors⇐empty,posting_contributors⇐empty,route_source_row⇐empty}}
EmptyEvidence ← {𝕊:{count⇐0,index⇐empty,plan_id⇐empty,plan_date⇐empty,target_account_key⇐empty,target_role⇐empty,coefficient⇐empty,scale⇐empty,route⇐empty,target_id⇐empty,route_source_row⇐empty,plan_reference⇐empty,posting_reference⇐empty}}
EmptyResult ← {𝕊 state‿domain‿start‿finish‿observation‿ds:{state⇐state,domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,scale⇐0,managed⇐EmptyManaged @,unmanaged⇐EmptyLane @,unrouted⇐EmptyLane @,evidence⇐EmptyEvidence @,diagnostics⇐ds}}
ExpenseRouteAt ← {𝕊 key‿day‿routing:
  mask←(key⊸≡¨routing.expense_account_key)∧(routing.initial∨routing.effective_ordinal≤day) ⋄ rows←mask/routing.index ⋄ route←"unrouted" ⋄ target←"" ⋄ sourceRow←0 ⋄ ambiguous←0
  {𝕊:ords←rows⊏routing.effective_ordinal ⋄ latest←⌈´ords ⋄ rs←(ords=latest)/rows ⋄ ambiguous↩1≠≠rs ⋄ {𝕊:r←⊑rs ⋄ route↩r⊑routing.route ⋄ target↩r⊑routing.target_id ⋄ sourceRow↩r⊑routing.source_row}⍟(1=≠rs) @}⍟(0<≠rows) @
  {route⇐route,target_id⇐target,source_row⇐sourceRow,ambiguous⇐ambiguous}}
FulfillmentRouteAt ← {𝕊 planId‿day‿routing:
  mask←(planId⊸≡¨routing.plan_id)∧routing.effective_ordinal≤day ⋄ rows←mask/routing.index ⋄ route←"none" ⋄ target←"" ⋄ sourceRow←0 ⋄ ambiguous←0
  {𝕊:ords←rows⊏routing.effective_ordinal ⋄ latest←⌈´ords ⋄ rs←(ords=latest)/rows ⋄ ambiguous↩1≠≠rs ⋄ {𝕊:r←⊑rs ⋄ route↩r⊑routing.route ⋄ target↩r⊑routing.target_id ⋄ sourceRow↩r⊑routing.source_row}⍟(1=≠rs) @}⍟(0<≠rows) @
  {route⇐route,target_id⇐target,source_row⇐sourceRow,ambiguous⇐ambiguous}}

Build ← {𝕊 planFacts‿retirements‿actualFacts‿history‿domain‿start‿finish‿observation:
  ds←empty ⋄ ds∾↩AddIf ⟨history.state≢"ok",Diagnostic ⟨"envelope_history_invalid","Envelope history must be admitted"⟩⟩
  domainKnown←∨´0∾domain⊸≡¨actualFacts.domains.code
  ds∾↩AddIf ⟨¬domainKnown,Diagnostic ⟨"domain_unknown","selected domain must occur in Actual facts"⟩⟩
  ds∾↩AddIf ⟨(start≥finish)∨(observation<start)∨observation≥finish,Diagnostic ⟨"observation_range_invalid","require start <= observation < end_exclusive"⟩⟩
  ds∾↩AddIf ⟨planFacts.accounts.key≢actualFacts.accounts.key,Diagnostic ⟨"account_axis_mismatch","Plan and Actual must share Account axis"⟩⟩
  result←EmptyResult ⟨"error",domain,start,finish,observation,ds⟩
  {𝕊:
    life←planObservation.Build ⟨planFacts,retirements,actualFacts,observation⟩ ⋄ ds∾↩life.diagnostics
    {𝕊:
      tx←life.open_transaction_indices ⋄ txMask←(tx⊏planFacts.transactions.date_ordinal)<finish
      txDomains←(tx⊏planFacts.transactions.domain_index)⊏planFacts.domains.code ⋄ txMask∧↩domain⊸≡¨txDomains ⋄ selectedTx←txMask/tx
      postingMask←(planFacts.postings.transaction_index∊selectedTx)∧planFacts.postings.coefficient>0 ⋄ postings←postingMask/planFacts.postings.index
      postingTx←postings⊏planFacts.postings.transaction_index ⋄ postingAccounts←postings⊏planFacts.postings.account_index
      roles←postingAccounts⊏planFacts.accounts.role ⋄ keys←postingAccounts⊏planFacts.accounts.key ⋄ planIds←postingTx⊏planFacts.transactions.plan_id ⋄ isExpense←"expense"⊸≡¨roles
      hasExpense←{𝕊 t:∨´0∾isExpense∧t=postingTx}¨selectedTx
      HasAssetFunding←{𝕊 t:local←(t=planFacts.postings.transaction_index)/planFacts.postings.index ⋄ localRoles←(local⊏planFacts.postings.account_index)⊏planFacts.accounts.role ⋄ ∨´0∾("asset"⊸≡¨localRoles)∧(local⊏planFacts.postings.coefficient)<0}
      ds∾↩AddIf ⟨∨´0∾hasExpense∧¬HasAssetFunding¨selectedTx,Diagnostic ⟨"expense_commitment_flow_invalid","Expense commitment requires negative Asset funding"⟩⟩
      {𝕊:
        Resolve←{𝕊 i:(i⊑isExpense)◶⟨{𝕊:FulfillmentRouteAt ⟨i⊑planIds,observation,history.fulfillment_routing⟩},{𝕊:ExpenseRouteAt ⟨i⊑keys,observation,history.expense_routing⟩}⟩ @}
        resolved←Resolve¨↕≠postings ⋄ ds∾↩AddIf ⟨∨´0∾{𝕩.ambiguous}¨resolved,Diagnostic ⟨"commitment_route_effective_ambiguous","effective route must be unique"⟩⟩
        routes←{𝕩.route}¨resolved ⋄ targets←{𝕩.target_id}¨resolved ⋄ sourceRows←{𝕩.source_row}¨resolved
        managedMask←("managed"⊸≡¨routes)∨"fulfills"⊸≡¨routes ⋄ unmanagedMask←isExpense∧"unmanaged"⊸≡¨routes ⋄ unroutedMask←isExpense∧"unrouted"⊸≡¨routes ⋄ relevant←managedMask∨unmanagedMask∨unroutedMask
        postingCoefficients←postings⊏planFacts.postings.coefficient ⋄ postingScales←postings⊏planFacts.postings.scale
        targetScale←⌈´0∾relevant/postingScales ⋄ norms←(relevant/postingCoefficients) {scale.Normalize ⟨𝕨,𝕩,targetScale⟩}¨ relevant/postingScales
        ds∾↩AddIf ⟨¬∧´1∾{𝕩.state≡"ok"}¨norms,Diagnostic ⟨"coefficient_normalization_failed","Commitment quantities cannot normalize exactly"⟩⟩
        {𝕊:
          normalized←{𝕩.coefficient}¨norms ⋄ relevantPostings←relevant/postings ⋄ relevantPlanIds←relevant/planIds ⋄ relevantKeys←relevant/keys ⋄ relevantTargets←relevant/targets ⋄ relevantRows←relevant/sourceRows
          relevantManaged←relevant/managedMask ⋄ relevantUnmanaged←relevant/unmanagedMask ⋄ relevantUnrouted←relevant/unroutedMask
          envelopeIds←history.registry.id ⋄ envelopeCoords←envelopeIds⊐relevantManaged/relevantTargets
          ds∾↩AddIf ⟨¬∧´1∾envelopeCoords<≠envelopeIds,Diagnostic ⟨"commitment_route_target_unknown","managed route target must be a stable Envelope"⟩⟩
          {𝕊:
            managedAmounts←relevantManaged/normalized ⋄ sums←{scale.Sum (envelopeCoords=𝕩)/managedAmounts}¨↕≠envelopeIds
            ds∾↩AddIf ⟨¬∧´1∾{𝕩.state≡"ok"}¨sums,Diagnostic ⟨"coefficient_sum_failed","Envelope Commitment exceeds exact range"⟩⟩
            {𝕊:
              relevantTx←relevantPostings⊏planFacts.postings.transaction_index ⋄ txRefs←{reference.Transaction ⟨planFacts,𝕩⟩}¨relevantTx ⋄ postRefs←{reference.Posting ⟨planFacts,𝕩⟩}¨relevantPostings
              managedTxRefs←relevantManaged/txRefs ⋄ managedPostRefs←relevantManaged/postRefs ⋄ managedRows←relevantManaged/relevantRows
              managed←{count⇐≠envelopeIds,index⇐↕≠envelopeIds,envelope_id⇐envelopeIds,commitment⇐{𝕩.coefficient}¨sums,plan_contributors⇐{(envelopeCoords=𝕩)/managedTxRefs}¨↕≠envelopeIds,posting_contributors⇐{(envelopeCoords=𝕩)/managedPostRefs}¨↕≠envelopeIds,route_source_rows⇐{(envelopeCoords=𝕩)/managedRows}¨↕≠envelopeIds}
              Lane←{𝕊 mask:{count⇐+´mask,index⇐↕+´mask,plan_id⇐mask/relevantPlanIds,target_account_key⇐mask/relevantKeys,coefficient⇐mask/normalized,contributors⇐mask/txRefs,posting_contributors⇐mask/postRefs,route_source_row⇐mask/relevantRows}}
              evidence←{count⇐≠postings,index⇐↕≠postings,plan_id⇐planIds,plan_date⇐postingTx⊏planFacts.transactions.date_text,target_account_key⇐keys,target_role⇐roles,coefficient⇐postingCoefficients,scale⇐postingScales,route⇐routes,target_id⇐targets,route_source_row⇐sourceRows,plan_reference⇐{reference.Transaction ⟨planFacts,𝕩⟩}¨postingTx,posting_reference⇐{reference.Posting ⟨planFacts,𝕩⟩}¨postings}
              result↩{state⇐"ok",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,scale⇐targetScale,managed⇐managed,unmanaged⇐Lane relevantUnmanaged,unrouted⇐Lane relevantUnrouted,evidence⇐evidence,diagnostics⇐empty}
            }⍟(0=≠ds) @
          }⍟(0=≠ds) @
        }⍟(0=≠ds) @
      }⍟(0=≠ds) @
    }⍟(0=≠ds) @
  }⍟(0=≠ds) @
  {𝕊:result↩EmptyResult ⟨"error",domain,start,finish,observation,ds⟩}⍟(0<≠ds) @ ⋄ result
}
{Build⇐Build}
