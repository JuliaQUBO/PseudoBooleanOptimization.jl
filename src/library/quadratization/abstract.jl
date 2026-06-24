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

function _quadratize_with_solution!(
    f::AbstractPBF{V,T},
    solution::Dict{V,Int},
    quad::Union{Quadratization,Nothing},
) where {V,T}
    isnothing(quad) && return f

    terms = collect(f)

    quad.stable && sort!(terms; by = first, lt = varlt)

    aux = vargen(f; start = -1, step = -1)

    for (ω, c) in terms
        length(ω) > 2 || continue

        variables = _quadratization_auxiliaries!(aux, solution, ω, c, quad)

        term_aux = function (n::Union{Integer,Nothing} = nothing)
            if isnothing(n)
                @assert length(variables) == 1

                return only(variables)
            else
                @assert n == length(variables)

                return variables
            end
        end

        quadratize!(term_aux, f, ω, c, quad)
    end

    return f
end
