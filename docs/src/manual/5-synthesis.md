# Synthetic Problem Generation

```@example synthesis
import PseudoBooleanOptimization as PBO
using Random

f = PBO.wishart(PBO.PBF{Int,Float64}, 3, 5)
```

## Sherrington-Kirkpatrick and ``\mathbb{Z}_2`` Gauge Invariance

[`PBO.sherrington_kirkpatrick`](@ref) supports ``1 / \sqrt{n}`` coupling scaling (`normalize = true`, which renders the ground-state energy per variable intensive for the centered ``\mu = 0`` ensemble) and toggling between the zero-field ``\mathbb{Z}_2`` gauge-invariant expansion (`gauge_invariant = true`, default) and the naive Boolean QUBO ensemble (`gauge_invariant = false`):

```@example synthesis
rng = Random.MersenneTwister(42)
f_sk, _ = PBO.sherrington_kirkpatrick(rng, PBO.PBF{Int,Float64}, 6; normalize = true, gauge_invariant = true)
PBO.is_gauge_invariant(f_sk; atol = 1e-12)
```
