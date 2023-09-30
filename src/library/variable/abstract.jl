varlt(u::V, v::V) where {V}         = isless(u, v) # fallback
varlt(u::V, v::V) where {V<:Symbol} = varlt(string(u), string(v))

function varlt(u::V, v::V) where {V<:Signed}
    # For signed integers, the order should be as follows:
    # 0, 1, 2, 3, ..., -1, -2, -3, ...
    if sign(u) == sign(v)
        return v < u
    else
        return sign(u) < sign(v)
    end
end

function varlt(u::V, v::V) where {V<:AbstractString}
    if length(u) == length(v)
        return u < v
    else
        return length(u) < length(v)
    end
end

function varlt(u::AbstractVector{V}, v::AbstractVector{V}) where {V}
    if length(u) == length(v)
        # Vectors are assumed to be sorted!
        # @assert issorted(u) && issorted(v)
        @inbounds for i in eachindex(u)
            if varlt(u[i], v[i])
                return true
            elseif varlt(v[i], u[i])
                return false
            else
                continue
            end
        end
    else
        return length(u) < length(v)
    end
end

function varlt(u::Set{V}, v::Set{V}) where {V}
    if length(u) == length(v)
        x = sort!(collect(u); alg = InsertionSort, lt = varlt)
        y = sort!(collect(v); alg = InsertionSort, lt = varlt)

        return varlt(x, y)
    else
        return length(u) < length(v)
    end
end


function varmul(u::Set{V}, v::Set{V}) where {V}
    return u ∪ v
end

function varmul(u::V, v::Set{V}) where {V}
    return u ∪ v
end

function varmul(u::Set{V}, v::V) where {V}
    return u ∪ v
end

function varmul(u::V, v::V) where {V}
    return Set{V}([u, v])
end

function varmul(u::AbstractVector{V}, v::AbstractVector{V}) where {V}
    # Vectors are assumed to be sorted!
    # @assert issorted(u) && issorted(v)
    return sortedmergewith(u, v; lt = varlt)
end


varshow(io::IO, v::V) where {V}                       = show(io, varshow(v))
varshow(v::Integer)                                   = "x$(_subscript(v))"
varshow(v::V) where {V<:Union{Symbol,AbstractString}} = string(v)
