@doc raw"""
    Quadratization{DEFAULT}(stable::Bool = false)

Employs other methods, specifically [`NTR_KZFD`](@ref) and [`PTR_BG`](@ref).
"""
struct DEFAULT <: QuadratizationMethod end

function quadratize!(
    aux,
    f::AbstractPBF{V,T},
    ω::Any,
    c::T,
    quad::Quadratization{DEFAULT},
) where {V,T}
    if c < zero(T)
        quadratize!(aux, f, ω, c, Quadratization(NTR_KZFD(); stable=quad.stable))
    else
        quadratize!(aux, f, ω, c, Quadratization(PTR_BG(); stable=quad.stable))
    end

    return f
end

function quadratize!(
    aux,
    f::AbstractPBF{V,T},
    quad::Quadratization,
) where {V,T}
    # Collect Terms
    Ω = collect(f)

    # Stable Quadratization
    quad.stable && sort!(Ω; by = first, lt = varlt)

    for (ω, c) in Ω
        quadratize!(aux, f, ω, c, quad)
    end

    return f
end

@doc raw"""
    Quadratization{INFER}(stable::Bool = false)
"""
struct INFER <: QuadratizationMethod end

@doc raw"""
    infer_quadratization(f::AbstractPBF)

For a given PBF, returns whether it should be quadratized or not, based on its degree.
"""
function infer_quadratization(f::AbstractPBF, stable::Bool = false)
    k = degree(f)

    if k <= 2
        return nothing
    else
        # Without any extra knowledge, it is better to
        # quadratize using the default approach
        return Quadratization(DEFAULT(); stable)
    end
end

function quadratize!(aux, f::AbstractPBF, quad::Quadratization{INFER})
    quadratize!(aux, f, infer_quadratization(f, quad.stable))

    return f
end

function quadratize!(::Function, f::AbstractPBF, ::Nothing)
    return f
end

function quadratize!(f::AbstractPBF, quad::Union{Quadratization,Nothing} = Quadratization(INFER()))
    return quadratize!(auxgen(f), f, quad)
end

function quadratize(aux, f::AbstractPBF, quad::Union{Quadratization,Nothing} = Quadratization(INFER()))
    return quadratize!(aux, copy(f), quad)
end

function quadratize(f::AbstractPBF, quad::Union{Quadratization,Nothing} = Quadratization(INFER()))
    return quadratize!(copy(f), quad)
end
