@doc raw"""
    PBF{V,T,S}

This is a concrete implementation of [`AbstractPBF`](@ref) that uses the `S` data structure to store the terms of the function.
"""
struct PBF{V,T,S} <: AbstractPBF{V,T}
    Φ::S

    # Constructor: I know what I am doing
    function PBF{V,T,S}(Φ::S) where {V,T,S}
        return new{V,T,S}(Φ)
    end
end

# Internal representation
function data(f::PBF{V,T,S})::S where {V,T,S}
    return f.Φ
end

# Type promotion
function Base.promote_rule(::Type{PBF{V,Tf,S}}, ::Type{PBF{V,Tg,S}}) where {V,Tf,Tg,S}
    T = promote_type(Tf, Tg)

    return PBF{V,T,S}
end

# Constructors - Base case
function PBF{V,T,S}() where {V,T,S}
    return zero(PBF{V,T,S})
end

# Constructors - Induction
function PBF{V,T,S}(args...) where {V,T,S}
    return PBF{V,T,S}(collect(args))
end

# Constructors - Generator
function PBF{V,T,S}(items::G) where {V,T,S,G<:Iterators.Generator}
    return PBF{V,T,S}(collect(items))
end

# Constructors - Dict
# function PBF{V,T,S}(items::AbstractDict) where {V,T,S}
#     return PBF{V,T,S}(collect(items))
# end

# Constructors - Item list
function PBF{V,T,S}(items::AbstractVector) where {V,T,S}
    f = zero(PBF{V,T,S})

    Base.haslength(items) && sizehint!(f, length(items))

    for x in items
        ω, c = term(PBF{V,T,S}, x)

        f[ω] += c
    end

    return f
end
