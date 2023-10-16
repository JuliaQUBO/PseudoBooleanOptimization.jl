function sortedmergewith(
    combine,
    u::AbstractVector{T},
    v::AbstractVector{T};
    lt = isless,
) where {T}
    m = length(u)
    n = length(v)
    w = Vector{T}(undef, m + n)
    i = 1
    j = 1
    k = 1

    @inbounds while i <= m && j <= n
        if lt(u[i], v[j])
            w[k] = u[i]
            k += 1
            i += 1
        elseif lt(v[j], u[i])
            w[k] = v[j]
            k += 1
            j += 1
        else
            w[k] = combine(u[i], v[j])
            k += 1
            i += 1
            j += 1
        end
    end

    @inbounds while i <= m
        w[k] = u[i]
        k += 1
        i += 1
    end

    @inbounds while j <= n
        w[k] = v[j]
        k += 1
        j += 1
    end

    return resize!(w, k - 1)
end

function sortedmergewith(u::AbstractVector{T}, v::AbstractVector{T}; lt = isless) where {T}
    return sortedmergewith(coalesce, u, v; lt)
end
