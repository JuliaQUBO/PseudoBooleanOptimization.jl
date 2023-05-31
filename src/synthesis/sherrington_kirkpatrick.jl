@doc raw"""
    sherrington_kirkpatrick(rng, ::Type{F}, n::Integer; μ::T = zero(T), σ::T = one(T)) where {V,T,F<:AbstractFunction{V,T}}
"""
function sherrington_kirkpatrick(rng, ::Type{F}, n::Integer; μ::T = zero(T), σ::T = one(T)) where {V,T,F<:AbstractFunction{V,T}}
    return sum([
        (σ * randn(rng, T) + μ) * F(i => T(2), T(-1)) * F(j => T(2), T(-1))
        for i = 1:n for j = (i+1):n
    ])
end
