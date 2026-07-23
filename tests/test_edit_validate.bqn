# tests/test_edit_validate.bqn
# Unit tests for src_edit/validate.bqn and src_edit/plan_id.bqn

t ← •Import "test_lib.bqn"
validate ← •Import "../src_edit/validate.bqn"
plan_id ← •Import "../src_edit/plan_id.bqn"
render ← •Import "../src_edit/render.bqn"

# ── Date validation tests ───────────────────────────────────────
•Out "Running Date tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateDate "2026-06-29"
⟨1, ""⟩ t.AssertEq validate.ValidateDate "2024-02-29"
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026-02-29")
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026-06-31")
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026-13-01")
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026-06-00")
t.Assert (0 ≡ ⊑ validate.ValidateDate "invalid-date")
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026/06/29")

# ── Amount and currency validation tests ────────────────────────
•Out "Running Amount and currency tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "100"
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "-50"
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "0"
t.Assert (0 ≡ ⊑ validate.ValidateAmount "12.34")
t.Assert (0 ≡ ⊑ validate.ValidateAmount "abc")
t.Assert (0 ≡ ⊑ validate.ValidateAmount "")

⟨1, ""⟩ t.AssertEq validate.ValidateCurrency "JPY"
⟨1, ""⟩ t.AssertEq validate.ValidateCurrency "ILS"
t.Assert (0 ≡ ⊑ validate.ValidateCurrency "EUR")
t.Assert (0 ≡ ⊑ validate.ValidateCurrency "")

⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForCurrency "JPY"‿"12.34"
⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForCurrency "ILS"‿"12"
⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForCurrency "ILS"‿"12.5"
⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForCurrency "ILS"‿"12.50"
⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForCurrency "ILS"‿"0.05"
t.Assert (0 ≡ ⊑ validate.ValidateExactAmountForCurrency "ILS"‿"1.234")
t.Assert (0 ≡ ⊑ validate.ValidateExactAmountForCurrency "ILS"‿"1.000")
t.Assert (0 ≡ ⊑ validate.ValidateExactAmountForCurrency "ILS"‿"12x")

# ── Tab/newline validation tests ────────────────────────────────
•Out "Running Tab/newline tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateNoTabNewline "memo"‿"fine memo"
t.Assert (0 ≡ ⊑ validate.ValidateNoTabNewline "memo"‿("fine" ∾ ⟨@+9⟩ ∾ "memo"))
t.Assert (0 ≡ ⊑ validate.ValidateNoTabNewline "memo"‿("fine" ∾ ⟨@+10⟩ ∾ "memo"))

# ── Account validation tests ────────────────────────────────────
•Out "Running Account tests..."
accts ← ⟨"assets:bank", "expenses:rent", "income:salary", "assets:cash-ils", "expenses:food-ils"⟩
acctCurrencies ← ⟨"JPY", "JPY", "JPY", "ILS", "ILS"⟩
⟨1, ""⟩ t.AssertEq validate.ValidateAccount "from"‿"assets:bank"‿accts
t.Assert (0 ≡ ⊑ validate.ValidateAccount "from"‿"expenses:food"‿accts)
t.Assert (0 ≡ ⊑ validate.ValidateAccount "from"‿""‿accts)
⟨1, ""⟩ t.AssertEq validate.ValidateAccountCurrency "from"‿"assets:bank"‿"JPY"‿accts‿acctCurrencies
⟨1, ""⟩ t.AssertEq validate.ValidateAccountCurrency "to"‿"expenses:food-ils"‿"ILS"‿accts‿acctCurrencies
t.Assert (0 ≡ ⊑ validate.ValidateAccountCurrency "from"‿"assets:bank"‿"ILS"‿accts‿acctCurrencies)

# Account-add contract: explicit role/currency, matching namespace, uniqueness,
# and controlled asset type.
⟨1, ""⟩ t.AssertEq validate.ValidateAccountAdd {
  name ⇐ "income:友人精算" ⋄ role ⇐ "income" ⋄ type ⇐ "" ⋄ currency ⇐ "JPY" ⋄ accounts ⇐ accts
}
⟨1, ""⟩ t.AssertEq validate.ValidateAccountAdd {
  name ⇐ "assets:PayPay" ⋄ role ⇐ "asset" ⋄ type ⇐ "liquid" ⋄ currency ⇐ "JPY" ⋄ accounts ⇐ accts
}
⟨1, ""⟩ t.AssertEq validate.ValidateAccountAdd {
  name ⇐ "assets:wallet-ils" ⋄ role ⇐ "asset" ⋄ type ⇐ "liquid" ⋄ currency ⇐ "ILS" ⋄ accounts ⇐ accts
}
t.Assert (0 ≡ ⊑ validate.ValidateAccountAdd { name ⇐ "income:salary" ⋄ role ⇐ "income" ⋄ type ⇐ "" ⋄ currency ⇐ "JPY" ⋄ accounts ⇐ accts })
t.Assert (0 ≡ ⊑ validate.ValidateAccountAdd { name ⇐ "expenses:food" ⋄ role ⇐ "income" ⋄ type ⇐ "" ⋄ currency ⇐ "JPY" ⋄ accounts ⇐ accts })
t.Assert (0 ≡ ⊑ validate.ValidateAccountAdd { name ⇐ "assets:bank2" ⋄ role ⇐ "asset" ⋄ type ⇐ "crypto" ⋄ currency ⇐ "JPY" ⋄ accounts ⇐ accts })
t.Assert (0 ≡ ⊑ validate.ValidateAccountAdd { name ⇐ "income:" ⋄ role ⇐ "income" ⋄ type ⇐ "" ⋄ currency ⇐ "JPY" ⋄ accounts ⇐ accts })
t.Assert (0 ≡ ⊑ validate.ValidateAccountAdd { name ⇐ "assets:usd" ⋄ role ⇐ "asset" ⋄ type ⇐ "liquid" ⋄ currency ⇐ "EUR" ⋄ accounts ⇐ accts })

# ── Meta token validation tests ─────────────────────────────────
•Out "Running Meta token tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateMetaToken "key=value"
⟨1, ""⟩ t.AssertEq validate.ValidateMetaToken "key_name-1=val-2"
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "key")
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "=value")
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "KEY=value")
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "key =value")
⟨1, ""⟩ t.AssertEq validate.ValidateNoCurrencyMeta ⟨"source=test"⟩
t.Assert (0 ≡ ⊑ validate.ValidateNoCurrencyMeta ⟨"currency=ILS"⟩)

# ── Render tests ────────────────────────────────────────────────
•Out "Running Render tests..."
tab ← @+9
("income:友人精算" ∾ tab ∾ "role=income" ∾ tab ∾ "currency=JPY") t.AssertEq render.RenderAccountRow {
  name ⇐ "income:友人精算" ⋄ role ⇐ "income" ⋄ type ⇐ "" ⋄ currency ⇐ "JPY"
}
("assets:PayPay" ∾ tab ∾ "role=asset" ∾ tab ∾ "type=liquid" ∾ tab ∾ "currency=JPY") t.AssertEq render.RenderAccountRow {
  name ⇐ "assets:PayPay" ⋄ role ⇐ "asset" ⋄ type ⇐ "liquid" ⋄ currency ⇐ "JPY"
}
("assets:wallet-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "type=liquid" ∾ tab ∾ "currency=ILS") t.AssertEq render.RenderAccountRow {
  name ⇐ "assets:wallet-ils" ⋄ role ⇐ "asset" ⋄ type ⇐ "liquid" ⋄ currency ⇐ "ILS"
}
("2026-06-29" ∾ tab ∾ "memo" ∾ tab ∾ "assets:bank" ∾ tab ∾ "expenses:rent" ∾ tab ∾ "100") t.AssertEq render.RenderJournalRow {
  date ⇐ "2026-06-29" ⋄ memo ⇐ "memo" ⋄ from ⇐ "assets:bank" ⋄ to ⇐ "expenses:rent" ⋄ amount ⇐ "100" ⋄ meta ⇐ ⟨⟩
}
("2026-06-29" ∾ tab ∾ "memo" ∾ tab ∾ "assets:cash-ils" ∾ tab ∾ "expenses:food-ils" ∾ tab ∾ "12.50" ∾ tab ∾ "source=test" ∾ tab ∾ "currency=ILS") t.AssertEq render.RenderJournalRow {
  date ⇐ "2026-06-29" ⋄ memo ⇐ "memo" ⋄ from ⇐ "assets:cash-ils" ⋄ to ⇐ "expenses:food-ils" ⋄ amount ⇐ "12.50" ⋄ meta ⇐ ⟨"source=test", "currency=ILS"⟩
}

# ── Slugify tests ───────────────────────────────────────────────
•Out "Running Slugify tests..."
"hello-world-123" t.AssertEq plan_id.Slugify "Hello! World 123"
"plan" t.AssertEq plan_id.Slugify "!!!"
"plan" t.AssertEq plan_id.Slugify ""
"my-series" t.AssertEq plan_id.Slugify "  my-series  "

# ── ValidatePlanIDFormat tests ──────────────────────────────────
•Out "Running ValidatePlanIDFormat tests..."
⟨1, ""⟩ t.AssertEq plan_id.ValidatePlanIDFormat "plan-2026-06-29-rent"
⟨1, ""⟩ t.AssertEq plan_id.ValidatePlanIDFormat "plan-2026-06-29-phone-bill"
t.Assert (0 ≡ ⊑ plan_id.ValidatePlanIDFormat "plan-2026-02-29-rent")
t.Assert (0 ≡ ⊑ plan_id.ValidatePlanIDFormat "plan-2026-06-29-")
t.Assert (0 ≡ ⊑ plan_id.ValidatePlanIDFormat "2026-06-29-rent")

# ── GeneratePlanID tests ────────────────────────────────────────
•Out "Running GeneratePlanID tests..."
existing ← ⟨"plan-2026-06-29-rent", "plan-2026-06-29-phone-bill"⟩
"plan-2026-06-29-salary" t.AssertEq plan_id.GeneratePlanID {
  date ⇐ "2026-06-29" ⋄ memo ⇐ "Salary" ⋄ meta ⇐ ⟨⟩ ⋄ existing_ids ⇐ existing
}
"plan-2026-06-29-rent-02" t.AssertEq plan_id.GeneratePlanID {
  date ⇐ "2026-06-29" ⋄ memo ⇐ "Rent" ⋄ meta ⇐ ⟨⟩ ⋄ existing_ids ⇐ existing
}
existing2 ← existing ∾ ⟨"plan-2026-06-29-rent-02"⟩
"plan-2026-06-29-rent-03" t.AssertEq plan_id.GeneratePlanID {
  date ⇐ "2026-06-29" ⋄ memo ⇐ "Rent" ⋄ meta ⇐ ⟨⟩ ⋄ existing_ids ⇐ existing2
}
"plan-2026-06-29-my-series" t.AssertEq plan_id.GeneratePlanID {
  date ⇐ "2026-06-29" ⋄ memo ⇐ "Rent payment" ⋄ meta ⇐ ⟨"series=my-series", "anchor=rent"⟩ ⋄ existing_ids ⇐ existing
}

•Out "Running transaction ID tests..."

•Out "All src_edit unit tests passed!"
