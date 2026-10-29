# Pseudo-Boolean functions

Let `f: \mathbb{B}^{n} \to \mathbb{R}`. Then `f` can be written as

```math
f(\mathbf{x}) = \sum_{\omega \subseteq [n]} c_{\omega} \prod_{j \in \omega} x_{j}
```

where ``c_{\omega} \in \mathbb{R}`` and ``x_{j} \in \{ 0, 1 \}`` for all ``j \in [n] = \{ 1, \dots, n \}``.

## Coercive Local Fields and ``\mathbb{Z}_2`` Gauge Invariance

For a quadratic pseudo-Boolean function (``\deg(f) \le 2``),

```math
f(\mathbf{x}) = c_{\varnothing} + \sum_{i} c_{\{i\}} x_{i} + \sum_{i < j} c_{\{i, j\}} x_{i} x_{j},
```

the spin transformation ``x_{i} = (s_{i} + 1) / 2`` with ``s_{i} \in \{-1, +1\}`` induces an Ising spin-glass Hamiltonian with couplings ``J_{i, j} = c_{\{i, j\}} / 4`` and **coercive local fields**

```math
h_{i} = \frac{1}{2} c_{\{i\}} + \frac{1}{4} \sum_{j \neq i} c_{\{i, j\}}.
```

Use [`PBO.coercive_field`](@ref), [`PBO.coercive_fields`](@ref), and [`PBO.is_gauge_invariant`](@ref) to inspect these induced local fields, and [`PBO.gauge_invariant_qubo`](@ref) (or [`PBO.gauge_invariant_qubo!`](@ref)) to project a quadratic pseudo-Boolean function onto its zero-field ``\mathbb{Z}_2`` bit-flip invariant form ``c_{\{i\}} = -\frac{1}{2} \sum_{j \neq i} c_{\{i, j\}}``:

```@example qubo_gauge
import PseudoBooleanOptimization as PBO

f = PBO.PBF{Symbol,Float64}(
    (:x, :y) => 8.0,
    (:y, :z) => -4.0,
)

PBO.coercive_fields(f)
```

```@example qubo_gauge
g = PBO.gauge_invariant_qubo(f)
PBO.is_gauge_invariant(g)
```
