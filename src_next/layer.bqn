# layer.bqn
# Low-dependency owner for the current Layer coordinate vocabulary.
#
# This module owns only the fixed Layer axis names, indices, count, and
# index-to-name representation. Source identity routing and source admission
# remain separate responsibilities.

layer_actual   ← 0
layer_plan     ← 1
layer_budget   ← 2
layer_forecast ← 3

layer_names ← ⟨"actual", "plan", "budget", "forecast"⟩
layer_count ← ≠ layer_names

LayerName ← {𝕊 layerIdx: layerIdx ⊑ layer_names }

{
  layer_actual   ⇐ layer_actual,
  layer_plan     ⇐ layer_plan,
  layer_budget   ⇐ layer_budget,
  layer_forecast ⇐ layer_forecast,
  layer_names    ⇐ layer_names,
  layer_count    ⇐ layer_count,
  LayerName      ⇐ LayerName
}
