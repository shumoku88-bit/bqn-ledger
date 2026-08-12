# Pure owner scope construction from admitted ownership links and canonical evidence.

balance ← •Import "../accounting/account_balance.bqn"
completion ← •Import "../accounting/plan_completion_join.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"application_daily_scope",code⇐code,message⇐message}
}
EmptyAssetScope ← {𝕊 stateValue:
  {state⇐stateValue,scope_id⇐"daily_target_assets",basis_kind⇐"account_balance",rows⇐empty}
}
EmptyObligationScope ← {𝕊 stateValue:
  {state⇐stateValue,scope_id⇐"daily_target_obligations",rows⇐empty}
}
Build ← {𝕊 admitted‿actualFacts‿planFacts‿domain‿observation‿target:
  diagnostics ← admitted.diagnostics
  validDates ← (dates.IsValid observation) ∧ dates.IsValid target
  diagnostics∾↩(¬validDates)/⟨Diagnostic ⟨"daily_scope_date_invalid","observation and target must be strict Gregorian text"⟩⟩
  assetRows ← empty ⋄ obligationRows ← empty
  {𝕊:
    balances ← balance.Build ⟨actualFacts,domain,dates.Ordinal observation⟩
    diagnostics∾↩balances.diagnostics
    joined ← completion.Build ⟨planFacts,actualFacts,planFacts.transactions.index,actualFacts.transactions.index⟩
    diagnostics∾↩joined.diagnostics

    ResolveRow ← {𝕊 i:
      rowDiagnostics ← empty ⋄ assetItems ← empty ⋄ obligationItems ← empty
      kind ← i⊑admitted.rows.kind
      {𝕊:
        key ← i⊑admitted.rows.account_key ⋄ matches ← key⊸≡¨balances.accounts.account_key
        known ← 1=+´matches
        rowDiagnostics∾↩(¬known)/⟨Diagnostic ⟨"daily_asset_account_unknown","asset Account must occur exactly once in selected domain"⟩⟩
        {𝕊:
          row ← ⊑matches/balances.accounts.index
          roleValid ← (row⊑balances.accounts.role)≡"asset"
          rowDiagnostics∾↩(¬roleValid)/⟨Diagnostic ⟨"daily_asset_role_invalid","daily asset Account must have asset role"⟩⟩
          contributors ← row⊑balances.accounts.contributors
          rowDiagnostics∾↩(0=≠contributors)/⟨Diagnostic ⟨"daily_asset_evidence_missing","asset balance requires source-qualified contributors"⟩⟩
          {𝕊:
            assetItems↩⟨{
              asset_id⇐i⊑admitted.rows.scope_id,currency⇐domain,
              coefficient⇐row⊑balances.accounts.closing,scale⇐balances.scale,
              decision⇐"include",reference⇐⊑contributors,contributors⇐contributors
            }⟩
          }⍟(roleValid ∧ 0<≠contributors) @
        }⍟known @
      }⍟(kind≡"asset") @
      {𝕊:
        planId ← i⊑admitted.rows.plan_id ⋄ matches ← planId⊸≡¨joined.rows.plan_id
        known ← 1=+´matches
        rowDiagnostics∾↩(¬known)/⟨Diagnostic ⟨"daily_obligation_plan_unknown","obligation plan_id must occur exactly once"⟩⟩
        {𝕊:
          row ← ⊑matches/joined.rows.index ⋄ relation ← row⊑joined.rows.status
          conflict ← Contains ⟨relation,⟨"duplicate","ambiguous"⟩⟩
          rowDiagnostics∾↩conflict/⟨Diagnostic ⟨"daily_obligation_completion_conflict","completion evidence must be open or completed"⟩⟩
          planCurrency ← row⊑joined.rows.currency
          reservationCurrency ← i⊑admitted.rows.currency
          currencyMismatch ← (0<≠reservationCurrency) ∧ reservationCurrency≢planCurrency
          rowDiagnostics∾↩currencyMismatch/⟨
            Diagnostic ⟨"daily_reservation_currency_mismatch","reservation currency must match Plan"⟩
          ⟩
          {𝕊:
            due ← dates.Ordinal (row⊑joined.rows.plan_date)
            completed ← relation≡"completed" ⋄ outside ← due≥dates.Ordinal target
            excluded ← i⊑admitted.rows.excluded_coefficient
            contributors ← (row⊑joined.rows.planned_debit_contributors)∾(row⊑joined.rows.planned_credit_contributors)
            rowDiagnostics∾↩(0=≠contributors)/⟨Diagnostic ⟨"daily_obligation_evidence_missing","Plan obligation requires Posting contributors"⟩⟩
            {𝕊:
              obligationItems↩⟨{
                obligation_id⇐i⊑admitted.rows.scope_id,due_ordinal⇐due,
                currency⇐planCurrency,coefficient⇐row⊑joined.rows.planned_coefficient,
                scale⇐row⊑joined.rows.planned_scale,settlement_state⇐completed⊑"open"‿"completed",
                decision⇐(completed∨outside)⊑"include"‿"exclude",
                excluded_coefficient⇐excluded,excluded_scale⇐i⊑admitted.rows.excluded_scale,
                reservation_state⇐(excluded>0)⊑"none"‿"proven",
                reservation_ref⇐i⊑admitted.rows.reservation_ref,
                reference⇐row⊑joined.rows.plan_reference,contributors⇐contributors
              }⟩
            }⍟(0<≠contributors) @
          }⍟(¬conflict) @
        }⍟known @
      }⍟(kind≡"obligation") @
      {diagnostics⇐rowDiagnostics,asset_items⇐assetItems,obligation_items⇐obligationItems}
    }

    rowResults ← ResolveRow¨admitted.rows.index
    diagnostics∾↩∾{𝕩.diagnostics}¨rowResults
    assetRows↩∾{𝕩.asset_items}¨rowResults
    obligationRows↩∾{𝕩.obligation_items}¨rowResults
  }⍟((0=≠diagnostics) ∧ validDates) @
  ok ← 0=≠diagnostics
  assetScope ← EmptyAssetScope "error" ⋄ obligationScope ← EmptyObligationScope "error"
  {𝕊:
    assetScope↩{state⇐"resolved",scope_id⇐"daily_target_assets",basis_kind⇐"account_balance",rows⇐assetRows}
    obligationScope↩{state⇐"resolved",scope_id⇐"daily_target_obligations",rows⇐obligationRows}
  }⍟ok @
  {state⇐ok⊑"error"‿"ok",asset_scope⇐assetScope,obligation_scope⇐obligationScope,diagnostics⇐diagnostics}
}

{Build⇐Build}
