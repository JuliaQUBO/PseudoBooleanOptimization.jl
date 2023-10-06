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

# Constructors
function PBF{V,T,S}(items) where {V,T,S}
    @assert Base.haslength(items)

    f = sizehint!(zero(PBF{V,T,S}), length(items))

    for x in items
        ω, c = term(PBF{V,T,S}, x)

        f[ω] += c
    end

    return f
end

function PBF{V,T,S}(args...) where {V,T,S}
    return PBF{V,T,S}(args)
end
