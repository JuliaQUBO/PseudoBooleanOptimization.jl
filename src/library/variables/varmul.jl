function varmul(u::Set{V}, v::Set{V}) where {V}
    return u ∪ v
end

function varmul(u::V, v::Set{V}) where {V}
    return push!(copy(u), v)
end

function varmul(u::Set{V}, v::V) where {V}
    return push!(copy(u), v)
end

function varmul(u::V, v::V) where {V}
    if varlt(u, v)
        return (u, v)
    else
        return (v, u)
    end
end

function varmul(u::AbstractVector{V}, v::AbstractVector{V}) where {V}
    # Vectors are assumed to be sorted!
    # @assert issorted(u) && issorted(v)
    return sortedmergewith(u, v; lt = varlt)
end
