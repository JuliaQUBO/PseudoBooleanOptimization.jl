@doc raw"""
    Quadratization{PTR_BG}(stable::Bool = false)

Positive term reduction PTR-BG (Boros & Gruber, 2014)

Let ``f(\mathbf{x}) = x_{1} x_{2} \dots x_{k}``.

```math
\mathcal{Q}\left\lbrace{f}\right\rbrace(\mathbf{x}; \mathbf{z}) = \left[{
    \sum_{i = 1}^{k-2} z_{i} \left({ k - i - 1 + x_{i} - \sum_{j = i+1}^{k} x_{j} }\right)
}\right] + x_{k-1} x_{k}
```
where ``\mathbf{x} \in \mathbb{B}^k`` and ``\mathbf{z} \in \mathbb{B}^{k-2}``

!!! info
    Introduces ``k - 2`` new variables ``z_{1}, \dots, z_{k-2}`` and ``k - 1`` non-submodular terms.
"""
struct PTR_BG <: QuadratizationMethod end

function quadratize!(
    aux,
    f::F,
    ω::Set{V},
    c::T,
    quad::Quadratization{PTR_BG},
) where {V,T,F<:AbstractPBF{V,T}}
    # Degree
    k = length(ω)

    # Fast-track
    k < 3 && return nothing

    # Variables
    s = aux(k - 2)::Vector{V}
    b = collect(ω)::Vector{V}

    # Stabilization
    quad.stable && sort!(b; lt = varlt)

    # Quadratization
    delete!(f, ω)

    f[b[k]×b[k-1]] += c

    for i = 1:(k-2)
        f[s[i]] += c * (k - i - 1)

        f[s[i]×b[i]] += c

        for j = (i+1):k
            f[s[i]×b[j]] -= c
        end
    end

    return f
end
