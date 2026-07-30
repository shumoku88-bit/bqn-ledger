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
    assetIndices ← ("asset"⊸≡¨source.role)/source.index
    liabilityIndices ← ("liability"⊸≡¨source.role)/source.index
    equityIndices ← ("equity"⊸≡¨source.role)/source.index
    resultIndices ← (("income"⊸≡¨source.role) ∨ "expense"⊸≡¨source.role)/source.index
    statementRole ← ("asset"⊸≡¨source.role) ∨ ("liability"⊸≡¨source.role) ∨ ("equity"⊸≡¨source.role) ∨ ("income"⊸≡¨source.role) ∨ "expense"⊸≡¨source.role
    unsupportedIndices ← (¬statementRole)/source.index

    assetAmounts ← assetIndices⊏source.closing
    liabilityAmounts ← -(liabilityIndices⊏source.closing)
    equityAmounts ← -(equityIndices⊏source.closing)
    unclosedSigned ← scale.Sum resultIndices⊏source.closing
    unsupportedTotal ← scale.Sum unsupportedIndices⊏source.closing
    assetTotal ← scale.Sum assetAmounts
    liabilityTotal ← scale.Sum liabilityAmounts
    equityTotal ← scale.Sum equityAmounts
    sums ← ⟨unclosedSigned,unsupportedTotal,assetTotal,liabilityTotal,equityTotal⟩
    sumsOk ← ∧´{𝕩.state≡"ok"}¨sums
    diagnostics ∾↩ AddIf ⟨¬sumsOk,Diagnostic ⟨"balance_sheet_sum_failed","Balance Sheet totals exceed exact range"⟩⟩
    {𝕊:
      diagnostics ∾↩ AddIf ⟨unsupportedTotal.coefficient≠0,Diagnostic ⟨"unsupported_role_balance","non-statement Account roles must have zero Actual balance"⟩⟩
      {𝕊:
        unclosedResult ← -unclosedSigned.coefficient
        totalEquityResult ← scale.Sum ⟨equityTotal.coefficient,unclosedResult⟩
        diagnostics ∾↩ AddIf ⟨totalEquityResult.state≢"ok",Diagnostic ⟨"balance_sheet_sum_failed","total Equity exceeds exact range"⟩⟩
        {𝕊:
          rightResult ← scale.Sum ⟨liabilityTotal.coefficient,totalEquityResult.coefficient⟩
          diagnostics ∾↩ AddIf ⟨rightResult.state≢"ok",Diagnostic ⟨"balance_sheet_sum_failed","Liabilities plus Equity exceeds exact range"⟩⟩
          {𝕊:
            differenceResult ← scale.Sum ⟨assetTotal.coefficient,-rightResult.coefficient⟩
            diagnostics ∾↩ AddIf ⟨differenceResult.state≢"ok",Diagnostic ⟨"balance_sheet_sum_failed","Balance Sheet difference exceeds exact range"⟩⟩
            {𝕊:
              balanced ← accountBalances.balanced ∧ differenceResult.coefficient=0
              diagnostics ∾↩ AddIf ⟨¬balanced,Diagnostic ⟨"balance_sheet_not_balanced","Assets must equal Liabilities plus Equity and unclosed result"⟩⟩
              {𝕊:
                result↩{
                  state⇐"ok",domain⇐domainCode,observation_ordinal⇐observationOrdinal,scale⇐accountBalances.scale,
                  assets⇐Rows ⟨source,assetIndices,assetAmounts⟩,
                  liabilities⇐Rows ⟨source,liabilityIndices,liabilityAmounts⟩,
                  equity⇐Rows ⟨source,equityIndices,equityAmounts⟩,
                  total_assets⇐assetTotal.coefficient,total_liabilities⇐liabilityTotal.coefficient,
                  stated_equity⇐equityTotal.coefficient,unclosed_result⇐unclosedResult,
                  total_equity⇐totalEquityResult.coefficient,
                  total_liabilities_and_equity⇐rightResult.coefficient,
                  difference⇐differenceResult.coefficient,balanced⇐balanced,
                  unclosed_result_contributors⇐∾resultIndices⊏source.contributors,
                  diagnostics⇐empty
                }
              }⍟balanced @
            }⍟(differenceResult.state≡"ok") @
          }⍟(rightResult.state≡"ok") @
        }⍟(totalEquityResult.state≡"ok") @
      }⍟(unsupportedTotal.coefficient=0) @
    }⍟sumsOk @
  }⍟(accountBalances.state≡"ok") @
  {𝕊: result↩EmptyResult ⟨domainCode,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
