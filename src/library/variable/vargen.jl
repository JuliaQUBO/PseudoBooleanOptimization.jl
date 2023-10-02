function auxgen(::AbstractPBF{Symbol,T}; name::Symbol = :aux) where {T}
    counter = Ref{Int}(0)

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
    counter = Ref{Int}(0)

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
