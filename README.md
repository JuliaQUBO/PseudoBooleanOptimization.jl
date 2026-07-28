# PseudoBooleanOptimization.jl

<div align="center">
    <a href="/docs/src/assets/">
        <img src="/docs/src/assets/logo.svg" width=400px alt="ToQUBO.jl" />
    </a>
    <br>

[![codecov](https://codecov.io/gh/JuliaQUBO/PseudoBooleanOptimization.jl/graph/badge.svg?token=87V5MR99ET)](https://codecov.io/gh/JuliaQUBO/PseudoBooleanOptimization.jl)
[![CI](https://github.com/JuliaQUBO/PseudoBooleanOptimization.jl/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/JuliaQUBO/PseudoBooleanOptimization.jl/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaQUBO.github.io/PseudoBooleanOptimization.jl/dev)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21650202.svg)](https://doi.org/10.5281/zenodo.21650202)

</div>

## Introduction

$$ f(\mathbf{x}) = \sum_{\omega \subseteq [n]} c_{\omega} \prod_{j \in \omega} x_{j} $$

## Installation
```julia
julia> import Pkg; Pkg.add("PseudoBooleanOptimization")
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

## Citation

For general use, cite `PseudoBooleanOptimization.jl` with its
[Zenodo concept DOI](https://doi.org/10.5281/zenodo.21650202). The concept DOI
is the evergreen software identifier and resolves to the latest archived
release. Citation metadata is available in [`CITATION.cff`](CITATION.cff).

For exact-version reproducibility, cite the corresponding Zenodo version DOI.
The archive for `v0.3.0` is
[10.5281/zenodo.21650203](https://doi.org/10.5281/zenodo.21650203).

For general discussion of the JuliaQUBO ecosystem, cite the
[QUBO.jl ecosystem article](https://doi.org/10.1080/10556788.2026.2702926).
