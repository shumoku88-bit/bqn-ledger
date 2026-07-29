# Narrow editor config: only fields required to append Plan budget allocations.

io ← •Import "source_io.bqn"
rows ← •Import "config_rows.bqn"
configPath ← •Import "editor_config_path.bqn"
Load ← {𝕊 base:
  table ← rows.Build io.ReadLines configPath.Resolve base
  Required ← {𝕊 key:
    value ← table.Get key
    {𝕊:
      •Out "CONFIG ERROR: missing value for "∾key
      •Exit 1
    }⍟(0=≠value) @
    value
  }
  {
    BudgetPrefix⇐{𝕊:Required "BUDGET_PREFIX"},
    BudgetSpent⇐{𝕊:Required "BUDGET_ID_SPENT"},
    ExecutionPlannedPaymentsEnvelope⇐{𝕊:table.Get "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"}
  }
}

{Load⇐Load}
