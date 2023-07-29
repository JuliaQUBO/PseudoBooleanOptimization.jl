@doc raw"""
    sherrington_kirkpatrick(rng, ::Type{F}, n::Integer; μ::T = zero(T), σ::T = one(T)) where {V,T,F<:AbstractFunction{V,T}}

```math
f^{(n)}_{\textrm{SK}}(\mathbf{x}) = \sum_{i = 1}^{n} \sum_{j = i + 1}^{n} J_{i, j} x_i x_j
```

where ``J_{i, j} \sim \mathcal{N}(0, 1)``.

"""
function sherrington_kirkpatrick(rng, ::Type{F}, n::Integer; μ::T = zero(T), σ::T = one(T)) where {V,T,F<:AbstractFunction{V,T}}
    return sum([
        (σ * randn(rng, T) + μ) * F(i => T(2), T(-1)) * F(j => T(2), T(-1))
        for i = 1:n for j = (i+1):n
    ])
end

function sherrington_kirkpatrick(::Type{F}, n::Integer; μ::T = zero(T), σ::T = one(T)) where {V,T,F<:AbstractFunction{V,T}}
    return sherrington_kirkpatrick(Random.GLOBAL_RNG, F, n; μ, σ)
end
