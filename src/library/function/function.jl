@doc raw"""
    PseudoBooleanFunction{V,T,S}

This is a concrete implementation of [`AbstractPBF`](@ref) that uses the `S` data structure to store the terms of the function.
"""
struct PseudoBooleanFunction{V,T,S} <: AbstractPBF{V,T}
    Φ::S

    # Constructor: I know what I am doing
    function PseudoBooleanFunction{V,T,S}(Φ::S) where {V,T,S}
        return new{V,T,S}(Φ)
    end
end

const PBF{V,T,S} = PseudoBooleanFunction{V,T,S}

# Type promotion
function Base.promote_rule(::Type{PBF{V,Tf,S}}, ::Type{PBF{V,Tg,S}}) where {V,Tf,Tg,S}
    T = promote_type(Tf, Tg)

    return PBF{V,T,S}
end

# Arithmetic: '+', '-', '*', '/'
function Base.:(+)(f::F, g::G) where {V,Tf,Tg,F<:AbstractPBF{V,Tf},G<:AbstractPBF{V,Tg}}
    Ω = union(keys(f), keys(g))
    h = sizehint!(zero(F), length(Ω))

    for ω in Ω
        h[ω] = f[ω] + g[ω]
    end

    return h
end

function Base.:(-)(f::Ff, g::Fg) where {V,Tf,Tg,Ff<:AbstractPBF{V,Tf},Fg<:AbstractPBF{V,Tg}}
    F = promote_type(Ff, Fg)
    Ω = union(keys(f), keys(g))
    h = sizehint!(zero(F), length(Ω))

    for ω in Ω
        h[ω] = f[ω] - g[ω]
    end

    return h
end

# Comparsion: '==', '≈'
Base.:(==)(f::DictFunction{V,T}, g::DictFunction{V,T}) where {V,T} = (f.Ω == g.Ω)

function Base.isapprox(f::AbstractPBF{V,Tf}, g::AbstractPBF{V,Tg}; kw...) where {V,Tf,Tg}
    return length(f) == length(g) && all(ω -> isapprox(g[ω], f[ω]; kw...), keys(f))
end
