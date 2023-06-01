# PseudoBooleanOptimization.jl

```math
f(\mathbf{x}) = \sum_{\omega \subseteq [n]} c_{\omega} \prod_{j \in \omega} x_{j}
```

## Getting Started

```@example
using PseudoBooleanOptimization
const PBO = PseudoBooleanOptimization

f = PBO.PBF{Symbol,Float64}(
    :x       => 3.0,
    (:y, :z) => 4.0,
    (:x, :w) => 1.0,
)

g = f^2 - f
```
