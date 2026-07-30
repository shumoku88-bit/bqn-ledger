# Effect-only adapter for the pure machine-readable report-route plan.

app ← •Import "report_route_plan.bqn"
result ← app.Run •args
•Out¨result.lines
{𝕊:•Exit result.exit_code}⍟(0≠result.exit_code) @
