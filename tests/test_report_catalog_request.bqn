#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
catalog ← •Import "../src/report/catalog.bqn"
request ← •Import "../src/report/request.bqn"
catalogText ← •Import "../src/report/catalog_text.bqn"
metadata ← •Import "../src/report/section_metadata.bqn"

table ← catalog.Table @
9 lib.AssertEq table.count
⟨"envelopes","balances","recent","planned","cycle-accounts","cycle-comparison","monthly-accounts","daily-target","issues"⟩ lib.AssertEq table.key
⟨1,1,1,1,1,1,1,1,1⟩ lib.AssertEq table.human
⟨1,1,1,1,0,0,0,1,0⟩ lib.AssertEq table.compact
⟨1,1,0,1,0,0,0,0,0⟩ lib.AssertEq table.json
⟨"household","accounting","operations","operations","accounting","accounting","accounting","household","operations"⟩ lib.AssertEq table.category
(•FChars "../fixtures/ledger-facts-phase1-proof/report_catalog.destination.tsv") lib.AssertEq catalogText.FormatTsv @
(•FChars "../fixtures/ledger-facts-phase1-proof/report_metadata.destination.tsv") lib.AssertEq metadata.FormatTsv @
(•FChars "../fixtures/ledger-facts-phase1-proof/report_metadata.destination.json") lib.AssertEq metadata.FormatJson @
found ← catalog.Find "balances"
"ok" lib.AssertEq found.state
"balances" lib.AssertEq found.entry.key
unknown ← catalog.Find "snapshot"
"unknown" lib.AssertEq unknown.state
0 lib.AssertEq ≠unknown.entry

balancesJson ← request.Validate ⟨"balances","json"⟩
"ok" lib.AssertEq balancesJson.state
⟨"balances"⟩ lib.AssertEq balancesJson.section_keys
allHuman ← request.Validate ⟨"all","human"⟩
"ok" lib.AssertEq allHuman.state
table.key lib.AssertEq allHuman.section_keys
allCompact ← request.Validate ⟨"all","compact"⟩
⟨"envelopes","balances","recent","planned","daily-target"⟩ lib.AssertEq allCompact.section_keys

CheckError ← {𝕊 key‿surface‿code:
  result ← request.Validate ⟨key,surface⟩
  "error" lib.AssertEq result.state
  0 lib.AssertEq ≠result.section_keys
  code lib.AssertEq (⊑result.diagnostics).code
}
CheckError ⟨"issues","json","report_surface_unsupported"⟩
CheckError ⟨"cycle-accounts","compact","report_surface_unsupported"⟩
CheckError ⟨"all","json","report_surface_unsupported"⟩
CheckError ⟨"snapshot","human","report_key_unknown"⟩
CheckError ⟨"trial-balance","human","report_key_unknown"⟩
CheckError ⟨"balances","yaml","report_surface_unknown"⟩
•Out "test_report_catalog_request: ok"
