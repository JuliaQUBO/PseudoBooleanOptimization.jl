function degree(f::DictFunction)
    return maximum(length.(keys(f)); init = 0)
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
