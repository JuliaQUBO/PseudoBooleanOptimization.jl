@doc raw"""
    Quadratization(::NTR_KZFD; stable::Bool = false)

## Negative term reduction NTR-KZFD[^NTR_KZFD]

Let ``f(\mathbf{x}) = -x_{1} x_{2} \dots x_{k}``.

```math
\mathcal{Q}\left\lbrace{f}\right\rbrace(\mathbf{x}; w) = (k - 1) w - \sum_{i = 1}^{k} x_{i} w
```

where ``\mathbf{x} \in \mathbb{B}^k, w \in \mathbb{B}``.

### Properties

| Variables | Non-submodular Terms |
|:---------:|:--------------------:|
|     1     |          0           |

!!! info
    NTR-KZFD is only applicable to negative terms.

!!! info
    This method is stable by construction.

[^NTR_KZFD]:
    Kolmogorov & Zabih, 2004; Freedman & Drineas, 2005
"""
struct NTR_KZFD <: QuadratizationMethod end

function quadratize!(
    aux,
    f::F,
    ω::AbstractTerm{V},
    c::T,
    ::Quadratization{NTR_KZFD},
) where {V,T,F<:AbstractPBF{V,T}}
    @assert c < zero(T)

    # Degree
    k = length(ω)

    # Fast-track
    k < 3 && return f

    # Variables
    s = aux()::V

    # Stabilization
    # This method is stable by construction

    # Quadratization
    delete!(f, ω)

    f[s] += -c * (k - 1)

    for i ∈ ω
        f[i×s] += c
    end

    return f
end
