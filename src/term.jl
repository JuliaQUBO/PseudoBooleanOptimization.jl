@doc raw"""
    Term{V,T} <: AbstractTerm{V,T}
"""
struct Term{V,T} <: AbstractTerm{V,T}
    ω::Vector{V}
    c::T

    # standard constructor
    function Term{V,T}(x::K, c::T) where {V,T,K<:Union{AbstractVector{V},AbstractSet{V}}}
        ω = unique!(sort!(collect(x); alg=InsertionSort, lt=varlt))

        return new{V,T}(ω, c)
    end

    # short-cut: zero
    Term{V,T}() where {V,T} = new{V,T}(V[], zero(T))
    
    # short-cut: one
    Term{V,T}(::Nothing) where {V,T} = new{V,T}(V[], one(T))

    # short-cut: constant
    Term{V,T}(c::T) where {V,T} = new{V,T}(V[], c)

    # short-cut: variable
    Term{V,T}(v::V) where {V,T} = new{V,T}(V[v], one(T))

    # short-cut: monomial
    Term{V,T}(v::V, c::T) where {V,T} = new{V,T}(V[v], c)
    
    # short-cut: fallback error
    Term{V,T}(x::Any) where {V,T} = error("Invalid term '$(x)'")
end

const PBT{V,T} = Term{V,T}

function PBT{V,T}(ω::K) where {V,T,K<:Union{AbstractVector{V},AbstractSet{V}}}
    return PBT{V,T}(ω, one(T))
end

function PBT{V,T}((_,c)::Pair{Nothing,T}) where {V,T}
    return PBT{V,T}(c)
end

function PBT{V,T}((_,c)::Tuple{Nothing,T}) where {V,T}
    return PBT{V,T}(c)
end

function PBT{V,T}((v,c)::Pair{V,T}) where {V,T}
    return PBT{V,T}(v,c)
end

function PBT{V,T}((ω,c)::Pair{K,T}) where {V,T,K<:Union{AbstractVector{V},AbstractSet{V}}}
    return PBT{V,T}(ω, c)
end

varlt(u::Term{V,T}, v::Term{V,T}) where {V,T} = varlt(u.ω, v.ω)
