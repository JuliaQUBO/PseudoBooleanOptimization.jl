@doc raw"""
    Quadratization(::PTR_BG; stable::Bool = false, sign::Integer = 1)

## Positive term reduction PTR-BG[^PTR_BG]

Let ``f(\mathbf{x}) = x_{1} x_{2} \dots x_{k}``.

```math
\mathcal{Q}\left\lbrace{f}\right\rbrace(\mathbf{x}; \mathbf{w}) = \left[{
    \sum_{i = 1}^{k-2} z_{i} \left({ k - i - 1 + x_{i} - \sum_{j = i+1}^{k} x_{j} }\right)
}\right] + x_{k-1} x_{k}
```

where ``\mathbf{x} \in \mathbb{B}^k`` and ``\mathbf{w} \in \mathbb{B}^{k-2}``

### Properties

| Variables | Non-submodular Terms |
|:---------:|:--------------------:|
|   k - 2   |        k - 1         |

[PTR_BG]:
    Boros & Gruber, 2014
"""
struct PTR_BG <: QuadratizationMethod end

function quadratize!(
    aux,
    f::F,
    ω::AbstractTerm{V},
    c::T,
    quad::Quadratization{PTR_BG},
) where {V,T,F<:AbstractPBF{V,T}}
    @assert quad.sign * c > zero(T)

    # Degree
    k = length(ω)

    # Fast-track
    k < 3 && return f

    # Variables
    s = aux(k - 2)::Vector{V}
    b = collect(ω)::Vector{V}

    # Stabilization
    # Since the variables are sorted by default, this method is naturally stable

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

function _quadratization_auxiliaries!(
    aux,
    solution::Dict{V,Int},
    ω::AbstractTerm{V},
    c::T,
    quad::Quadratization{PTR_BG},
) where {V,T}
    @assert quad.sign * c > zero(T)

    variables = aux(length(ω) - 2)::Vector{V}
    terms = collect(ω)::Vector{V}

    for i = 1:(length(ω)-2)
        coefficient =
            length(ω) - i - 1 +
            solution[terms[i]] -
            sum(solution[terms[j]] for j = (i+1):length(ω); init = 0)

        solution[variables[i]] = quad.sign * c * coefficient < zero(T) ? 1 : 0
    end

    return variables
end
