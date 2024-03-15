#  Arithmetic: (+)
function Base.:(+)(f::VectorFunction{V,T}, g::VectorFunction{V,T}) where {V,T}
    return VectorFunction{V,T}(sortedmergewith(+, f, g; lt = varlt), true)
end

function Base.:(+)(f::VectorFunction{V,T}, c::T) where {V,T}
    g = copy(f)

    g[nothing] += c
    
    return g
end

Base.:(+)(f::VectorFunction{V,T}, c) where {V,T} = +(f, convert(T, c))
Base.:(+)(c, f::VectorFunction)                  = +(f, c)

#  Arithmetic: (-) 
function Base.:(-)(f::VectorFunction{V,T}) where {V,T}
    return VectorFunction{V,T}(Dict{Set{S},T}(ω => -c for (ω, c) in f))
end

function Base.:(-)(f::VectorFunction{V,T}, g::VectorFunction{V,T}) where {V,T}
    h = copy(f)

    for (ω, c) in g
        h[ω] -= c
    end

    return h
end

function Base.:(-)(f::VectorFunction{V,T}, c::T) where {V,T}
    if iszero(c)
        copy(f)
    else
        g = copy(f)

        g[nothing] -= c

        return g
    end
end

function Base.:(-)(c::T, f::VectorFunction{V,T}) where {V,T}
    g = -f

    if !iszero(c)
        g[nothing] += c
    end

    return g
end

Base.:(-)(c, f::VectorFunction{V,T}) where {V,T} = -(convert(T, c), f)
Base.:(-)(f::VectorFunction{V,T}, c) where {V,T} = -(f, convert(T, c))

#  Arithmetic: (*) 
function Base.:(*)(f::VectorFunction{V,T}, g::VectorFunction{V,T}) where {V,T}
    h = zero(VectorFunction{V,T})
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

function Base.:(*)(f::VectorFunction{V,T}, a::T) where {V,T}
    if iszero(a)
        return VectorFunction{V,T}()
    else
        return VectorFunction{V,T}(ω => c * a for (ω, c) ∈ f)
    end
end

Base.:(*)(f::VectorFunction{V,T}, a) where {V,T} = *(f, convert(T, a))
Base.:(*)(a, f::VectorFunction)                  = *(f, a)

#  Arithmetic: (/) 
function Base.:(/)(f::VectorFunction{V,T}, a::T) where {V,T}
    if iszero(a)
        throw(DivideError())
    else
        return VectorFunction{V,T}(Dict(ω => c / a for (ω, c) in f))
    end
end

Base.:(/)(f::VectorFunction{V,T}, a) where {V,T} = /(f, convert(T, a))

#  Arithmetic: (^) 
function Base.:(^)(f::VectorFunction{V,T}, n::Integer) where {V,T}
    if n < 0
        throw(DivideError())
    elseif n == 0
        return one(VectorFunction{V,T})
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
function (f::VectorFunction{V,T})(x::Dict{S,U}) where {V,T,U<:Integer}
    g = VectorFunction{V,T}()

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

function (f::VectorFunction{V,T})(η::Set{S}) where {V,T}
    return sum(c for (ω, c) in f if ω ⊆ η; init = zero(T))
end

function (f::VectorFunction{S})(x::Pair{S,U}...) where {S,U<:Integer}
    return f(Dict{S,U}(x...))
end

function (f::VectorFunction{S})() where {S}
    return f(Dict{S,Int}())
end