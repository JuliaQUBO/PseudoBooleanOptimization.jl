# PseudoBooleanOptimization.jl

<a href="/actions/workflows/ci.yml">
    <img src="https://github.com/pedromxavier/PseudoBooleanOptimization.jl/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI" />
</a>
<a href="https://pedromxavier.github.com/PseudoBooleanOptimization.jl/dev">
    <img src="https://img.shields.io/badge/docs-dev-blue.svg" alt="Docs">
</a>

## Introduction

$$ f(\mathbf{x}) = \sum_{\omega \subseteq [n]} c_{\omega} \prod_{j \in \omega} x_{j} $$

## Installation
```julia
julia> import Pkg; Pkg.add(url="https://github.com/pedromxavier/PseudoBooleanOptimization.jl")
```

## Getting Started
```julia
using PseudoBooleanOptimization
const PBO = PseudoBooleanOptimization

f = PBO.PBF{Symbol,Float64}([
    [:x, :y] => 10.0,
    [:x, :z] => 15.0,
    [:y, :z] => -5.0,
])

g = PBO.PBF{Symbol,Float64}([
    :x => 1.0,
    :y => 2.0,
    :z => 3.0,
])

h = f + g
```
Output:
```julia
1.0x + 2.0y + 3.0z + 10.0x*y + 15.0x*z - 5.0y*z
```
