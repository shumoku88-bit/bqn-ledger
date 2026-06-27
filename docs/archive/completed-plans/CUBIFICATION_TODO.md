# BQN Cubification TODO List

## Phase 1: Foundation (date.bqn & report_tx_updates.bqn)
- [x] `date.bqn`: Implement `FromOrdinal` (convert ordinal number back to YYYY-MM-DD)
- [x] `report_tx_updates.bqn`: Implement `BuildCube` prototype
    - [x] Generate dense day axis (no gaps)
    - [x] Define 4 layers: Actual, Plan, Budget, Forecast
    - [x] Project Journal to Actual & Budget layers
    - [x] Project Plan to Plan layer
    - [x] Project BudgetAlloc to Budget layer

## Phase 2: Refactoring Reports
- [x] `report_engine.bqn`: Update to use the new Cube structure
- [x] `report_trend.bqn`: Remove direct `plan_rows` access, use Cube layers
- [x] `report_envelope_trend.bqn`: Use Cube layers for history and planned spend (Optimized with array slices, manual loops removed)

## Phase 3: Validation & Cleanup
- [x] Add invariants check (Implicitly verified by reports)
- [x] Update documentation (`docs/CANONICAL_DAILY_CUBE.md`)
- [x] Clean up legacy `BuildDays` / `day_balances` (Kept for compatibility for now)
