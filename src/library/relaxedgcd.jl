# Relaxed Greatest Common Divisor 
@doc raw"""
    relaxedgcd(x::T, y::T; tol::T = T(1E-6)) where {T}

We define two real numbers ``x`` and ``y`` to be ``\tau``-comensurable if,
for some ``\tau > 0`` there exists a continued fractions convergent
``p_{k} \div q_{k}`` such that

```math
    \left| {q_{k} x - p_{k} y} \right| \le \tau
```
"""
function relaxedgcd end

function relaxedgcd(x::T, y::T; tol::T = T(1E-6)) where {T}
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
