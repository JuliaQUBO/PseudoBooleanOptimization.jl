const TermKey{V} = Union{AbstractVector{V},AbstractSet{V},Tuple{Vararg{V}}}

@doc raw"""
    Term{V,T} <: AbstractTerm{V,T}
"""
struct Term{V,T} <: AbstractTerm{V,T}
    ω::Vector{V}
    c::T

    # standard constructor
    function Term{V,T}(x::K,c::T) where {V,T,K<:TermKey{V}}
        ω = unique!(sort!(collect(x); alg = InsertionSort, lt = varlt))

        return new{V,T}(ω, c)
    end

    # shortcut: fast-track
    function Term{V,T}(x::K,c::T,::Nothing) where {V,T,K<:TermKey{V}}
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

function Term{V,T}((ω, c)::Pair{K,T}) where {V,T,K<:Union{AbstractVector{V},AbstractSet{V},Tuple{Vararg{V}}}}
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
    return sortedmergewith(u, v; lt=varlt)
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
