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
