function _colwise_shuffle!(rng, x::AbstractMatrix{U}) where {U<:Integer}
    n = size(x, 2)

    @inbounds for j = 1:n
        shuffle!(rng, @view(x[:, j]))
    end

    return x
end

function _rowwise_allunique(
    x::AbstractMatrix{U},
    u::Vector{S},
) where {U<:Integer,S<:Integer}
    m, n = size(x)

    for i = 1:m
        u .= zero(S)

        for j = 1:n
            k = x[i, j]

            if isone(u[k])
                return false
            else
                u[k] = one(S)
            end
        end
    end

    return true
end

function _swaprows!(x::AbstractMatrix, i::Integer, j::Integer)
    n = size(x, 2)

    @inbounds for k = 1:n
        x[i, k], x[j, k] = (x[j, k], x[i, k])
    end

    return nothing
end

function _swaprows!(x::AbstractVector, i::Integer, j::Integer)
    x[i], x[j] = (x[j], x[i])

    return nothing
end

function _mod2_numsolutions!(A::AbstractMatrix{U}, b::AbstractVector{U}) where {U<:Integer}
    _mod2_elimination!(A, b)

    m, n = size(A)

    # start with full rank
    rank = m

    @inbounds for i = 1:m
        if iszero(@view(A[i, :])) # all-zero row encountered
            if !iszero(b[i])     # no solutions
                return 0
            end

            rank -= 1
        end
    end

    return 2^(n - rank)
end

function _mod2_elimination!(A::AbstractMatrix{U}, b::AbstractVector{U}) where {U<:Integer}
    m, n = size(A)

    i = 1
    j = 1

    @inbounds while i <= m && j <= n
        pivot = i

        for l = i:m
            if A[l, j] == 1
                pivot = l
                break
            end
        end

        if A[pivot, j] == 0
            j += 1
            continue
        end

        if i != pivot
            _swaprows!(A, i, pivot)
            _swaprows!(b, i, pivot)
        end

        for k = (i+1):m
            for l = 1:n
                A[k, l] ⊻= A[k, j] & A[i, l]
            end

            b[k] ⊻= A[k, j] & b[i]
        end

        i += 1
        j += 1
    end

    return nothing
end
