function bounds(f::AbstractFunction)
    return (lowerbound(f), upperbound(f))
end

function discretize(f::AbstractFunction{V,T}; tol::T = 1E-6) where {V,T}
    return discretize!(copy(f); tol)
end

function gradient(f::AbstractFunction{V,T}, x::Vector{V}) where {V,T}
    return [derivative(f, xi) for xi in x]
end

function maxgap(f::F) where {V,T,F<:AbstractFunction{V,T}}
    return sum(abs(c) for (ω, c) in f if !isempty(ω); init = zero(T))
end

function mingap(f::F; tol::T = 1E-6) where {V,T,F<:AbstractFunction{V,T}}
    return relaxedgcd(collect(values(f)); tol)::T
end

function lowerbound(f::F) where {V,T,F<:AbstractFunction{V,T}}
    return sum((c < zero(T) || isempty(ω)) ? c : zero(T) for (ω, c) in f)
end

function upperbound(f::F) where {V,T,F<:AbstractFunction{V,T}}
    return sum((c > zero(T) || isempty(ω)) ? c : zero(T) for (ω, c) in f)
end

function Base.convert(::Type{U}, f::AbstractFunction{V,T}) where {V,T,U<:T}
    if isempty(f)
        return zero(U)
    elseif degree(f) == 0
        return convert(U, f[nothing])
    else
        error("Can't convert non-constant pseudo-Boolean function to scalar type '$U'")
    end
end
