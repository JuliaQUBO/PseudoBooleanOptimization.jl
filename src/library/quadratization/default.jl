@doc raw"""
    Quadratization(::DEFAULT; stable::Bool = false, sign::Integer = 1)

Employs [`NTR_KZFD`](@ref) for negative terms and [`PTR_BG`](@ref) for the positive ones.
"""
struct DEFAULT <: QuadratizationMethod end

function quadratize!(
    aux,
    f::AbstractPBF{V,T},
    ω::AbstractTerm{V},
    c::T,
    quad::Quadratization{DEFAULT},
) where {V,T}
    length(ω) < 3 && return f # Fast-track

    if quad.sign * c < zero(T)
        quadratize!(
            aux,
            f,
            ω,
            c,
            Quadratization(NTR_KZFD(); stable=quad.stable, sign=quad.sign),
        )
    else
        quadratize!(
            aux,
            f,
            ω,
            c,
            Quadratization(PTR_BG(); stable=quad.stable, sign=quad.sign),
        )
    end

    return f
end
