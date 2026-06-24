@doc raw"""
    Quadratization(::DEFAULT; stable::Bool = false, sign::Integer = 1)

Employs [`NTR_KZFD`](@ref) for negative terms and [`PTR_BG`](@ref) for the positive ones.
"""
struct DEFAULT <: QuadratizationMethod end

function _default_quadratization(c::T, quad::Quadratization{DEFAULT}) where {T}
    if quad.sign * c < zero(T)
        return Quadratization(NTR_KZFD(); stable = quad.stable, sign = quad.sign)
    else
        return Quadratization(PTR_BG(); stable = quad.stable, sign = quad.sign)
    end
end

function quadratize!(
    aux,
    f::AbstractPBF{V,T},
    ω::AbstractTerm{V},
    c::T,
    quad::Quadratization{DEFAULT},
) where {V,T}
    length(ω) < 3 && return f # Fast-track

    quadratize!(aux, f, ω, c, _default_quadratization(c, quad))

    return f
end

function _quadratization_auxiliaries!(
    aux,
    solution::Dict{V,Int},
    ω::AbstractTerm{V},
    c::T,
    quad::Quadratization{DEFAULT},
) where {V,T}
    return _quadratization_auxiliaries!(
        aux,
        solution,
        ω,
        c,
        _default_quadratization(c, quad),
    )
end
