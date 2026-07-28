# Pure conservative Daily Target over owner-resolved exact evidence.

scale ← •Import "../ledger/exact_scale.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Unique ← {𝕊 values: out←empty ⋄ {𝕊 value:{𝕊:out∾↩⟨value⟩}⍟(¬Contains ⟨value,out⟩) @}¨values ⋄ out}
Diagnostic ← {𝕊 severity‿code‿message‿refs:
  {severity⇐severity,stage⇐"accounting_daily_target",code⇐code,message⇐message,evidence_refs⇐refs}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyCalculation ← {𝕊:
  {
    eligible_assets⇐empty,gross_obligations⇐empty,already_excluded⇐empty,
    obligation_deduction⇐empty,capacity_balance⇐empty,remaining_days⇐empty,
    daily_target⇐empty,daily_shortfall⇐empty
  }
}
EmptyResult ← {𝕊 state‿reason‿domain‿diagnostics:
  {
    state⇐state,reason⇐reason,domain⇐domain,observation⇐"",target_date⇐"",scale⇐0,
    asset_evidence⇐empty,obligation_evidence⇐empty,
    calculation⇐EmptyCalculation @,diagnostics⇐diagnostics
  }
}

ValidateCoordinates ← {𝕊 observation‿target:
  diagnostics ← empty
  observationValid ← dates.IsValid observation
  targetValid ← dates.IsValid target
  diagnostics∾↩AddIf ⟨¬observationValid,Diagnostic ⟨"error","observation_invalid","observation must be strict Gregorian text",⟨observation⟩⟩⟩
  diagnostics∾↩AddIf ⟨¬targetValid,Diagnostic ⟨"error","target_date_invalid","target date must be strict Gregorian text",⟨target⟩⟩⟩
  {𝕊:
    orderInvalid ← (dates.Ordinal observation)≥dates.Ordinal target
    diagnostics∾↩AddIf ⟨orderInvalid,Diagnostic ⟨"error","target_not_after_observation","target must be after observation",⟨observation,target⟩⟩⟩
  }⍟(observationValid∧targetValid) @
  diagnostics
}

ValidateAssets ← {𝕊 scope‿domain:
  diagnostics ← empty
  knownState ← Contains ⟨scope.state,⟨"resolved","unavailable","error"⟩⟩
  diagnostics∾↩AddIf ⟨¬knownState,Diagnostic ⟨"error","asset_scope_error","asset scope state invalid",⟨scope.scope_id⟩⟩⟩
  diagnostics∾↩AddIf ⟨scope.state≡"unavailable",Diagnostic ⟨"unavailable","asset_scope_unavailable","asset ownership unavailable",⟨scope.scope_id⟩⟩⟩
  diagnostics∾↩AddIf ⟨scope.state≡"error",Diagnostic ⟨"error","asset_scope_error","asset scope rejected",⟨scope.scope_id⟩⟩⟩
  {𝕊:
    ids ← {𝕩.asset_id}¨scope.rows
    diagnostics∾↩AddIf ⟨(≠ids)≠≠Unique ids,Diagnostic ⟨"error","duplicate_asset_id","asset identities must be unique",ids⟩⟩
    diagnostics∾↩AddIf ⟨scope.basis_kind≢"account_balance",Diagnostic ⟨"error","asset_basis_invalid","P1 requires one account_balance basis",⟨scope.basis_kind⟩⟩⟩
    invalid ← {𝕊 row:
      decisionInvalid ← ¬Contains ⟨row.decision,⟨"include","exclude"⟩⟩
      domainInvalid ← row.currency≢domain
      scaleInvalid ← (row.scale<0) ∨ row.scale≠⌊row.scale
      evidenceInvalid ← (0=≠row.reference.source) ∨ 0=≠row.contributors
      decisionInvalid ∨ domainInvalid ∨ scaleInvalid ∨ evidenceInvalid
    }¨scope.rows
    diagnostics∾↩AddIf ⟨∨´0∾invalid,Diagnostic ⟨"error","asset_row_invalid","asset evidence row invalid",invalid/ids⟩⟩
  }⍟(scope.state≡"resolved") @
  diagnostics
}

ValidateObligations ← {𝕊 scope‿domain‿targetOrdinal:
  diagnostics ← empty
  knownState ← Contains ⟨scope.state,⟨"resolved","unavailable","error"⟩⟩
  diagnostics∾↩AddIf ⟨¬knownState,Diagnostic ⟨"error","obligation_scope_error","obligation scope state invalid",⟨scope.scope_id⟩⟩⟩
  diagnostics∾↩AddIf ⟨scope.state≡"unavailable",Diagnostic ⟨"unavailable","obligation_scope_unavailable","obligation ownership unavailable",⟨scope.scope_id⟩⟩⟩
  diagnostics∾↩AddIf ⟨scope.state≡"error",Diagnostic ⟨"error","obligation_scope_error","obligation scope rejected",⟨scope.scope_id⟩⟩⟩
  {𝕊:
    rows ← scope.rows ⋄ ids ← {𝕩.obligation_id}¨rows
    diagnostics∾↩AddIf ⟨(≠ids)≠≠Unique ids,Diagnostic ⟨"error","duplicate_obligation_id","obligation identities must be unique",ids⟩⟩
    invalid ← {𝕊 row:
      decisionInvalid ← ¬Contains ⟨row.decision,⟨"include","exclude"⟩⟩
      settlementInvalid ← ¬Contains ⟨row.settlement_state,⟨"open","completed"⟩⟩
      reservationInvalid ← ¬Contains ⟨row.reservation_state,⟨"none","proven","ambiguous"⟩⟩
      amountInvalid ← (row.coefficient<0) ∨ (row.scale<0) ∨ row.scale≠⌊row.scale
      amountInvalid ∨↩ (row.excluded_coefficient<0) ∨ (row.excluded_scale<0) ∨ row.excluded_scale≠⌊row.excluded_scale
      coordinateInvalid ← (row.due_ordinal<0) ∨ row.due_ordinal≠⌊row.due_ordinal
      evidenceInvalid ← (row.currency≢domain) ∨ (0=≠row.reference.source) ∨ 0=≠row.contributors
      amountInvalid ∨↩ coordinateInvalid
      decisionInvalid ∨ settlementInvalid ∨ reservationInvalid ∨ amountInvalid ∨ evidenceInvalid
    }¨rows
    diagnostics∾↩AddIf ⟨∨´0∾invalid,Diagnostic ⟨"error","obligation_row_invalid","obligation evidence row invalid",invalid/ids⟩⟩
    included ← {𝕩.decision≡"include"}¨rows
    completed ← included ∧ {𝕩.settlement_state≡"completed"}¨rows
    outside ← included ∧ {𝕩.due_ordinal≥targetOrdinal}¨rows
    diagnostics∾↩AddIf ⟨∨´0∾completed,Diagnostic ⟨"error","completed_obligation_included","completed obligation cannot be included",completed/ids⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾outside,Diagnostic ⟨"error","obligation_outside_horizon","included obligation must be due before target",outside/ids⟩⟩
    ambiguous ← included ∧ {𝕩.reservation_state≡"ambiguous"}¨rows
    diagnostics∾↩AddIf ⟨∨´0∾ambiguous,Diagnostic ⟨"unavailable","reservation_provenance_ambiguous","reservation provenance ambiguous",ambiguous/ids⟩⟩
    proven ← included ∧ {𝕩.reservation_state≡"proven"}¨rows
    none ← included ∧ {𝕩.reservation_state≡"none"}¨rows
    positive ← {𝕩.excluded_coefficient>0}¨rows
    missing ← included ∧ positive ∧ ¬proven
    provenMissingRef ← proven ∧ {0=≠𝕩.reservation_ref}¨rows
    provenZero ← proven ∧ ¬positive
    noneMismatch ← none ∧ (positive ∨ {0<≠𝕩.reservation_ref}¨rows)
    diagnostics∾↩AddIf ⟨∨´0∾missing,Diagnostic ⟨"error","reservation_provenance_missing","positive exclusion requires proven reservation",missing/ids⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾provenMissingRef,Diagnostic ⟨"error","reservation_provenance_missing","proven reservation requires reference",provenMissingRef/ids⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾provenZero,Diagnostic ⟨"error","reservation_amount_invalid","proven reservation requires positive excluded amount",provenZero/ids⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾noneMismatch,Diagnostic ⟨"error","reservation_amount_invalid","none reservation cannot exclude amount",noneMismatch/ids⟩⟩
    usedRefs ← (proven∧positive)/{𝕩.reservation_ref}¨rows
    diagnostics∾↩AddIf ⟨(≠usedRefs)≠≠Unique usedRefs,Diagnostic ⟨"error","duplicate_reservation_linkage","reservation reference cannot be reused",usedRefs⟩⟩
  }⍟(scope.state≡"resolved") @
  diagnostics
}

NormalizeRows ← {𝕊 assetRows‿obligationRows:
  includedAssets ← ({𝕩.decision≡"include"}¨assetRows)/assetRows
  includedObligations ← ({𝕩.decision≡"include"}¨obligationRows)/obligationRows
  scales ← ({𝕩.scale}¨includedAssets)∾({𝕩.scale}¨includedObligations)∾{𝕩.excluded_scale}¨includedObligations
  targetScale ← 0 ⋄ {𝕊:targetScale↩⌈´scales}⍟(0<≠scales) @
  assetNormalized ← {scale.Normalize ⟨𝕩.coefficient,𝕩.scale,targetScale⟩}¨includedAssets
  obligationNormalized ← {scale.Normalize ⟨𝕩.coefficient,𝕩.scale,targetScale⟩}¨includedObligations
  excludedNormalized ← {scale.Normalize ⟨𝕩.excluded_coefficient,𝕩.excluded_scale,targetScale⟩}¨includedObligations
  ok ← ∧´1∾{𝕩.state≡"ok"}¨assetNormalized∾obligationNormalized∾excludedNormalized
  assetValues ← {𝕩.coefficient}¨assetNormalized
  obligationValues ← {𝕩.coefficient}¨obligationNormalized
  excludedValues ← {𝕩.coefficient}¨excludedNormalized
  assetEvidence ← {𝕊 i:
    row ← i⊑includedAssets
    {asset_id⇐row.asset_id,coefficient⇐i⊑assetValues,scale⇐targetScale,reference⇐row.reference,contributors⇐row.contributors}
  }¨↕≠includedAssets
  obligationEvidence ← {𝕊 i:
    row ← i⊑includedObligations
    deduction ← scale.Sum ⟨i⊑obligationValues,-(i⊑excludedValues)⟩
    {
      obligation_id⇐row.obligation_id,due_ordinal⇐row.due_ordinal,
      coefficient⇐i⊑obligationValues,excluded_coefficient⇐i⊑excludedValues,
      deduction_coefficient⇐deduction.coefficient,scale⇐targetScale,
      reservation_state⇐row.reservation_state,reservation_ref⇐row.reservation_ref,
      reference⇐row.reference,contributors⇐row.contributors
    }
  }¨↕≠includedObligations
  {
    state⇐ok⊑"error"‿"ok",scale⇐targetScale,
    assets⇐assetValues,obligations⇐obligationValues,excluded⇐excludedValues,
    asset_evidence⇐assetEvidence,obligation_evidence⇐obligationEvidence
  }
}

Calculate ← {𝕊 normalized‿remainingDays:
  eligible ← scale.Sum normalized.assets
  gross ← scale.Sum normalized.obligations
  excluded ← scale.Sum normalized.excluded
  deduction ← {state⇐"error",coefficient⇐empty}
  capacity ← {state⇐"error",coefficient⇐empty}
  {𝕊:deduction↩scale.Sum ⟨gross.coefficient,-excluded.coefficient⟩}⍟((gross.state≡"ok")∧excluded.state≡"ok") @
  {𝕊:capacity↩scale.Sum ⟨eligible.coefficient,-deduction.coefficient⟩}⍟((eligible.state≡"ok")∧deduction.state≡"ok") @
  ok ← ∧´{𝕩.state≡"ok"}¨⟨eligible,gross,excluded,deduction,capacity⟩
  result ← {state⇐"error",calculation⇐EmptyCalculation @}
  {𝕊:
    dailyTarget ← 0 ⋄ shortfall ← 0 ⋄ state ← "ok"
    {𝕊:dailyTarget↩⌊capacity.coefficient÷remainingDays}⍟(capacity.coefficient≥0) @
    {𝕊:state↩"deficit" ⋄ shortfall↩⌈(-capacity.coefficient)÷remainingDays}⍟(capacity.coefficient<0) @
    result↩{
      state⇐state,
      calculation⇐{
        eligible_assets⇐eligible.coefficient,gross_obligations⇐gross.coefficient,
        already_excluded⇐excluded.coefficient,obligation_deduction⇐deduction.coefficient,
        capacity_balance⇐capacity.coefficient,remaining_days⇐remainingDays,
        daily_target⇐dailyTarget,daily_shortfall⇐shortfall
      }
    }
  }⍟ok @
  result
}

Build ← {𝕊 observation‿target‿domain‿assetScope‿obligationScope:
  diagnostics ← ValidateCoordinates ⟨observation,target⟩
  targetOrdinal ← 0 ⋄ targetValid ← dates.IsValid target
  {𝕊:targetOrdinal↩dates.Ordinal target}⍟targetValid @
  diagnostics∾↩ValidateAssets ⟨assetScope,domain⟩
  {𝕊:diagnostics∾↩ValidateObligations ⟨obligationScope,domain,targetOrdinal⟩}⍟targetValid @
  severities ← {𝕩.severity}¨diagnostics
  unavailable ← Contains ⟨"unavailable",severities⟩
  error ← Contains ⟨"error",severities⟩
  state ← "error" ⋄ reason ← ""
  {𝕊:state↩"unavailable" ⋄ reason↩(⊑("unavailable"⊸≡¨severities)/{𝕩.code}¨diagnostics)}⍟(unavailable∧¬error) @
  result ← EmptyResult ⟨state,reason,domain,diagnostics⟩
  {𝕊:
    normalized ← NormalizeRows ⟨assetScope.rows,obligationScope.rows⟩
    diagnostics∾↩AddIf ⟨normalized.state≢"ok",Diagnostic ⟨"error","coefficient_normalization_failed","evidence cannot normalize exactly",empty⟩⟩
    reservationAmountsOk ← ∧´1∾normalized.excluded≤normalized.obligations
    diagnostics∾↩AddIf ⟨¬reservationAmountsOk,Diagnostic ⟨"error","reservation_amount_invalid","excluded amount cannot exceed obligation",empty⟩⟩
    {𝕊:
      remainingDays ← targetOrdinal-dates.Ordinal observation
      calculated ← Calculate ⟨normalized,remainingDays⟩
      diagnostics∾↩AddIf ⟨calculated.state≡"error",Diagnostic ⟨"error","coefficient_sum_failed","Daily Target arithmetic exceeds exact range",empty⟩⟩
      {𝕊:
        result↩{
          state⇐calculated.state,reason⇐"",domain⇐domain,observation⇐observation,target_date⇐target,
          scale⇐normalized.scale,asset_evidence⇐normalized.asset_evidence,
          obligation_evidence⇐normalized.obligation_evidence,
          calculation⇐calculated.calculation,diagnostics⇐empty
        }
      }⍟(∨´calculated.state⊸≡¨⟨"ok","deficit"⟩) @
    }⍟((normalized.state≡"ok") ∧ reservationAmountsOk) @
    {𝕊:result↩EmptyResult ⟨"error","",domain,diagnostics⟩}⍟(0<≠diagnostics) @
  }⍟(0=≠diagnostics) @
  result
}

{Build⇐Build}
