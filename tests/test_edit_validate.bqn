# tests/test_edit_validate.bqn
# Unit tests for src_edit/validate.bqn and src_edit/plan_id.bqn

t ← •Import "test_lib.bqn"
validate ← •Import "../src_edit/validate.bqn"
plan_id ← •Import "../src_edit/plan_id.bqn"
render ← •Import "../src_edit/render.bqn"

# ── Date validation tests ───────────────────────────────────────
•Out "Running Date tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateDate "2026-06-29"
⟨1, ""⟩ t.AssertEq validate.ValidateDate "2024-02-29"  # leap year
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026-02-29")  # non-leap year invalid Feb 29
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026-06-31")  # June has 30 days
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026-13-01")  # month 13
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026-06-00")  # day 00
t.Assert (0 ≡ ⊑ validate.ValidateDate "invalid-date")
t.Assert (0 ≡ ⊑ validate.ValidateDate "2026/06/29")

# ── Amount validation tests ─────────────────────────────────────
•Out "Running Amount tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "100"
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "-50"
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "0"
t.Assert (0 ≡ ⊑ validate.ValidateAmount "12.34")
t.Assert (0 ≡ ⊑ validate.ValidateAmount "abc")
t.Assert (0 ≡ ⊑ validate.ValidateAmount "")

# ── Tab/newline validation tests ────────────────────────────────
•Out "Running Tab/newline tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateNoTabNewline "memo"‿"fine memo"
t.Assert (0 ≡ ⊑ validate.ValidateNoTabNewline "memo"‿("fine" ∾ ⟨@+9⟩ ∾ "memo")) # Tab
t.Assert (0 ≡ ⊑ validate.ValidateNoTabNewline "memo"‿("fine" ∾ ⟨@+10⟩ ∾ "memo")) # LF

# ── Account validation tests ────────────────────────────────────
•Out "Running Account tests..."
accts ← ⟨"assets:bank", "expenses:rent", "income:salary"⟩
⟨1, ""⟩ t.AssertEq validate.ValidateAccount "from"‿"assets:bank"‿accts
t.Assert (0 ≡ ⊑ validate.ValidateAccount "from"‿"expenses:food"‿accts)
t.Assert (0 ≡ ⊑ validate.ValidateAccount "from"‿""‿accts)

# ── Meta token validation tests ──────────────────────────────────
•Out "Running Meta token tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateMetaToken "key=value"
⟨1, ""⟩ t.AssertEq validate.ValidateMetaToken "key_name-1=val-2"
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "key") # missing =
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "=value") # empty key
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "KEY=value") # uppercase key
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "key =value") # space in key

# ── Render tests ─────────────────────────────────────────────────
•Out "Running Render tests..."
tab ← @+9
("2026-06-29" ∾ tab ∾ "memo" ∾ tab ∾ "assets:bank" ∾ tab ∾ "expenses:rent" ∾ tab ∾ "100") t.AssertEq render.RenderJournalRow {
  date ⇐ "2026-06-29" ⋄
  memo ⇐ "memo" ⋄
  from ⇐ "assets:bank" ⋄
  to ⇐ "expenses:rent" ⋄
  amount ⇐ "100" ⋄
  meta ⇐ ⟨⟩
}
("2026-06-29" ∾ tab ∾ "memo" ∾ tab ∾ "assets:bank" ∾ tab ∾ "expenses:rent" ∾ tab ∾ "100" ∾ tab ∾ "source=test") t.AssertEq render.RenderJournalRow {
  date ⇐ "2026-06-29" ⋄
  memo ⇐ "memo" ⋄
  from ⇐ "assets:bank" ⋄
  to ⇐ "expenses:rent" ⋄
  amount ⇐ "100" ⋄
  meta ⇐ ⟨"source=test"⟩
}

# ── Slugify tests ────────────────────────────────────────────────
•Out "Running Slugify tests..."
"hello-world-123" t.AssertEq plan_id.Slugify "Hello! World 123"
"plan" t.AssertEq plan_id.Slugify "!!!"
"plan" t.AssertEq plan_id.Slugify ""
"my-series" t.AssertEq plan_id.Slugify "  my-series  "

# ── ValidatePlanIDFormat tests ──────────────────────────────────
•Out "Running ValidatePlanIDFormat tests..."
⟨1, ""⟩ t.AssertEq plan_id.ValidatePlanIDFormat "plan-2026-06-29-rent"
⟨1, ""⟩ t.AssertEq plan_id.ValidatePlanIDFormat "plan-2026-06-29-phone-bill"
t.Assert (0 ≡ ⊑ plan_id.ValidatePlanIDFormat "plan-2026-02-29-rent") # invalid date
t.Assert (0 ≡ ⊑ plan_id.ValidatePlanIDFormat "plan-2026-06-29-") # empty series
t.Assert (0 ≡ ⊑ plan_id.ValidatePlanIDFormat "2026-06-29-rent") # missing prefix

# ── GeneratePlanID tests ────────────────────────────────────────
•Out "Running GeneratePlanID tests..."
existing ← ⟨"plan-2026-06-29-rent", "plan-2026-06-29-phone-bill"⟩

# Generate unique base
"plan-2026-06-29-salary" t.AssertEq plan_id.GeneratePlanID {
  date ⇐ "2026-06-29" ⋄
  memo ⇐ "Salary" ⋄
  meta ⇐ ⟨⟩ ⋄
  existing_ids ⇐ existing
}

# Generate collision suffix -02
"plan-2026-06-29-rent-02" t.AssertEq plan_id.GeneratePlanID {
  date ⇐ "2026-06-29" ⋄
  memo ⇐ "Rent" ⋄
  meta ⇐ ⟨⟩ ⋄
  existing_ids ⇐ existing
}

# Generate collision suffix -03 if -02 also exists
existing2 ← existing ∾ ⟨"plan-2026-06-29-rent-02"⟩
"plan-2026-06-29-rent-03" t.AssertEq plan_id.GeneratePlanID {
  date ⇐ "2026-06-29" ⋄
  memo ⇐ "Rent" ⋄
  meta ⇐ ⟨⟩ ⋄
  existing_ids ⇐ existing2
}

# Prefer series in meta over memo
"plan-2026-06-29-my-series" t.AssertEq plan_id.GeneratePlanID {
  date ⇐ "2026-06-29" ⋄
  memo 	⇐ "Rent payment" ⋄
  meta ⇐ ⟨"series=my-series", "anchor=rent"⟩ ⋄
  existing_ids ⇐ existing
}

•Out "All src_edit unit tests passed!"
