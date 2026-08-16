# tests/test_edit_validate.bqn
# Unit tests for live src_edit validation, Issue rendering, and Plan ID logic.

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

# ── Amount validation tests ─────────────────────────────────────
•Out "Running Amount tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "100"
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "-50"
⟨1, ""⟩ t.AssertEq validate.ValidateAmount "0"
t.Assert (0 ≡ ⊑ validate.ValidateAmount "12.34")
t.Assert (0 ≡ ⊑ validate.ValidateAmount "abc")
t.Assert (0 ≡ ⊑ validate.ValidateAmount "")

twoDigitPolicy ← {state⇐"ok",max_fraction_digits⇐2}
unsupportedPolicy ← {state⇐"error",max_fraction_digits⇐0}
⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForPolicy ⟨"ILS",twoDigitPolicy,"12"⟩
⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForPolicy ⟨"ILS",twoDigitPolicy,"12.5"⟩
⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForPolicy ⟨"ILS",twoDigitPolicy,"12.50"⟩
⟨1, ""⟩ t.AssertEq validate.ValidateExactAmountForPolicy ⟨"ILS",twoDigitPolicy,"0.05"⟩
t.Assert (0 ≡ ⊑ validate.ValidateExactAmountForPolicy ⟨"ILS",twoDigitPolicy,"1.234"⟩)
t.Assert (0 ≡ ⊑ validate.ValidateExactAmountForPolicy ⟨"ILS",twoDigitPolicy,"1.000"⟩)
t.Assert (0 ≡ ⊑ validate.ValidateExactAmountForPolicy ⟨"ILS",twoDigitPolicy,"12x"⟩)
t.Assert (0 ≡ ⊑ validate.ValidateExactAmountForPolicy ⟨"EUR",unsupportedPolicy,"12"⟩)

# ── Tab/newline validation tests ────────────────────────────────
•Out "Running Tab/newline tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateNoTabNewline "memo"‿"fine memo"
t.Assert (0 ≡ ⊑ validate.ValidateNoTabNewline "memo"‿("fine" ∾ ⟨@+9⟩ ∾ "memo"))
t.Assert (0 ≡ ⊑ validate.ValidateNoTabNewline "memo"‿("fine" ∾ ⟨@+10⟩ ∾ "memo"))

# ── Metadata validation tests ───────────────────────────────────
•Out "Running Meta token tests..."
⟨1, ""⟩ t.AssertEq validate.ValidateMetaToken "key=value"
⟨1, ""⟩ t.AssertEq validate.ValidateMetaToken "key_name-1=val-2"
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "key")
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "=value")
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "KEY=value")
t.Assert (0 ≡ ⊑ validate.ValidateMetaToken "key =value")
⟨1, ""⟩ t.AssertEq validate.ValidateMeta ⟨"source=test","note=ok"⟩
t.Assert (0 ≡ ⊑ validate.ValidateMeta ⟨"source=test","BAD=value"⟩)
⟨1, ""⟩ t.AssertEq validate.ValidateNoCurrencyMeta ⟨"source=test"⟩
t.Assert (0 ≡ ⊑ validate.ValidateNoCurrencyMeta ⟨"currency=ILS"⟩)

# ── Live Issue render tests ─────────────────────────────────────
•Out "Running Issue render tests..."
tab ← @+9
issue ← {
  issue_id⇐"issue-1",status⇐"open",date⇐"2026-06-29",due⇐"2026-07-01",closed⇐"",
  category⇐"want",title⇐"Book",amount⇐"1200",currency⇐"JPY",details⇐"note"
}
("issue-1"∾tab∾"open"∾tab∾"2026-06-29"∾tab∾"want"∾tab∾"Book"∾tab∾"1200"∾tab∾"JPY"∾tab∾"note") t.AssertEq render.RenderIssueRow issue
("issue-1"∾tab∾"open"∾tab∾"2026-06-29"∾tab∾"2026-07-01"∾tab∾"want"∾tab∾"Book"∾tab∾"1200"∾tab∾"JPY"∾tab∾"note") t.AssertEq render.RenderIssueRowWithDue issue
("issue-1"∾tab∾"open"∾tab∾"2026-06-29"∾tab∾"2026-07-01"∾tab∾""∾tab∾"want"∾tab∾"Book"∾tab∾"1200"∾tab∾"JPY"∾tab∾"note") t.AssertEq render.RenderIssueRowWithClosed issue

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
  date⇐"2026-06-29",memo⇐"Salary",meta⇐⟨⟩,existing_ids⇐existing
}
"plan-2026-06-29-rent-02" t.AssertEq plan_id.GeneratePlanID {
  date⇐"2026-06-29",memo⇐"Rent",meta⇐⟨⟩,existing_ids⇐existing
}
existing2 ← existing ∾ ⟨"plan-2026-06-29-rent-02"⟩
"plan-2026-06-29-rent-03" t.AssertEq plan_id.GeneratePlanID {
  date⇐"2026-06-29",memo⇐"Rent",meta⇐⟨⟩,existing_ids⇐existing2
}
"plan-2026-06-29-my-series" t.AssertEq plan_id.GeneratePlanID {
  date⇐"2026-06-29",memo⇐"Rent payment",meta⇐⟨"series=my-series","anchor=rent"⟩,existing_ids⇐existing
}

•Out "All src_edit unit tests passed!"