# Fallback implementation
function varmap(::Type{V}, i::Integer) where {V}
    return V(i)
end

function varmap(::Type{V}, i::Integer) where {V<:Union{AbstractString,Symbol}}
    if i >= 0
        return V("var_$(i)")
    else
        return V("aux_$(-i)")
    end
end
