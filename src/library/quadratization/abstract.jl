@doc raw"""
    Quadratization{DEFAULT}(stable::Bool = false)

Employs other methods, specifically [`NTR_KZFD`](@ref) and [`PTR_BG`](@ref).
"""
struct DEFAULT <: QuadratizationMethod end

function quadratize!(
    aux,
    f::PBF{V,T},
    ω::Set{V},
    c::T,
    quad::Quadratization{DEFAULT},
) where {V,T}
    if c < zero(T)
        quadratize!(aux, f, ω, c, Quadratization{NTR_KZFD}(quad.stable))
    else
        quadratize!(aux, f, ω, c, Quadratization{PTR_BG}(quad.stable))
    end

    return f
end

function quadratize!(
    aux,
    f::PBF{V,T},
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
    infer_quadratization(f::PBF)

For a given PBF, returns whether it should be quadratized or not, based on its degree.
"""
function infer_quadratization(f::PBF, stable::Bool = false)
    k = degree(f)

    if k <= 2
        return nothing
    else
        # Without any extra knowledge, it is better to
        # quadratize using the default approach
        return Quadratization{DEFAULT}(stable)
    end
end

function quadratize!(aux, f::PBF, quad::Quadratization{INFER})
    quadratize!(aux, f, infer_quadratization(f, quad.stable))

    return f
end

function quadratize!(::Function, f::PBF, ::Nothing)
    return f
end

@doc raw"""
    auxgen(::AbstractPBF{V,T}; name::AbstractString = "aux") where {V<:AbstractString,T}

Creates a function that, when called multiple times, returns the strings `"aux_1"`, `"aux_2"`, ... and so on.

    auxgen(::AbstractPBF{Symbol,T}; name::Symbol = :aux) where {T}

Creates a function that, when called multiple times, returns the symbols `:aux_1`, `:aux_2`, ... and so on.

    auxgen(::AbstractPBF{V,T}; start::V = V(0), step::V = V(-1)) where {V<:Integer,T}

Creates a function that, when called multiple times, returns the integers ``-1``, ``-2``, ... and so on.
"""
function auxgen end

function auxgen(::AbstractPBF{Symbol,T}; name::Symbol = :aux) where {T}
    counter = Int[0]

    function aux(n::Union{Integer,Nothing} = nothing)
        if isnothing(n)
            return first(aux(1))
        else
            return [Symbol("$(name)_$(counter[] += 1)") for _ in 1:n]
        end
    end

    return aux
end

function auxgen(::AbstractPBF{V,T}; name::AbstractString = "aux") where {V<:AbstractString,T}
    counter = Int[0]

    function aux(n::Union{Integer,Nothing} = nothing)
        if isnothing(n)
            return first(aux(1))
        else
            return ["$(name)_$(counter[] += 1)" for _ in 1:n]
        end
    end

    return aux
end

function auxgen(::AbstractPBF{V,T}; start::V = V(0), step::V = V(-1)) where {V<:Integer,T}
    counter = [start]

    function aux(n::Union{Integer,Nothing} = nothing)
        if isnothing(n)
            return first(aux(1))
        else
            return [(counter[] += step) for _ in 1:n]
        end
    end

    return aux
end

function quadratize!(f::PBF, quad::Union{Quadratization,Nothing} = Quadratization{INFER})
    return quadratize!(auxgen(f), f, quad)
end

function quadratize(aux, f::PBF, quad::Union{Quadratization,Nothing} = Quadratization{INFER})
    return quadratize!(aux, copy(f), quad)
end

function quadratize(f::PBF, quad::Union{Quadratization,Nothing} = Quadratization{INFER})
    return quadratize!(copy(f), quad)
end
