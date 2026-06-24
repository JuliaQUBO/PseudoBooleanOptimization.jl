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
        if length(ω) > 2
            quadratize!(aux, f, ω, c, quad)
        end
    end

    return f
end

function quadratize!(::Function, f::AbstractPBF, ::Nothing)
    return f
end

function quadratize!(f::AbstractPBF, quad::Union{Quadratization,Nothing} = Quadratization(DEFAULT()))
    return quadratize!(vargen(f; start = -1, step = -1), f, quad)
end

function quadratize(aux, f::AbstractPBF, quad::Union{Quadratization,Nothing} = Quadratization(DEFAULT()))
    return quadratize!(aux, copy(f), quad)
end

function quadratize(f::AbstractPBF, quad::Union{Quadratization,Nothing} = Quadratization(DEFAULT()))
    return quadratize!(copy(f), quad)
end

function _quadratization_auxiliaries!(
    aux,
    solution::Dict{V,Int},
    ω::AbstractTerm{V},
    c::T,
    quad::Quadratization,
) where {V,T}
    throw(
        ArgumentError(
            "Unsupported quadratization method $(typeof(quad.method)) for planted solution completion",
        ),
    )
end
