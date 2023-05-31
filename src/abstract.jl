function bounds(f::AbstractFunction)
    return (lowerbound(f), upperbound(f))
end

function discretize(f::AbstractFunction{V,T}; tol::T = 1E-6) where {V,T}
    return discretize!(copy(f); tol)
end

function gradient(f::AbstractFunction{V,T}, x::Vector{V}) where {V,T}
    return [derivative(f, xi) for xi in x]
end
