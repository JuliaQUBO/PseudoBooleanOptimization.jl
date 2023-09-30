@doc raw"""
    VectorFunction{V,T} <: AbstractPBF{V,T}
"""
struct VectorFunction{V,T} <: AbstractPBF{V,T}
    Ω::Vector{Term{V,T}}

    # standard constructor
    function VectorFunction{V,T}(v::AbstractVector{Term{V,T}}, ready::Bool = false) where {V,T}
        if ready
            Ω = v
        else
            Ω = sort!(filter(!iszero ∘ last, v); alg=QuickSort, lt=varlt)
        end

        return new{V,T}(Ω)
    end

    # heterogeneous list
    function VectorFunction{V,T}(x::AbstractVector) where {V,T}
        return VectorFunction{V,T}(Term{V,T}.(x))
    end

    # dictionary
    function VectorFunction{V,T}(x::AbstractDict) where {V,T}
        return VectorFunction{V,T}(Term{V,T}.(pairs(x)))
    end

    # fallback
    function VectorFunction{V,T}(x::Any) where {V,T}
        return VectorFunction{V,T}(Term{V,T}[Term{V,T}(x)])
    end
end

# Broadcast as scalar ?
Base.broadcastable(f::VectorFunction) = f

# Copy 
function Base.sizehint!(f::VectorFunction, n::Integer)
    sizehint!(f.Ω, n)

    return f
end

function Base.copy!(f::VectorFunction{V,T}, g::VectorFunction{V,T}) where {V,T}
    sizehint!(f, length(g))

    copy!(f.Ω, g.Ω)

    return f
end

function Base.copy(f::VectorFunction{V,T}) where {V,T}
    return copy!(VectorFunction{V,T}(), f)
end

#  Iterator & Length
Base.iterate(f::VectorFunction)             = iterate(f.Ω)
Base.iterate(f::VectorFunction, i::Integer) = iterate(f.Ω, i)

#  Properties 
Base.size(f::VectorFunction{V,T}) where {V,T} = (length(f),)

function Base.getindex(f::VectorFunction{V,T}, i::Integer) where {V,T}
    return getindex(f.Ω, i)
end

function Base.getindex(f::VectorFunction{V,T}, ::Nothing)
    if isempty(f) || !isempty(first(first(f)))
        return zero(T)
    else
        return last(first(f))
    end
end

function Base.getindex(f::VectorFunction{V,T}, v::Vector{V}) where {V,T}
    t = Term{V,T}(v)

    i = findsorted(f.Ω, t)

    return getindex(f.Ω, i)
end


const TermKey{V} = Union{AbstractVector{V},AbstractSet{V},Tuple{Vararg{V}}}

@doc raw"""
    Term{V,T} <: AbstractTerm{V,T}
"""
struct Term{V,T} <: AbstractTerm{V,T}
    ω::Vector{V}
    c::T

    # standard constructor
    function Term{V,T}(x::K, c::T) where {V,T,K<:TermKey{V}}
        ω = unique!(sort!(collect(x); alg = InsertionSort, lt = varlt))

        return new{V,T}(ω, c)
    end

    # shortcut: fast-track
    function Term{V,T}(x::K, c::T, ::Nothing) where {V,T,K<:TermKey{V}}
        return new{V,T}(x, c)
    end

    # shortcut: zero
    Term{V,T}() where {V,T} = new{V,T}(V[], zero(T))

    # shortcut: one
    Term{V,T}(::Nothing) where {V,T} = new{V,T}(V[], one(T))

    # shortcut: constant
    Term{V,T}(c::T) where {V,T} = new{V,T}(V[], c)

    # shortcut: variable
    Term{V,T}(v::V) where {V,T} = new{V,T}(V[v], one(T))

    # shortcut: monomial
    Term{V,T}(v::V, c::T) where {V,T} = new{V,T}(V[v], c)

    # shortcut: fallback error
    Term{V,T}(x::Any) where {V,T} = error("Invalid term '$(x)'")
end

function Term{V,T}(ω::K) where {V,T,K<:TermKey{V}}
    return Term{V,T}(ω, one(T))
end

function Term{V,T}((_, c)::Pair{Nothing,T}) where {V,T}
    return Term{V,T}(c)
end

function Term{V,T}((_, c)::Tuple{Nothing,T}) where {V,T}
    return Term{V,T}(c)
end

function Term{V,T}((v, c)::Pair{V,T}) where {V,T}
    return Term{V,T}(v, c)
end

function Term{V,T}(
    (ω, c)::Pair{K,T},
) where {V,T,K<:Union{AbstractVector{V},AbstractSet{V},Tuple{Vararg{V}}}}
    return Term{V,T}(ω, c)
end

function varlt(u::Term{V,T}, v::Term{V,T}) where {V,T}
    if length(u.ω) == length(v.ω)
        return varlt(u.ω, v.ω)
    else
        return isless(length(u.ω), length(v.ω))
    end
end

function varmul(u::Term{V,T}, v::Term{V,T}) where {V,T}
    return sortedmergewith(u, v; lt = varlt)
end

function Base.length(::Term)
    return 2
end

function Base.iterate(u::Term)
    return (first(u), 2)
end

function Base.iterate(u::Term, i::Integer)
    if i == 1
        return (first(u), 2)
    elseif i == 2
        return (last(u), 3)
    else
        return nothing
    end
end

function Base.first(u::Term)
    return u.ω
end

function Base.last(u::Term)
    return u.c
end

function Base.:(+)(u::Term{V,T}, v::Term{V,T}) where {V,T}
    @assert u.ω == v.ω

    return Term{V,T}(u.ω, u.c + v.c, true) # use fast-track
end

function Base.:(-)(u::Term{V,T}, v::Term{V,T}) where {V,T}
    @assert u.ω == v.ω

    return Term{V,T}(u.ω, u.c - v.c, true) # use fast-track
end

function Base.:(*)(u::Term{V,T}, c::T) where {V,T}
    return Term{V,T}(u.ω, u.c * c, true) # use fast-track
end

Base.:(*)(c::T, u::Term{V,T}) where {V,T} = u * c

function Base.:(*)(u::Term{V,T}, v::Term{V,T}) where {V,T}
    if u.ω == v.ω
        return Term{V,T}(u.ω, u.c * v.c, true) # use fast-track
    else
        return Term{V,T}(sortedmergewith(u.ω, v.ω; lt = varlt), u.c * v.c, true) # use fast-track
    end
end

Base.:(/)(u::Term{V,T}, c::T) where {V,T} = u * inv(c)

degree(t::Term) = length(first(t))

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

degree(f::VectorFunction) = degree(last(f))
