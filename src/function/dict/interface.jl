function degree(f::DictFunction)
    return maximum(length.(keys(f)); init = 0)
end

function lowerbound(f::DictFunction{V,T}) where {V,T}
    return sum(c < zero(T) || isempty(ω) ? c : zero(T) for (ω, c) in f)
end

function upperbound(f::DictFunction{V,T}) where {V,T}
    return sum(c > zero(T) || isempty(ω) ? c : zero(T) for (ω, c) in f)
end

# TODO: See [1] sec 5.1.1 Majorization
function maxgap(f::DictFunction{V,T}) where {V,T}
    return sum(abs(c) for (ω, c) in f if !isempty(ω); init = zero(T))
end

# TODO: How to name it properly
function mingap(f::DictFunction{V,T}; tol::T = 1E-6) where {V,T}
    return relaxedgcd(values(f); tol)::T # || one(T)
end

function discretize!(f::DictFunction{V,T}; tol::T = 1E-6) where {V,T}
    ε = mingap(f; tol)

    for (ω, c) in f
        f[ω] = round(c / ε; digits = 0)
    end

    return f
end

function derivative(f::DictFunction{V,T}, x::V) where {V,T}
    return DictFunction{V,T}(ω => f[ω×x] for ω ∈ keys(f) if (x ∉ ω))
end

function residual(f::DictFunction{V,T}, x::V) where {V,T}
    return DictFunction{V,T}(ω => c for (ω, c) ∈ f if (x ∉ ω))
end
