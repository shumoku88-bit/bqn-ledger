# ASCII Garden Report Materials

Status: experimental / read-only projection boundary

## Purpose

This experiment prepares a stable bundle of household-ledger material that an AI can turn into a large fixed-width ASCII-art "garden" report.

The first goal is not to make the BQN engine draw arbitrary art. The first goal is to preserve meaning and provenance while giving a renderer enough material to create a changing scene.

```text
accounting source TSVs
  -> existing BQN interpretation
  -> structured section exports + selected human sections
                                      \
                                       -> materials bundle -> AI renderer -> ASCII garden
weather forecast snapshot ------------/
```

## Core boundary

Different meanings remain different.

- The configured native Journal remains the Actual household-event source.
- `plan.tsv` remains future expected events.
- `budget_alloc.tsv` remains budget allocation source data.
- issues remain unresolved/decision-tracking material.
- weather is external context.
- the ASCII garden is a derived presentation.

Weather must never be appended to the configured native Journal, `plan.tsv`, `budget_alloc.tsv`, `cycle.tsv`, or `accounts.tsv` merely to make the garden renderer convenient.

## First materials bundle

The initial bundle should contain existing surfaces rather than reimplementing accounting meaning in shell:

Structured JSON:

- `snapshot.json`
- `balances.json`
- `planned.json`
- `envelopes.json`

Selected canonical human sections until dedicated structured exports exist:

- `cycle.txt`
- `issues.txt`
- `outlook.txt`
- `daily-trend.txt`

External context:

- `weather.json` when a recorded forecast snapshot is available

Renderer guidance:

- `PROMPT.md`
- `LAYOUT.txt`
- `manifest.tsv`

## Weather snapshot policy

Weather is an external observation/forecast stream, not accounting truth.

Recommended provider for the first slice: Open-Meteo Forecast API.

The request should use coordinates supplied from local environment variables, not committed repository config. Recommended variables:

```text
WEATHER_LATITUDE
WEATHER_LONGITUDE
WEATHER_TIMEZONE=auto
WEATHER_LOCATION_LABEL=local
WEATHER_FORECAST_DAYS=3
```

Recommended requested fields:

Current:

```text
temperature_2m
relative_humidity_2m
apparent_temperature
precipitation
weather_code
cloud_cover
wind_speed_10m
wind_direction_10m
```

Daily:

```text
weather_code
temperature_2m_max
temperature_2m_min
precipitation_probability_max
precipitation_sum
sunrise
sunset
```

The first implementation should record the raw JSON response per fetch instead of normalizing it immediately.

```text
<weather-data-dir>/
  index.tsv
  forecast-20260705T120000Z.json
  forecast-20260706T000000Z.json
  ...
```

Why raw snapshots first:

- no second weather schema becomes authoritative too early;
- forecast changes remain inspectable;
- an AI renderer can read the provider response directly;
- normalization can be added later after real use shows which fields matter.

The provider documentation is:

```text
https://open-meteo.com/en/docs
```

## Privacy boundary

Coordinates are location data.

- keep coordinates in local `.env` or another private environment source;
- do not add personal coordinates to public repository config;
- remember that raw weather JSON may contain returned latitude/longitude;
- treat a materials bundle containing weather as private unless reviewed/redacted.

## Renderer rules

The AI renderer must:

1. preserve supplied numbers verbatim unless a derived calculation is explicitly requested;
2. never treat missing/unavailable as zero;
3. never turn plan into actual, budget into cash, or weather into accounting fact;
4. use scene changes as presentation, not as new canonical meaning;
5. keep source provenance visible in a compact footer;
6. produce a fixed-width report from the supplied layout/prompt contract.

## Suggested first scene mapping

These are presentation ideas, not source semantics:

```text
weather                 -> sky / clouds / rain marks / sun
available cash          -> house or central store
execution envelopes     -> sheds / marked crates
reserve                 -> barn / cistern
plan due/overdue        -> notice board / gate signs
issues                   -> fence posts / unfinished path
cycle progress          -> horizon / road / calendar strip
```

A missing field should make the corresponding object unknown or absent. It must not silently become an empty object or zero balance.

## Non-goals

- no accounting source TSV mutation
- no weather-driven budget advice in the first slice
- no BQN ASCII rendering engine yet
- no general-purpose report registry rewrite
- no requirement to normalize weather JSON yet
- no autonomous AI write-back into ledger sources

## First implementation slices

1. Add renderer prompt and layout templates.
2. Add a read-only materials bundle command built from existing report exports.
3. Add an independent weather snapshot fetch/record command.
4. Use the bundle with an AI manually before automating rendering.
5. Only after repeated use, decide whether a dedicated `GardenViewModel` is justified.
