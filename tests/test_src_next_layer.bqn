#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
layer ← •Import "../src_next/layer.bqn"
proj ← •Import "../src_next/projection.bqn"
cube ← •Import "../src_next/cube.bqn"

0 lib.AssertEq layer.layer_actual
1 lib.AssertEq layer.layer_plan
2 lib.AssertEq layer.layer_budget
3 lib.AssertEq layer.layer_forecast
4 lib.AssertEq layer.layer_count
⟨"actual", "plan", "budget", "forecast"⟩ lib.AssertEq layer.layer_names
layer.layer_names lib.AssertEq layer.LayerName¨ ↕ layer.layer_count

# Existing module surfaces remain compatibility delegates to the pure owner.
layer.layer_actual lib.AssertEq proj.layer_actual
layer.layer_plan lib.AssertEq proj.layer_plan
layer.layer_budget lib.AssertEq proj.layer_budget
layer.layer_forecast lib.AssertEq proj.layer_forecast
"actual" lib.AssertEq proj.LayerName proj.layer_actual

layer.layer_actual lib.AssertEq cube.layer_actual
layer.layer_plan lib.AssertEq cube.layer_plan
layer.layer_budget lib.AssertEq cube.layer_budget
layer.layer_forecast lib.AssertEq cube.layer_forecast
layer.layer_names lib.AssertEq cube.layer_names
layer.layer_count lib.AssertEq cube.layer_count

•Out "test_src_next_layer.bqn: OK"
