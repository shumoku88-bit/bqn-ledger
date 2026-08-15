# Explicit historical Envelope evidence for accounting tests.
# Tests name stable Envelope identities and routing facts directly; this helper
# never derives history from current budget.toml assignments.

dates ← •Import "../src/ledger/date_ordinal.bqn"
empty ← ⟨⟩

EmptyExpense ← {𝕊:{
  count⇐0,index⇐empty,effective_from⇐empty,initial⇐empty,effective_ordinal⇐empty,
  expense_account_key⇐empty,route⇐empty,target_id⇐empty,note⇐empty,source_row⇐empty
}}
EmptyFulfillment ← {𝕊:{
  count⇐0,index⇐empty,effective_from⇐empty,effective_ordinal⇐empty,
  plan_id⇐empty,route⇐empty,target_id⇐empty,note⇐empty,source_row⇐empty
}}
ExpenseOrdinal ← {𝕊 text:
  value ← ¯1
  {𝕊:value↩dates.Ordinal text}⍟(text≢"initial") @
  value
}

Initial ← {𝕊 ids‿expenseKeys‿routes‿targets:
  count ← ≠expenseKeys
  {
    state⇐"ok",present⇐1,source_name⇐"household.toml",
    registry⇐{count⇐≠ids,index⇐↕≠ids,id⇐ids},
    expense_routing⇐{
      count⇐count,index⇐↕count,effective_from⇐count⥊⟨"initial"⟩,
      initial⇐count⥊1,effective_ordinal⇐count⥊¯1,
      expense_account_key⇐expenseKeys,route⇐routes,target_id⇐targets,
      note⇐count⥊⟨"test historical route"⟩,source_row⇐1+↕count
    },
    fulfillment_routing⇐EmptyFulfillment @
  }
}

Managed ← {𝕊 ids‿expenseKeys‿targets:
  Initial ⟨ids,expenseKeys,(≠expenseKeys)⥊⟨"managed"⟩,targets⟩
}

WithExpense ← {𝕊 history‿effectiveTexts‿expenseKeys‿routes‿targets:
  count ← ≠expenseKeys
  {
    state⇐history.state,present⇐history.present,source_name⇐history.source_name,
    registry⇐history.registry,
    expense_routing⇐{
      count⇐count,index⇐↕count,effective_from⇐effectiveTexts,
      initial⇐"initial"⊸≡¨effectiveTexts,effective_ordinal⇐ExpenseOrdinal¨effectiveTexts,
      expense_account_key⇐expenseKeys,route⇐routes,target_id⇐targets,
      note⇐count⥊⟨"test historical route"⟩,source_row⇐1+↕count
    },
    fulfillment_routing⇐history.fulfillment_routing
  }
}

WithFulfillment ← {𝕊 history‿effectiveTexts‿planIds‿routes‿targets:
  count ← ≠planIds
  {
    state⇐history.state,present⇐history.present,source_name⇐history.source_name,
    registry⇐history.registry,expense_routing⇐history.expense_routing,
    fulfillment_routing⇐{
      count⇐count,index⇐↕count,effective_from⇐effectiveTexts,
      effective_ordinal⇐dates.Ordinal¨effectiveTexts,plan_id⇐planIds,
      route⇐routes,target_id⇐targets,
      note⇐count⥊⟨"test historical fulfillment route"⟩,
      source_row⇐101+↕count
    }
  }
}

{Initial⇐Initial,Managed⇐Managed,WithExpense⇐WithExpense,WithFulfillment⇐WithFulfillment}
