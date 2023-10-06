struct VariableGenerator{V}
    counter::Ref{Int}
    step::Int

    function VariableGenerator{V}(start::Integer, step::Integer) where {V}
        return new{V}(Ref(start), step)
    end
end

function VariableGenerator(::Type{V}; start::Integer = 1, step::Integer = 1) where {V}
    return VariableGenerator{V}(start, step)
end

function __next(vg::VariableGenerator{V}) where {V}
    i = vg.counter[]

    vg.counter[] += vg.step

    return varmap(V, i)
end

function vargen(::Type{V}; start::Integer = 1, step::Integer = 1) where {V}
    vg = VariableGenerator{V}(start, step)

    return (n::Union{Integer,Nothing} = nothing) -> begin
        if isnothing(n)
            return __next(vg)::V
        else
            return [__next(vg) for _ = 1:n]::Vector{V}
        end
    end
end

function vargen(::AbstractPBF{V}; start::Integer = 1, step::Integer = 1) where {V}
    return vargen(V; start, step)
end
