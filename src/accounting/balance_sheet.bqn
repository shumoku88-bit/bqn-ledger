# Pure Actual balance-sheet classification at one explicit observation.
# Income and expense balances remain unclosed and are exposed as one result line.

balances ← •Import "account_balance.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_balance_sheet",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyRows ← {𝕊:
  {count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,balance⇐empty,contributors⇐empty}
}
EmptyResult ← {𝕊 domainCode‿diagnosticsValue:
  {
    state⇐"error",domain⇐domainCode,observation_ordinal⇐0,scale⇐0,
    assets⇐EmptyRows @,liabilities⇐EmptyRows @,equity⇐EmptyRows @,
    total_assets⇐empty,total_liabilities⇐empty,stated_equity⇐empty,
    unclosed_result⇐empty,total_equity⇐empty,total_liabilities_and_equity⇐empty,
    difference⇐empty,balanced⇐0,unclosed_result_contributors⇐empty,
    diagnostics⇐diagnosticsValue
  }
}
Rows ← {𝕊 source‿rowIndices‿amounts:
  {
    count⇐≠rowIndices,index⇐↕≠rowIndices,
    account_index⇐rowIndices⊏source.account_index,account_key⇐rowIndices⊏source.account_key,
    balance⇐amounts,contributors⇐rowIndices⊏source.contributors
  }
}

Build ← {𝕊 facts‿domainCode‿observationOrdinal:
  accountBalances ← balances.Build ⟨facts,domainCode,observationOrdinal⟩
  diagnostics ← accountBalances.diagnostics
  result ← EmptyResult ⟨domainCode,diagnostics⟩
  {𝕊:
    source ← accountBalances.accounts
    statementRoles ← ⟨"asset","liability","equity","income","expense"⟩
    roleCoordinates ← statementRoles⊐source.role

    # a: canonical Account rows; s: asset / liability / equity / unclosed-result / unsupported-check lanes.
    # Income and expense share s=3; unmatched roles map to s=4. Group preserves Account and contributor order.
    # Statement signs publish liabilities, Equity, and unclosed result on the right-hand side; trailing s=5 retains empty lanes.
    laneCoordinates ← roleCoordinates⊏⟨0,1,2,3,3,4⟩
    statementSigns ← roleCoordinates⊏⟨1,-1,-1,-1,-1,1⟩
    statementBalances ← statementSigns×source.closing
    laneCount ← 5
    groupCoordinates ← laneCoordinates∾laneCount
    rowGroups ← groupCoordinates⊔source.index
    amountGroups ← groupCoordinates⊔statementBalances
    contributorGroups ← groupCoordinates⊔source.contributors
    laneSums ← scale.Sum¨amountGroups
    sumsOk ← ∧´{𝕩.state≡"ok"}¨laneSums
    diagnostics ∾↩ AddIf ⟨¬sumsOk,Diagnostic ⟨"balance_sheet_sum_failed","Balance Sheet totals exceed exact range"⟩⟩
    {𝕊:
      assetTotal‿liabilityTotal‿equityTotal‿unclosedResult‿unsupportedTotal ← {𝕩.coefficient}¨laneSums
      diagnostics ∾↩ AddIf ⟨unsupportedTotal≠0,Diagnostic ⟨"unsupported_role_balance","non-statement Account roles must have zero Actual balance"⟩⟩
      {𝕊:
        totalEquityResult ← scale.Sum ⟨equityTotal,unclosedResult⟩
        diagnostics ∾↩ AddIf ⟨totalEquityResult.state≢"ok",Diagnostic ⟨"balance_sheet_sum_failed","total Equity exceeds exact range"⟩⟩
        {𝕊:
          rightResult ← scale.Sum ⟨liabilityTotal,totalEquityResult.coefficient⟩
          diagnostics ∾↩ AddIf ⟨rightResult.state≢"ok",Diagnostic ⟨"balance_sheet_sum_failed","Liabilities plus Equity exceeds exact range"⟩⟩
          {𝕊:
            differenceResult ← scale.Sum ⟨assetTotal,-rightResult.coefficient⟩
            diagnostics ∾↩ AddIf ⟨differenceResult.state≢"ok",Diagnostic ⟨"balance_sheet_sum_failed","Balance Sheet difference exceeds exact range"⟩⟩
            {𝕊:
              balanced ← accountBalances.balanced ∧ differenceResult.coefficient=0
              diagnostics ∾↩ AddIf ⟨¬balanced,Diagnostic ⟨"balance_sheet_not_balanced","Assets must equal Liabilities plus Equity and unclosed result"⟩⟩
              {𝕊:
                result↩{
                  state⇐"ok",domain⇐domainCode,observation_ordinal⇐observationOrdinal,scale⇐accountBalances.scale,
                  assets⇐Rows ⟨source,0⊑rowGroups,0⊑amountGroups⟩,
                  liabilities⇐Rows ⟨source,1⊑rowGroups,1⊑amountGroups⟩,
                  equity⇐Rows ⟨source,2⊑rowGroups,2⊑amountGroups⟩,
                  total_assets⇐assetTotal,total_liabilities⇐liabilityTotal,
                  stated_equity⇐equityTotal,unclosed_result⇐unclosedResult,
                  total_equity⇐totalEquityResult.coefficient,
                  total_liabilities_and_equity⇐rightResult.coefficient,
                  difference⇐differenceResult.coefficient,balanced⇐balanced,
                  unclosed_result_contributors⇐∾3⊑contributorGroups,
                  diagnostics⇐empty
                }
              }⍟balanced @
            }⍟(differenceResult.state≡"ok") @
          }⍟(rightResult.state≡"ok") @
        }⍟(totalEquityResult.state≡"ok") @
      }⍟(unsupportedTotal=0) @
    }⍟sumsOk @
  }⍟(accountBalances.state≡"ok") @
  {𝕊: result↩EmptyResult ⟨domainCode,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
