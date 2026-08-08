#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
posting ← •Import "../src/ledger/journal_posting_text.bqn"

tab ← @+9

a ← posting.Split "  Assets:Cash  -100 JPY"
lib.Assert a.valid
"Assets:Cash" lib.AssertEq a.account
⟨"-100","JPY"⟩ lib.AssertEq a.words
0 lib.AssertEq a.elided

b ← posting.Split "  Assets:Cash Wallet  -100 JPY ; note"
lib.Assert b.valid
"Assets:Cash Wallet" lib.AssertEq b.account
⟨"-100","JPY"⟩ lib.AssertEq b.words

c ← posting.Split tab∾"Assets:Cash Wallet"∾tab∾"-100"∾tab∾"JPY"
lib.Assert c.valid
"Assets:Cash Wallet" lib.AssertEq c.account
⟨"-100","JPY"⟩ lib.AssertEq c.words

d ← posting.Split "  Expenses:Food ; inferred"
lib.Assert d.valid
"Expenses:Food" lib.AssertEq d.account
1 lib.AssertEq d.elided
0 lib.AssertEq ≠d.words

e ← posting.Split "  Assets:Cash  -100"
0 lib.AssertEq e.valid

•Out "test_ledger_journal_posting_text: ok"
