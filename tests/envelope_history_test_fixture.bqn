# Explicit historical Envelope evidence for accounting tests.
# Tests name stable Envelope identities and routing facts directly; this helper
# never derives history from current budget.toml assignments.

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
    }
  }
}

Managed ← {𝕊 ids‿expenseKeys‿targets:
  Initial ⟨ids,expenseKeys,(≠expenseKeys)⥊⟨"managed"⟩,targets⟩
}

{Initial⇐Initial,Managed⇐Managed}
