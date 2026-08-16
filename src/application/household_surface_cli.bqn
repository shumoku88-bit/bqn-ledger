surface ← •Import "household_surface.bqn"
args ← •args
{𝕊:•Out "ERROR: household surface metadata takes no arguments" ⋄ •Exit 2}⍟(0<≠args) @
•Out ¯1↓surface.FormatTsv @
