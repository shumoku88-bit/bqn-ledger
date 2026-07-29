# Parallel destination CLI proof. Production tools/report remains unchanged.

request ← •Import "../report/request.bqn"
compose ← •Import "../report/compose.bqn"
render ← •Import "../report/render.bqn"
sources ← •Import "report_source_adapter.bqn"
empty ← ⟨⟩ ⋄ tab ← @+9
args ← •args
Fail ← {𝕊 code‿message: •Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
IsDigits ← {𝕊 text: (0<≠text) ∧ ∧´text∊"0123456789"}
ToNatural ← {𝕊 text:
  digits ← "0123456789"⊐text
  +´digits×10⋆⌽↕≠digits
}
PrintDiagnostics ← {𝕊 diagnostics:
  {𝕊 diagnostic: •Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}

{𝕊:Fail ⟨"usage","expected BASE KEY SURFACE and key-specific coordinates"⟩}⍟(3>≠args) @
base‿key‿surface ← 3↑args ⋄ coordinates ← 3↓args
admitted ← request.Validate ⟨key,surface⟩
{𝕊:PrintDiagnostics admitted.diagnostics}⍟(admitted.state≢"ok") @
{𝕊:Fail ⟨"all_not_implemented","parallel CLI currently requires one retained key"⟩}⍟(key≡"all") @

registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:PrintDiagnostics registryResult.diagnostics}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
composition ← {state⇐"error",key⇐key,result⇐empty,diagnostics⇐empty}

{𝕊:
  {𝕊:Fail ⟨"usage_balances","balances requires DOMAIN AS_OF JOURNAL_BASENAME"⟩}⍟(3≠≠coordinates) @
  domain‿observation‿journal ← coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  composition↩compose.Balances ⟨actual.facts,domain,observation⟩
}⍟(key≡"balances") @
{𝕊:
  {𝕊:Fail ⟨"usage_recent","recent requires LIMIT JOURNAL_BASENAME"⟩}⍟(2≠≠coordinates) @
  limitText‿journal ← coordinates
  {𝕊:Fail ⟨"limit_invalid","LIMIT must be decimal digits"⟩}⍟(¬IsDigits limitText) @
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  composition↩compose.Recent ⟨actual.facts,ToNatural limitText⟩
}⍟(key≡"recent") @
{𝕊:
  {𝕊:Fail ⟨"usage_monthly_accounts","monthly-accounts requires DOMAIN FIRST_MONTH LAST_MONTH_EXCLUSIVE JOURNAL_BASENAME"⟩}⍟(4≠≠coordinates) @
  domain‿firstMonth‿lastMonth‿journal ← coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  composition↩compose.MonthlyAccounts ⟨actual.facts,domain,firstMonth,lastMonth⟩
}⍟(key≡"monthly-accounts") @
{𝕊:
  {𝕊:Fail ⟨"usage_issues","issues requires ISSUE_BASENAME"⟩}⍟(1≠≠coordinates) @
  composition↩compose.Issues ⟨sources.IssueLines ⟨base,⊑coordinates⟩,registry⟩
}⍟(key≡"issues") @

implemented ← ∨´key⊸≡¨⟨"balances","recent","monthly-accounts","issues"⟩
{𝕊:Fail ⟨"composition_not_implemented","retained key is not yet wired to the parallel source adapter"⟩}⍟(¬implemented) @
{𝕊:PrintDiagnostics composition.diagnostics}⍟(composition.state≢"ok") @
rendered ← render.Render ⟨key,surface,composition⟩
{𝕊:PrintDiagnostics rendered.diagnostics}⍟(rendered.state≢"ok") @
text ← rendered.text
{𝕊:text↩¯1↓text}⍟((0<≠text) ∧ (@+10)=¯1↑text) @
•Out text
