# Effectful adapter: admit one concrete human manifest, resolve its volatile daily coordinates,
# and print a complete concrete manifest for the existing report engine.

io ← •Import "source_io.bqn"
sources ← •Import "report_source_adapter.bqn"
route ← •Import "report_route.bqn"
catalog ← •Import "../report/catalog.bqn"
cycleAdmission ← •Import "../ledger/cycle_admission.bqn"
cycleResolution ← •Import "cycle_resolution.bqn"
profile ← •Import "current_report_profile.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩ ⋄ tab ← @+9

Fail ← {𝕊 code‿message: •Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
PrintDiagnostics ← {𝕊 diagnostics:
  {𝕊 diagnostic: •Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
SafeBasename ← {𝕊 value:
  forbidden ← ('/'=value) ∨ ((@+92)=value) ∨ value∊(@+9)‿(@+10)‿(@+13)
  (0<≠value) ∧ ¬∨´forbidden
}
EndsWith ← {𝕊 suffix‿value: suffix≡(-≠suffix)↑value}
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
FindRow ← {𝕊 key‿rows: (⊑(key⊸≡¨{𝕩.key}¨rows)⊐1)⊑rows}
CycleFailure ← {𝕊 resolved‿fallback:
  {𝕊:PrintDiagnostics resolved.diagnostics}⍟(0<≠resolved.diagnostics) @
  code ← fallback ⋄ message ← "Cycle resolution failed"
  {𝕊:code↩resolved.reason ⋄ message↩resolved.reason}⍟((resolved.state≡"unavailable") ∧ 0<≠resolved.reason) @
  Fail ⟨code,message⟩
}

args ← •args
{𝕊:Fail ⟨"usage","expected BASE HUMAN_MANIFEST_BASENAME"⟩}⍟(2≠≠args) @
base‿manifestName ← args
{𝕊:Fail ⟨"manifest_basename_invalid","human manifest must be a safe .tsv basename"⟩}⍟((¬SafeBasename manifestName) ∨ ¬".tsv"≡¯4↑manifestName) @
manifestPath ← Join ⟨base,manifestName⟩
{𝕊:Fail ⟨"manifest_unreadable","human manifest is not readable"⟩}⍟(¬•file.Exists io.ResolvePath manifestPath) @
lines ← io.ReadLines manifestPath
{𝕊:Fail ⟨"manifest_header_invalid","manifest header must be key, surface, arguments"⟩}⍟((0=≠lines) ∨ (⊑lines)≢"key"∾tab∾"surface"∾tab∾"arguments") @
fields ← io.SplitTsv¨1↓lines
{𝕊:Fail ⟨"manifest_row_invalid","every manifest row requires key, surface, and arguments"⟩}⍟(∨´0∾{3>≠𝕩}¨fields) @
rows ← {𝕊 row: {key⇐0⊑row,surface⇐1⊑row,arguments⇐2↓row}}¨fields
expectedKeys ← (catalog.Table @).key
{𝕊:Fail ⟨"manifest_catalog_mismatch","human manifest must contain every catalog key in order"⟩}⍟((≠rows)≠≠expectedKeys) @
{𝕊:Fail ⟨"manifest_catalog_mismatch","human manifest must contain every catalog key in order"⟩}⍟(expectedKeys≢{𝕩.key}¨rows) @
{𝕊:Fail ⟨"manifest_surface_mismatch","current profile requires human rows"⟩}⍟(∨´0∾{"human"≢𝕩.surface}¨rows) @

admissions ← {route.Admit ⟨𝕩.key,𝕩.surface,𝕩.arguments⟩}¨rows
routeDiagnostics ← ∾{𝕩.diagnostics}¨admissions
{𝕊:PrintDiagnostics routeDiagnostics}⍟(0<≠routeDiagnostics) @
sourceRoles ← ∾{𝕩.sources.role}¨admissions
sourceNames ← ∾{𝕩.sources.name}¨admissions
actualNames ← ("actual"⊸≡¨sourceRoles)/sourceNames
actualUnique ← ⍷actualNames
{𝕊:Fail ⟨"current_actual_source_mismatch","current profile requires one shared Actual source"⟩}⍟(1≠≠actualUnique) @
actualName ← ⊑actualUnique
{𝕊:Fail ⟨"source_basename_invalid","current profile Actual source must be a safe .journal basename"⟩}⍟(¬((SafeBasename actualName) ∧ EndsWith ⟨".journal",actualName⟩)) @

registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:Fail ⟨registryResult.code,registryResult.message⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
actual ← sources.Actual ⟨base,actualName,registry⟩
{𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
{𝕊:Fail ⟨"current_observation_missing","current profile requires at least one admitted Actual transaction"⟩}⍟(0=actual.facts.transactions.count) @
latestOrdinal ← ⌈´actual.facts.transactions.date_ordinal
latestIndex ← ⊑(latestOrdinal=actual.facts.transactions.date_ordinal)⊐1
observation ← latestIndex⊑actual.facts.transactions.date_text

profileSources ← profile.SourceNames admissions
currentCycleName ← profileSources.current_cycle
comparisonCurrentName ← profileSources.comparison_current_cycle
baselineCycleName ← profileSources.baseline_cycle
planName ← profileSources.plan
comparisonRoute ← FindRow ⟨"cycle-comparison",admissions⟩
{𝕊:Fail ⟨"current_cycle_source_mismatch","Cycle Accounts and Cycle Comparison must share the current Cycle source"⟩}⍟(currentCycleName≢comparisonCurrentName) @
{𝕊:Fail ⟨"current_comparison_policy_unsupported","current profile requires aligned_elapsed Cycle Comparison"⟩}⍟((3⊑comparisonRoute.coordinates)≢"aligned_elapsed") @
sourceNamesOk ← (SafeBasename currentCycleName) ∧ (SafeBasename baselineCycleName) ∧ SafeBasename planName
sourceSuffixesOk ← (EndsWith ⟨".tsv",currentCycleName⟩) ∧ (EndsWith ⟨".tsv",baselineCycleName⟩) ∧ EndsWith ⟨".tsv",planName⟩
{𝕊:Fail ⟨"source_basename_invalid","Cycle and Plan sources must be safe .tsv basenames"⟩}⍟(¬(sourceNamesOk ∧ sourceSuffixesOk)) @
plan ← sources.Plan ⟨base,planName,actual.facts.accounts,registry⟩
{𝕊:PrintDiagnostics plan.diagnostics}⍟(plan.state≢"ok") @
currentAdmission ← cycleAdmission.Admit ⟨sources.CycleLines ⟨base,currentCycleName⟩,actual.facts.accounts⟩
{𝕊:PrintDiagnostics currentAdmission.diagnostics}⍟(currentAdmission.state≢"ok") @
currentCycle ← cycleResolution.WithPlan ⟨currentAdmission,observation,actual.facts,plan.facts⟩
{𝕊:CycleFailure ⟨currentCycle,"current_cycle_resolution_failed"⟩}⍟(currentCycle.state≢"ok") @
previousObservation ← dates.FromOrdinal currentCycle.start_ordinal-1
baselineAdmission ← cycleAdmission.Admit ⟨sources.CycleLines ⟨base,baselineCycleName⟩,actual.facts.accounts⟩
{𝕊:PrintDiagnostics baselineAdmission.diagnostics}⍟(baselineAdmission.state≢"ok") @
baselineCycle ← cycleResolution.WithPlan ⟨baselineAdmission,previousObservation,actual.facts,plan.facts⟩
{𝕊:CycleFailure ⟨baselineCycle,"baseline_cycle_resolution_failed"⟩}⍟(baselineCycle.state≢"ok") @

resolved ← profile.Build ⟨admissions,observation,currentCycle,baselineCycle⟩
{𝕊:PrintDiagnostics resolved.diagnostics}⍟(resolved.state≢"ok") @
•Out "key"∾tab∾"surface"∾tab∾"arguments"
{𝕊 row: •Out row.key∾tab∾row.surface∾(∾{tab∾𝕩}¨row.arguments)}¨resolved.rows
