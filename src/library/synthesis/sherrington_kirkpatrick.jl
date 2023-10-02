@doc raw"""
    sherrington_kirkpatrick(rng, ::Type{F}, n::Integer; μ::T = zero(T), σ::T = one(T)) where {V,T,F<:AbstractPBF{V,T}}

```math
f^{(n)}_{\textrm{SK}}(\mathbf{x}) = \sum_{i = 1}^{n} \sum_{j = i + 1}^{n} J_{i, j} x_i x_j
```

where ``J_{i, j} \sim \mathcal{N}(0, 1)``.

"""
function sherrington_kirkpatrick(rng, ::Type{F}, n::Integer; μ::T = zero(T), σ::T = one(T)) where {V,T,F<:AbstractPBF{V,T}}
    J = Dict{Tuple{Int,Int},T}((i, j) => (σ * randn(rng, T) + μ) for i = 1:n for j = (i+1):n)

    # Convert to boolean
    # let s_i = 2x_i - 1
    # ⟹ s_i s_j = (2x_i - 1) (2x_j - 1) = 4x_i x_j - 2x_i - 2x_j + 1
    # ⟹ Jij s_i s_j = 4Jij x_i x_j - 2Jij x_i - 2Jij x_j + Jij
    f = sizehint!(zero(F), length(J) + n)

    for ((i, j), c) in J
        f[i, j]    += 4c
        f[i]       -= 2c
        f[j]       -= 2c
        f[nothing] += c
    end

    x = nothing # no planted solutions

    return (f, x)
end

function sherrington_kirkpatrick(::Type{F}, n::Integer; μ::T = zero(T), σ::T = one(T)) where {V,T,F<:AbstractPBF{V,T}}
    return sherrington_kirkpatrick(Random.GLOBAL_RNG, F, n; μ, σ)
end
