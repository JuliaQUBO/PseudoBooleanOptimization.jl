# PseudoBooleanOptimization.jl

```math
f(\mathbf{x}) = \sum_{\omega \subseteq [n]} c_{\omega} \prod_{j \in \omega} x_{j}
```

## Getting Started

```@example
import PseudoBooleanOptimization as PBO

f = PBO.PBF{Symbol,Float64}(
    :x       => 3.0,
    (:y, :z) => 4.0,
    (:x, :w) => 1.0,
    -100.0,
)

g = f^2 - 2f
```

## Table of Contents

```@contents
Pages = [
    "manual/1-intro.md",
    "manual/2-function.md",
    "manual/3-operators.md",
    "manual/4-quadratization.md",
]
Depth = 2
```
