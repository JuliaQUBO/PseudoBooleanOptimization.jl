#  Comparison: (==)
Base.:(==)(f::PBF{S,T}, g::PBF{S,T}) where {S,T} = f.Ω == g.Ω
Base.:(==)(f::PBF{S,T}, a::T) where {S,T}        = isscalar(f) && (f[nothing] == a)

function Base.isapprox(f::PBF{S,T}, g::PBF{S,T}; kw...) where {S,T}
    return (length(f) == length(g)) &&
           all(haskey(g, ω) && isapprox(g[ω], f[ω]; kw...) for ω in keys(f))
end

function Base.isapprox(f::PBF{S,T}, a::T; kw...) where {S,T}
    return isscalar(f) && isapprox(f[nothing], a; kw...)
end

function isscalar(f::PBF{S}) where {S}
    return isempty(f) || (length(f) == 1 && haskey(f, nothing))
end

Base.zero(::Type{PBF{S,T}}) where {S,T}    = PBF{S,T}()
Base.iszero(f::PBF)                        = isempty(f)
Base.one(::Type{PBF{S,T}}) where {S,T}     = PBF{S,T}(one(T))
Base.isone(f::PBF)                         = isscalar(f) && isone(f[nothing])
Base.round(f::PBF{S,T}; kw...) where {S,T} = PBF{S,T}(ω => round(c; kw...) for (ω, c) in f)

#  Arithmetic: (+) 
function Base.:(+)(f::PBF{S,T}, g::PBF{S,T}) where {S,T}
    h = copy(f)

    for (ω, c) in g
        h[ω] += c
    end

    return h
end

function Base.:(+)(f::PBF{S,T}, c::T) where {S,T}
    if iszero(c)
        copy(f)
    else
        g = copy(f)

        g[nothing] += c

        return g
    end
end

Base.:(+)(f::PBF{S,T}, c) where {S,T} = +(f, convert(T, c))
Base.:(+)(c, f::PBF)                  = +(f, c)

#  Arithmetic: (-) 
function Base.:(-)(f::PBF{S,T}) where {S,T}
    return PBF{S,T}(Dict{Set{S},T}(ω => -c for (ω, c) in f))
end

function Base.:(-)(f::PBF{S,T}, g::PBF{S,T}) where {S,T}
    h = copy(f)

    for (ω, c) in g
        h[ω] -= c
    end

    return h
end

function Base.:(-)(f::PBF{S,T}, c::T) where {S,T}
    if iszero(c)
        copy(f)
    else
        g = copy(f)

        g[nothing] -= c

        return g
    end
end

function Base.:(-)(c::T, f::PBF{S,T}) where {S,T}
    g = -f

    if !iszero(c)
        g[nothing] += c
    end

    return g
end

Base.:(-)(c, f::PBF{S,T}) where {S,T} = -(convert(T, c), f)
Base.:(-)(f::PBF{S,T}, c) where {S,T} = -(f, convert(T, c))

#  Arithmetic: (*) 
function Base.:(*)(f::PBF{S,T}, g::PBF{S,T}) where {S,T}
    h = zero(PBF{S,T})
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

function Base.:(*)(f::PBF{S,T}, a::T) where {S,T}
    if iszero(a)
        return PBF{S,T}()
    else
        return PBF{S,T}(ω => c * a for (ω, c) ∈ f)
    end
end

Base.:(*)(f::PBF{S,T}, a) where {S,T} = *(f, convert(T, a))
Base.:(*)(a, f::PBF)                  = *(f, a)

#  Arithmetic: (/) 
function Base.:(/)(f::PBF{S,T}, a::T) where {S,T}
    if iszero(a)
        throw(DivideError())
    else
        return PBF{S,T}(Dict(ω => c / a for (ω, c) in f))
    end
end

Base.:(/)(f::PBF{S,T}, a) where {S,T} = /(f, convert(T, a))

#  Arithmetic: (^) 
function Base.:(^)(f::PBF{S,T}, n::Integer) where {S,T}
    if n < 0
        throw(DivideError())
    elseif n == 0
        return one(PBF{S,T})
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
function (f::PBF{S,T})(x::Dict{S,U}) where {S,T,U<:Integer}
    g = PBF{S,T}()

    for (ω, c) in f
        η = Set{S}()

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

function (f::PBF{S,T})(η::Set{S}) where {S,T}
    return sum(c for (ω, c) in f if ω ⊆ η; init = zero(T))
end

function (f::PBF{S})(x::Pair{S,U}...) where {S,U<:Integer}
    return f(Dict{S,U}(x...))
end

function (f::PBF{S})() where {S}
    return f(Dict{S,Int}())
end