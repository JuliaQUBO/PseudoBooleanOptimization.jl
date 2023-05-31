#  Comparison: (==)
Base.:(==)(f::DictFunction{V,T}, g::DictFunction{V,T}) where {V,T} = (f.Ω == g.Ω)

function Base.isapprox(f::DictFunction{V,T}, g::DictFunction{V,T}; kw...) where {V,T}
    return (length(f) == length(g)) && all(haskey(g, ω) && isapprox(g[ω], f[ω]; kw...) for ω in keys(f))
end

function isscalar(f::DictFunction)
    return isempty(f) || (length(f) == 1 && haskey(f, nothing))
end

Base.zero(::Type{DictFunction{V,T}}) where {V,T}    = DictFunction{V,T}()
Base.iszero(f::DictFunction)                        = isempty(f)
Base.one(::Type{DictFunction{V,T}}) where {V,T}     = DictFunction{V,T}(one(T))
Base.isone(f::DictFunction)                         = isscalar(f) && isone(f[nothing])
Base.round(f::DictFunction{V,T}; kw...) where {V,T} = DictFunction{V,T}(ω => round(c; kw...) for (ω, c) in f)

#  Arithmetic: (+) 
function Base.:(+)(f::DictFunction{V,T}, g::DictFunction{V,T}) where {V,T}
    h = copy(f)

    for (ω, c) in g
        h[ω] += c
    end

    return h
end

function Base.:(+)(f::DictFunction{V,T}, c::T) where {V,T}
    if iszero(c)
        copy(f)
    else
        g = copy(f)

        g[nothing] += c

        return g
    end
end

Base.:(+)(f::DictFunction{V,T}, c) where {V,T} = +(f, convert(T, c))
Base.:(+)(c, f::DictFunction)                  = +(f, c)

#  Arithmetic: (-) 
function Base.:(-)(f::DictFunction{V,T}) where {V,T}
    return DictFunction{V,T}(Dict{Set{V},T}(ω => -c for (ω, c) in f))
end

function Base.:(-)(f::DictFunction{V,T}, g::DictFunction{V,T}) where {V,T}
    h = copy(f)

    for (ω, c) in g
        h[ω] -= c
    end

    return h
end

function Base.:(-)(f::DictFunction{V,T}, c::T) where {V,T}
    if iszero(c)
        copy(f)
    else
        g = copy(f)

        g[nothing] -= c

        return g
    end
end

function Base.:(-)(c::T, f::DictFunction{V,T}) where {V,T}
    g = -f

    if !iszero(c)
        g[nothing] += c
    end

    return g
end

Base.:(-)(c, f::DictFunction{V,T}) where {V,T} = -(convert(T, c), f)
Base.:(-)(f::DictFunction{V,T}, c) where {V,T} = -(f, convert(T, c))

#  Arithmetic: (*) 
function Base.:(*)(f::DictFunction{V,T}, g::DictFunction{V,T}) where {V,T}
    h = zero(DictFunction{V,T})
    m = length(f)
    n = length(g)

    if iszero(f) || iszero(g) # T(n) = O(1)
        return h
    elseif f === g # T(n) = O(n) + O(n^2 / 2)
        k = collect(f)

        sizehint!(h, n^2 ÷ 2)

        for i = 1:n
            ωi, ci = k[i]

            h[ωi] += ci * ci

            for j = (i+1):n
                ωj, cj = k[j]

                h[union(ωi, ωj)] += 2 * ci * cj
            end
        end

        return h
    else # T(n) = O(m n)
        sizehint!(h, m * n)

        for (ωᵢ, cᵢ) in f, (ωⱼ, cⱼ) in g
            h[union(ωᵢ, ωⱼ)] += cᵢ * cⱼ
        end

        return h
    end
end

function Base.:(*)(f::DictFunction{V,T}, a::T) where {V,T}
    if iszero(a)
        return DictFunction{V,T}()
    else
        return DictFunction{V,T}(ω => c * a for (ω, c) ∈ f)
    end
end

Base.:(*)(f::DictFunction{V,T}, a) where {V,T} = *(f, convert(T, a))
Base.:(*)(a, f::DictFunction)                  = *(f, a)

#  Arithmetic: (/) 
function Base.:(/)(f::DictFunction{V,T}, a::T) where {V,T}
    if iszero(a)
        throw(DivideError())
    else
        return DictFunction{V,T}(Dict(ω => c / a for (ω, c) in f))
    end
end

Base.:(/)(f::DictFunction{V,T}, a) where {V,T} = /(f, convert(T, a))

#  Arithmetic: (^) 
function Base.:(^)(f::DictFunction{V,T}, n::Integer) where {V,T}
    if n < 0
        throw(DivideError())
    elseif n == 0
        return one(DictFunction{V,T})
    elseif n == 1
        return copy(f)
    elseif n == 2
        return f * f
    else
        g = f * f

        if iseven(n)
            return g^(n ÷ 2)
        else
            return g^(n ÷ 2) * f
        end
    end
end

#  Arithmetic: Evaluation 
function (f::DictFunction{V,T})(x::Dict{V,U}) where {V,T,U<:Integer}
    g = DictFunction{V,T}()

    for (ω, c) in f
        η = Set{V}()

        for j in ω
            if haskey(x, j)
                if iszero(x[j])
                    c = zero(T)
                    break
                end
            else
                push!(η, j)
            end
        end

        g[η] += c
    end

    return g
end

function (f::DictFunction{V,T})(η::Set{V}) where {V,T}
    return sum(c for (ω, c) in f if ω ⊆ η; init = zero(T))
end

function (f::DictFunction{V})(x::Pair{V,U}...) where {V,U<:Integer}
    return f(Dict{V,U}(x...))
end

function (f::DictFunction{V})() where {V}
    return f(Dict{V,Int}())
end
