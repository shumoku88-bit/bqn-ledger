# Anchor Unmet Failure Fixture

Tests plan rows with `anchor=income:年金` where the corresponding income has NOT been received in the current cycle.

Expected: The rent plan (anchor=年金, unmet) is treated as reserve. The salary plan (anchor=月給, met) is counted as planned income. Outlook fund = liquid + met_income - unmet_reserve.
