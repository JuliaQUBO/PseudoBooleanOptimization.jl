# Fallback implementation
function varmap(::Type{V}, i::Integer) where {V}
    return V(i)
end

function varmap(::Type{V}, i::Integer) where {V<:Union{AbstractString,Symbol}}
    return V("x$(_subscript(i))")
end
