@doc raw"""
    Quadratization{NTR_KZFD}(stable::Bool = false)

Negative term reduction NTR-KZFD (Kolmogorov & Zabih, 2004; Freedman & Drineas, 2005)

Let ``f(\mathbf{x}) = -x_{1} x_{2} \dots x_{k}``.

```math
\mathcal{Q}\left\lbrace{f}\right\rbrace(\mathbf{x}; z) = (k - 1) z - \sum_{i = 1}^{k} x_{i} z
```

where ``\mathbf{x} \in \mathbb{B}^k``

!!! info
    Introduces a new variable ``z`` and no non-submodular terms.
"""
struct NTR_KZFD <: QuadratizationMethod end

function quadratize!(
    aux,
    f::F,
    ω::Any,
    c::T,
    ::Quadratization{NTR_KZFD},
) where {V,T,F<:AbstractPBF{V,T}}
    @assert c < zero(T)

    ω_ = term_head(F, ω)

    # Degree
    k = length(ω_)

    # Fast-track
    k < 3 && return nothing

    # Variables
    s = aux()::V

    # Stabilization
    # NOTE: This method is stable by construction

    # Quadratization
    delete!(f, ω_)

    f[s] += -c * (k - 1)

    for i ∈ ω_
        f[i×s] += c
    end

    return f
end
