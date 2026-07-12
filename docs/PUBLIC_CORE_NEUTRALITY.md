# Public Core Neutrality

## Purpose

BQN Ledger should be usable as a private household tool and readable as a public reference repository without changing its primary identity.

The goal is not to make the project vague or impersonal. The goal is to keep the core specific to household accounting while avoiding assumptions tied to one person's biography, income pattern, institutions, health, relationships, or daily history.

The public core is designed positively. We first decide what the repository should teach, demonstrate, and provide. Publication filtering is a final safety check, not the organizing principle.

## Core qualities

Primary files should be:

- **domain-specific**: clearly about plain-text household accounting;
- **biographically neutral**: not dependent on one person's circumstances;
- **moderate in voice**: neither promotional nor confessional;
- **operationally complete**: examples and defaults form a coherent runnable system;
- **adaptable**: personal policies live in external data or explicit configuration;
- **inspectable**: examples explain the model without pretending to be real household records.

## Primary-file boundary

The following are treated as the public face of the project and should naturally satisfy this standard:

1. `README.md`
2. `config/**`
3. the default sandbox dataset
4. representative fixtures and golden outputs
5. active architecture and operation documents
6. command help, diagnostics, and user-facing error messages
7. source comments that explain domain policy

Archive material may preserve project history, but it must not define the current public introduction or default behavior.

## Language and voice

Primary documentation should normally speak about:

- a household, user, operator, dataset, account, cycle, plan, or transaction;
- configurable income and expense schedules;
- generic institutions such as a bank, card provider, shop, employer, or public agency only when the feature requires them;
- explicit accounting behavior rather than inferred personal motives.

Primary documentation should not require knowledge of:

- the maintainer's income source or payment cadence;
- medical, welfare, disability, family, friendship, or support arrangements;
- actual merchants, locations, dates, balances, debts, subscriptions, or appointments;
- personal philosophy that is not needed to understand or operate the ledger.

A personal origin story may exist in a clearly marked essay or archive document. It should not leak into defaults, fixtures, commands, or architectural contracts.

## Defaults

Defaults must represent the smallest coherent household ledger, not the maintainer's current setup.

A good default:

- works without external personal data;
- uses ordinary account names and conservative settings;
- avoids prescribing a budgeting method unless the feature is explicitly selected;
- does not assume a monthly salary, pension cycle, cash-only life, credit-card use, or a particular household structure;
- makes local customization obvious.

Where no universally reasonable behavioral default exists, prefer an explicit required setting or a documented neutral example.

## Fixtures and examples

Fixtures are teaching models, not anonymized household history.

Every public fixture should:

- be deliberately synthetic from its first row;
- have a named learning purpose;
- use a compact fictional scenario;
- contain round or clearly illustrative values;
- avoid real-world continuity that resembles a copied personal journal;
- include only the rows needed to demonstrate the behavior;
- remain internally consistent across journal, plan, budget, accounts, and cycle data.

Recommended fictional vocabulary:

- accounts: `assets:bank`, `assets:cash`, `income:salary`, `expenses:groceries`, `expenses:utilities`;
- counterparties: `Example Market`, `Utility Company`, `Card Provider`;
- memos: `weekly groceries`, `electric bill`, `monthly income`;
- dates: a short, fixed demonstration period documented as fictional.

Japanese examples may use equally ordinary fictional labels. Do not mix a generic fixture with details copied from actual life.

## Configuration versus personal policy

The core should provide mechanisms. Personal datasets provide policy.

Examples:

- the core supports arbitrary cycle boundaries; a private dataset chooses a particular income date;
- the core supports envelopes; a private dataset chooses whether and how to use them;
- the core supports issues and plans; a private dataset records actual decisions and obligations;
- the core supports account metadata; a private dataset supplies local account names and classifications.

A rule belongs in the core only when it protects data integrity, defines the accounting model, or provides broadly useful behavior. A rule that merely matches one household belongs in configuration or external source data.

## Review questions

For each primary file, review in this order:

1. What should a new reader learn from this file?
2. Does the file describe a general household-accounting capability or one household's policy?
3. Are examples intentionally fictional and minimal?
4. Could another user adopt the file without first removing the maintainer's assumptions?
5. Is any personal explanation necessary for the technical contract?
6. Would moving a detail to external data or a historical essay make the core clearer?

## Migration order

Neutralization should proceed in small reviewable slices:

1. README positioning and quick start
2. default sandbox dataset and account vocabulary
3. representative fixtures and golden outputs
4. configuration defaults
5. active operational documentation
6. command help and diagnostics
7. active architecture documents
8. archive classification and optional personal essays

Each slice should preserve behavior unless a separate behavioral change is explicitly justified.

## Completion condition

The public core is ready when a new reader can clone the repository, run its default example, understand its accounting model, and adapt it without encountering unexplained details from the maintainer's private life.

This standard does not erase the project's origin. It gives the origin a clean vessel.