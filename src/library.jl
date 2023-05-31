function sortedmergewith(combine, u::AbstractVector{T}, v::AbstractVector{T}; lt = isless) where {T}
    m = length(u)
    n = length(v)
    w = Vector{T}(undef, m + n)
    i = 1
    j = 1
    k = 1

    while i <= m && j <= n
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

    while i <= m
        w[k] = u[i]
        k += 1
        i += 1
    end

    while j <= n
        w[k] = v[j]
        k += 1
        j += 1
    end

    return resize!(w, k - 1)
end

function sortedmergewith(u::AbstractVector{T}, v::AbstractVector{T}; lt = isless) where {T}
    return sortedmergewith(coalesce, u, v; lt)
end

# Relaxed Greatest Common Divisor 
@doc raw"""
    relaxedgcd(x::T, y::T; tol::T = T(1e-6)) where {T}

We define two real numbers ``x`` and ``y`` to be ``\tau``-comensurable if, for some ``\tau > 0`` there exists a continued fractions convergent ``p_{k} \div q_{k}`` such that

```math
    \left| {q_{k} x - p_{k} y} \right| \le \tau
```
"""
function relaxedgcd(x::T, y::T; tol::T = 1e-6) where {T}
    x_ = abs(x)
    y_ = abs(y)

    if x_ < y_
        return relaxedgcd(y_, x_; tol)::T
    elseif y_ < tol
        return x_
    elseif x_ < tol
        return y_
    else
        return (x_ / numerator(rationalize(x_ / y_; tol)))::T
    end
end

function relaxedgcd(a::AbstractArray{T}; tol::T = 1e-6) where {T}
    if length(a) == 0
        return one(T)
    elseif length(a) == 1
        return first(a)
    else
        return reduce((x, y) -> relaxedgcd(x, y; tol), a)
    end
end

function _subscript(i::Integer)
    if i < 0
        return "₋$(_subscript(abs(i)))"
    else
        return join(reverse(digits(i)) .+ Char(0x2080))
    end
end

function _swaprows!(x::AbstractArray, i::Integer, j::Integer)
    x[i,:], x[j,:] .= (x[j,:], x[i,:])

    return nothing
end

function _mod2_numsolutions(_A::AbstractMatrix{U}, _b::AbstractVector{U}) where {U<:Integer}
    A, b = _mod2_elimination(_A, _b)
    m, n = size(A)

    # start with full rank
    rank = m

    for i in 1:m
        if iszero(A[i,:])    # all-zero row encountered
            if !iszero(b[i]) # no solutions
                return 0
            end

            rank -= 1
        end
    end

    return 2 ^ (n - rank)
end

function _mod2_elimination(_A::AbstractMatrix{U}, _b::AbstractVector{U}) where {U<:Integer}
    A = copy(_A)
    b = copy(_b)

    m, n = size(A)

    i = 1
    j = 1

    while i <= m && j <= n
        max_i = i

        for l = i:m
            if A[l, j] == 1
                max_i = l
                break
            end
        end

        if A[max_i, j] == 0
            j += 1
        else
            if i != max_i
                _swaprows!(A, i, max_i)
                _swaprows!(b, i, max_i)
            end

            for u in (i+1):m
                A[u,:] .⊻= A[u,j] .& A[i,:]
                b[u]    ⊻= A[u,j] & b[i]
            end

            i += 1
            j += 1
        end
    end

    return (A, b)
end