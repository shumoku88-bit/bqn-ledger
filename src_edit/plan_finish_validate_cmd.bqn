# Validate one published canonical Plan completion link.

planSource ← •Import "../src/application/plan_source_adapter.bqn"
actualSource ← •Import "../src/application/editor_actual.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @
args ← •args
tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
{𝕊:Fail "usage: plan_finish_validate_cmd.bqn <baseDir> <planId> <actualDate>"}⍟(3≠≠args) @
base ← 0⊑args
planID ← 1⊑args
actualDate ← 2⊑args

planResult ← planSource.Load ⟨base,setup.registry⟩
{𝕊:Fail "canonical plan.journal rejected"}⍟(planResult.state≢"ok") @
planMatches ← planID⊸≡¨planResult.facts.transactions.plan_id
{𝕊:Fail ("Plan identity must resolve exactly once: "∾planID)}⍟(1≠+´planMatches) @

evidence ← actualSource.CompletionEvidence base
matches ← (planID⊸≡¨{𝕩.plan_id}¨evidence)/evidence
{𝕊:Fail ("completion evidence must resolve exactly once: "∾planID)}⍟(1≠≠matches) @
completion ← ⊑matches
{𝕊:Fail ("completion date mismatch for Plan: "∾planID)}⍟(completion.date≢actualDate) @
•Out "OK"∾tab∾"PLAN_COMPLETION"∾tab∾planID∾tab∾actualDate