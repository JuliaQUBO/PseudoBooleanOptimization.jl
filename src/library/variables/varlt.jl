varlt(u::V, v::V) where {V}         = isless(u, v) # fallback
varlt(u::V, v::V) where {V<:Symbol} = varlt(string(u), string(v))

function varlt(u::V, v::V) where {V<:Signed}
    # For signed integers, the order should be as follows:
    # 0, 1, 2, 3, ..., -1, -2, -3, ...
    if sign(u) == sign(v)
        return isless(abs(u), abs(v))
    elseif sign(u) >= 0 && sign(v) >= 0
        return isless(sign(u), sign(v))
    else
        return isless(sign(v), sign(u))
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
        return isless(length(u), length(v))
    end
end

function varlt(u::AbstractSet{V}, v::AbstractSet{V}) where {V}
    if length(u) == length(v)
        x = sort!(collect(u); alg = InsertionSort, lt = varlt)
        y = sort!(collect(v); alg = InsertionSort, lt = varlt)

        return varlt(x, y)
    else
        return isless(length(u), length(v))
    end
end
