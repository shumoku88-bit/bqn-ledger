# account_key.bqn
# AccountKey resolution for the cycle-ledger prototype.
#
# Contract (DATA_CONTRACT.md, AXIS_CONTRACT.md):
#   - AccountKey = (Account, Currency)
#   - Currency defaults to "JPY" when not specified
#   - Different currencies must not share the same numeric balance
#   - AccountKey axis is derived from resolved account keys
#
# Contract (CYCLE_LEDGER_DECISIONS.md):
#   - Currency-separated balances via AccountKey, not a separate Currency axis
#   - Currency conversion out of scope

# Extract a key=value field from account metadata tokens.
# Used for read-only account metadata resolution in src_next.
MetaValue ← {𝕊 key‿def‿toks:
  pref ← key ∾ "="
  plen ← ≠ pref
  ok_len ← { plen ≤ ≠ 𝕩 } ¨ toks
  is_match ← ok_len × { pref ≡ plen ↑ 𝕩 } ¨ toks
  hits ← is_match / toks
  vals ← (plen ↓¨ hits) ∾ ⟨def⟩
  (0 < ≠ hits) ⊑ ⟨def, ⊑ vals⟩
}

# Explicit account metadata resolvers.
# Empty string means unspecified; callers may still apply documented fallback
# only where a fallback is explicitly part of the src_next contract.
RoleFromMeta ← { MetaValue ⟨"role", "", 𝕩⟩ }
CurrencyFromMeta ← { MetaValue ⟨"currency", "JPY", 𝕩⟩ }
TypeFromMeta ← { MetaValue ⟨"type", "", 𝕩⟩ }
BudgetFromMeta ← { MetaValue ⟨"budget", "", 𝕩⟩ }
BudgetGroupFromMeta ← { MetaValue ⟨"budget_group", "", 𝕩⟩ }
KindFromMeta ← { MetaValue ⟨"kind", "", 𝕩⟩ }
SpendClassFromMeta ← { MetaValue ⟨"spend_class", "", 𝕩⟩ }

# Resolve: build AccountKey table from accounts.tsv lines.
# Args: 𝕩 is 1D Array of Strings (parsed lines from accounts.tsv, each TAB-separated)
# Returns Namespace:
#   - table: 2D Array [n × 4] of Strings:
#       [index_str, account, currency, account_key]
#   - account_keys: 1D Array of Strings (the resolved AccountKey values)
#   - roles / budgets / budget_groups / spend_classes / types: parallel metadata arrays;
#     missing metadata is represented as empty string
#   - count: Scalar Number
Resolve ← {
  lines ← 𝕩

  # Split by TAB
  Split ← { sep ← 𝕨 ⋄ mask ← sep = 𝕩 ⋄ groups ← (+` mask) ⊔ 𝕩 ⋄ parts ← { (sep ≠ 𝕩) / 𝕩 } ¨ groups ⋄ (0 < ≠¨ parts) / parts }
  rows ← { (@+9) Split 𝕩 } ¨ lines

  # Account name is the first field
  accounts ← { ⊑ 𝕩 } ¨ rows

  # Metadata: fields after the first
  metas ← { 1 ↓ 𝕩 } ¨ rows

  currencies ← CurrencyFromMeta ¨ metas
  roles ← RoleFromMeta ¨ metas
  types ← TypeFromMeta ¨ metas
  budgets ← BudgetFromMeta ¨ metas
  budget_groups ← BudgetGroupFromMeta ¨ metas
  spend_classes ← SpendClassFromMeta ¨ metas
  kinds ← KindFromMeta ¨ metas

  # Build AccountKey: "account/currency"
  n ← ≠ accounts
  keys ← { (𝕩⊑accounts) ∾ "/" ∾ (𝕩⊑currencies) } ¨ ↕ n

  idxStrs ← •Fmt ¨ ↕ n

  # Build table: n rows × 4 columns
  table ← { ⟨ (𝕩⊑idxStrs), (𝕩⊑accounts), (𝕩⊑currencies), (𝕩⊑keys) ⟩ } ¨ ↕ n

  {
    table ⇐ table,
    accounts ⇐ accounts,
    currencies ⇐ currencies,
    roles ⇐ roles,
    types ⇐ types,
    budgets ⇐ budgets,
    budget_groups ⇐ budget_groups,
    spend_classes ⇐ spend_classes,
    kinds ⇐ kinds,
    raw_accounts ⇐ accounts,
    raw_metadata ⇐ metas,
    account_keys ⇐ keys,
    count ⇐ n
  }
}

# FormatTable: format AccountKey table as tab-separated text.
# Args: 𝕩 is a Namespace with field `table` (2D Array of Strings, n × 4)
# Returns: String (TSV text with newlines)
FormatTable ← {
  t ← 𝕩.table
  header ← "account_key_index"‿"account"‿"currency"‿"account_key"

  # Join fields with TAB, rows with newline
  FmtRow ← { ∾ (𝕩 ∾¨ (@+9)) }

  hdr_line ← FmtRow header
  data_lines ← FmtRow ¨ t

  hdr_line ∾ (@+10) ∾ ∾ (data_lines ∾¨ (@+10))
}

{ MetaValue ⇐ MetaValue,
  RoleFromMeta ⇐ RoleFromMeta,
  CurrencyFromMeta ⇐ CurrencyFromMeta,
  BudgetFromMeta ⇐ BudgetFromMeta,
  BudgetGroupFromMeta ⇐ BudgetGroupFromMeta,
  KindFromMeta ⇐ KindFromMeta,
  SpendClassFromMeta ⇐ SpendClassFromMeta,
  Resolve ⇐ Resolve,
  FormatTable ⇐ FormatTable
}
