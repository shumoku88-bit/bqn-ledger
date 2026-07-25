# Native Journal non-JPY single-currency admission characterization

Status: completed docs/test-boundary characterization
Owner: Journal / currency admission
Date: 2026-07-25
Canonical continuation route: `TODO.md`

## 1. Finite question

> Can the current native Journal architecture be widened so that a household ledger whose arithmetic domain is one supported non-JPY currency can use the same accounting pipeline, without introducing mixed-currency aggregation, FX valuation, or an ILS-specific special case?

The concrete first witness is one balanced ILS Actual transaction between two existing ILS accounts. ILS is evidence for an immediate travel need, not the intended architectural boundary.

## 2. Result

**Yes, the repository already contains enough currency-parameterized foundation to preserve the possibility of a non-JPY household ledger. It does not yet provide that runtime capability.**

The reusable foundation already includes:

- a repository-owned supported-currency registry containing JPY, ILS, and USD;
- per-currency lexical precision policy;
- exact-decimal parsing into coefficient and scale;
- a pure arithmetic owner that accepts one supported currency domain and rejects mixed domains;
- AccountKey identity that includes account currency;
- strict source-currency admission that accepts any explicitly supported registry currency.

The current native Journal route narrows that foundation back to JPY at several later boundaries:

- Stage 1 admits only a JPY commodity declaration;
- Stage 1 posting amounts must be exact integers;
- native rendering always emits JPY;
- native writer and post-write validation require every account and posting to be JPY;
- Stage 2A does not retain currency or arithmetic scale in Posting IR rows;
- `BuildContext` requires the non-Actual arithmetic proof to be JPY and merges native Actual rows without a ledger-wide Actual + non-Actual domain proof;
- selected balances fail closed outside JPY.

Therefore the problem is not absence of a currency model. It is a sequence of JPY-only gates and one missing ledger-wide single-domain proof.

## 3. Meaning of “possibility is guaranteed”

This characterization distinguishes three levels.

### 3.1 Preserved architectural possibility

This is established now.

The registry, exact-decimal, AccountKey, and single-domain arithmetic owners are not intrinsically JPY-only. Widening native Journal admission does not require inventing FX conversion or replacing the Canonical Daily Cube with a Currency axis.

### 3.2 Supported non-JPY single-currency runtime

This is not established now.

A future implementation must prove that one configured supported currency is preserved from raw native Journal evidence through account admission, normalization, Posting IR/context, Cube/TBDS, and formatting.

### 3.3 Generic supported-currency claim

One ILS success is insufficient for a broad claim.

A second non-JPY witness, preferably USD because it is already in `config/currencies.tsv`, or an equivalent parameterized proof is required before documentation may claim that the path is reusable across all supported registry currencies.

No result here authorizes arbitrary ISO currency codes. A currency must remain explicitly admitted by the repository registry and precision policy.

## 4. Existing reusable foundation

| Boundary | Current owner | Current reusable property | Qualification |
|---|---|---|---|
| supported currencies | `config/currencies.tsv`, `src_next/currency_registry.bqn` | registry data determines admitted codes and precision policy | current registry contains JPY, ILS, USD only |
| default and explicit selection | `src_next/currency_setup.bqn` | resolves any registry-supported currency with provenance | selection does not itself prove source arithmetic safety |
| exact source quantity | `src_next/exact_decimal.bqn` | parses decimal text into exact coefficient + scale | no sign; callers own sign and currency precision |
| arithmetic normalization | `src_next/currency_arithmetic.bqn` | accepts exactly one supported domain, normalizes scale, rejects mixed domains | empty evidence defaults to JPY compatibility |
| account coordinate | `src_next/account_key.bqn` | AccountKey is `(account, currency)` and conversion is out of scope | missing account currency still defaults to JPY |
| strict row/account admission | `src_next/source_currency_admission.bqn` | explicit supported currencies are admitted generically | legacy missing-currency compatibility resolves to JPY |
| amount display policy | `src_next/balances.bqn` helpers | calculation scale and presentation scale are separated | current selected balance orchestration permits JPY only |

### 4.1 Exact-decimal evidence

`exact_decimal.Parse` is currency-neutral. For example, source text such as `12.34` becomes an exact coefficient and scale rather than a floating-point approximation.

Currency policy remains a separate owner. The ILS and USD registry rows currently allow at most two fractional digits.

### 4.2 Arithmetic-domain evidence

`currency_arithmetic.Build` already performs the most important semantic rejection:

- all admitted evidence must carry the same supported currency;
- mixed domains fail;
- quantities are normalized to one snapshot-wide scale;
- exact-range failure closes the result without partial coefficients.

This is suitable foundation for a JPY-only ledger, an ILS-only ledger, or a USD-only ledger. It is deliberately not suitable for adding JPY and ILS together.

### 4.3 Account coordinate evidence

AccountKey already includes currency. Two accounts with different currency metadata receive different account coordinates.

For a proven single-currency context, the existing `Day × Account × Layer` Cube shape can remain plausible because every numeric cell belongs to one context-wide arithmetic domain and each account coordinate also carries currency identity.

This is a design inference supported by the current contracts, not a runtime proof. Mixed-currency context materialization would require a separate decision.

## 5. Current JPY-only gates

### 5.1 Native Journal Stage 1 parser

Owner: `src_next/journal_profile_stage1.bqn`

Current gates:

- commodity declarations other than JPY are rejected;
- at least one JPY commodity declaration is required;
- transaction metadata `currency` is valid only when its value is JPY;
- posting amounts must be explicit exact integers;
- posting commodity must match a declared commodity.

Consequence: a syntactically valid balanced ILS block cannot enter current Transaction IR.

### 5.2 Native Journal writer

Owner: `src_edit/journal_block_add_cmd.bqn`

Current gates:

- each posting argument must contain a canonical signed integer;
- every internal posting descriptor is assigned `commodity="JPY"`;
- every selected account must resolve to JPY;
- rendered posting lines always end with `JPY`;
- parsed candidate verification requires every candidate commodity to be JPY.

Consequence: the public stable native writer cannot express decimal ILS or USD postings.

### 5.3 Mandatory post-write source check

Owner: `src_edit/journal_native_source_check.bqn`

Current gates independently repeat the JPY contract:

- expected posting amounts must be integers;
- expected posting commodity is JPY;
- every resolved account must be JPY;
- every written posting must be nonzero JPY exact-integer evidence;
- candidate verification requires all posting commodities to be JPY.

Consequence: widening only the preview renderer would still fail the mandatory post-write boundary.

### 5.4 Stage 2A Posting IR adaptation

Owner: `src_next/journal_posting_ir_stage2a.bqn`

Stage 2A is structurally less JPY-specific than the parser and writer, but its current 16-field row omits:

- posting commodity;
- arithmetic domain;
- source amount scale;
- context calculation scale.

It copies the posting numeric `delta` into the row and resolves AccountKey, but does not prove that the posting commodity equals the resolved account currency.

Consequence: simply allowing decimal ILS in Stage 1 would lose the unit/scale evidence before Cube/TBDS materialization. Stage 2A cannot be treated as already non-JPY-ready.

### 5.5 Context assembly

Owner: `src_next/context.bqn`

Current non-Actual TSV arithmetic is comparatively generic:

- row evidence can carry an explicit supported currency;
- `currency_arithmetic.Build` can prove one supported domain and normalize scale.

But `BuildContext` currently:

- requires the non-Actual domain to equal JPY;
- does not derive equivalent arithmetic-domain evidence from native Actual transactions;
- concatenates native Actual Posting IR rows with non-Actual rows after the JPY-only check;
- exposes the non-Actual proof as the context arithmetic proof.

Consequence: a whole-ledger USD or ILS configuration cannot be obtained by changing `DEFAULT_CURRENCY`. Actual, plan, and budget need one combined proof that they share the same supported domain and calculation scale.

### 5.6 Immediate consumers

`src_next/balances.bqn` selected-currency orchestration currently rejects every currency except JPY.

Other Cube/TBDS consumers often sum naked numeric deltas. Those sums can remain valid only after a context-wide single-domain proof. They must not independently guess currency from account names, selected report options, or display symbols.

## 6. Required generic contract

A reusable non-JPY admission boundary must express this invariant:

```text
one complete ledger context
  -> exactly one supported arithmetic currency domain C
  -> every admitted Actual, plan, and budget quantity belongs to C
  -> every posting account belongs to C
  -> every amount satisfies policy(C)
  -> all quantities normalize exactly to one calculation scale S
  -> Posting/Cube/TBDS arithmetic uses normalized coefficients only
  -> human formatting uses C and a presentation scale derived from policy(C)
```

This contract applies equally to a JPY-only, ILS-only, or USD-only household ledger.

It does not permit:

- a JPY account and an ILS account in one balanced transaction;
- an exchange transaction represented by equal naked numbers in different currencies;
- adding JPY and ILS totals;
- selecting a display currency and reinterpreting source quantities;
- implicit FX rates or valuation.

## 7. ILS-specific evidence versus reusable semantics

### 7.1 ILS-specific witness facts

- currency code: `ILS`;
- registry precision: at most two fractional digits;
- immediate need: physical-cash and Wise-balance spending during Israel travel;
- example source amount may be `12.34 ILS`.

### 7.2 Reusable semantics

- currency code comes from the supported registry;
- precision comes from the selected currency policy;
- all accounts and postings must match the selected domain;
- exact decimal source text becomes normalized coefficient evidence;
- one arithmetic scale is carried through the context;
- mixed-domain evidence fails closed.

No generic module should contain `israel-2026`, `cash`, `Wise`, travel account-name patterns, or ILS-only branching except in focused witness fixtures/tests.

## 8. Smallest test-only implementation contract supported by this audit

The smallest supported continuation is **not** production `journal add --currency ILS`.

Select a pure, test-only supported-single-currency native Journal admission proof with no runtime wiring.

Proposed conceptual boundary:

```text
AdmitSupportedSingleCurrencyJournal
  raw Journal witness
  resolved account registry
  supported currency registry/policy
  -> state
  -> domain
  -> calculation_scale
  -> normalized transaction/posting evidence
  -> diagnostics
```

Required success evidence:

1. one balanced ILS transaction with two existing ILS accounts and an amount such as `12.34 ILS`;
2. exact result domain `ILS` and calculation scale `2`;
3. normalized signed coefficients balance to zero;
4. source description, identity, account, commodity, and amount text remain traceable;
5. no production parser, writer, context, Cube, TBDS, or report route is changed.

Required rejection evidence:

1. unsupported currency;
2. precision beyond registry policy;
3. account currency differs from posting/domain currency;
4. mixed commodities in one transaction or source;
5. unbalanced normalized coefficients;
6. zero posting;
7. exact-range failure;
8. malformed or ambiguous currency declaration.

Required generality evidence before a reusable claim:

- repeat the same successful contract with USD, using only registry/policy inputs and fixture values changed from the ILS witness;
- no code branch may test whether the domain equals ILS or USD.

The implementation may reuse current parser components or introduce a separate test-only pure seam. It must not silently widen the production `historical_external_plan` profile.

## 9. Recommended continuation sequence

1. **Test-only supported-single-currency native Journal admission proof**
   - ILS and USD witnesses;
   - raw source to domain/scale/normalized evidence;
   - no production routing.
2. **Production Stage 1 / complete-source contract decision**
   - choose whether to parameterize the current profile or introduce an explicitly selected supported-single-currency profile.
3. **Stage 2A/context currency-proof carrier decision**
   - retain domain and scale without automatically adding a Currency axis;
   - prove account-currency equality and Actual + plan + budget single-domain composition.
4. **Native ordinary-add writer implementation for a selected supported currency**
   - first operational witness may be ILS;
   - preserve existing JPY behavior.
5. **Single-domain consumer and formatting verification**
   - balances and immediate reports use context domain/scale;
   - no mixed-currency totals.
6. Travel metadata, reverse exchange, Wise semantics, and friend finalization remain separate.

## 10. Decision

The repository should treat the Israel ILS need as a pressure test for a **supported single-currency household ledger**, not as an ILS-specific feature branch.

This direction preserves the possibility that the same program can later run as:

- a JPY household ledger;
- an ILS household ledger;
- a USD household ledger;
- another explicitly registered and tested single-currency ledger.

It does **not** yet preserve or authorize one mixed-currency accounting total, FX conversion, valuation, or cross-currency transfer accounting.

The next eligible finite implementation candidate is the test-only supported-single-currency native Journal admission proof described in section 8. It remains unselected until `TODO.md` explicitly selects it.
