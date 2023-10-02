# Fallback implementation of varmap for types that do not implement it
function varmap(::Type{V}, i::Integer) where {V}
    return V(i)
end

function varmap(::Type{V}, i::Integer, x::AbstractString = "x") where {V<:AbstractString}
    return V("$(x)_$(i)")
end

function varmap(::Type{Symbol}, i::Integer, x::Symbol = :x)
    return Symbol("$(x)_$(i)")
end
