@doc raw"""
    Term{V}

Reference implementation for [`AbstractTerm`](@ref).
"""
struct Term{V} <: AbstractTerm{V}
    ω::Vector{V}

    # Constructors - I know what I am doing
    function Term{V}(ω::Vector{V}) where {V}
        return new{V}(ω)
    end

    # Constructors - Empty
    function Term{V}() where {V}
        return new{V}(Vector{V}())
    end

    # Constructors - Vector/Set/Tuple
    function Term(ω::X) where {V,N,X<:Union{AbstractVector{V},AbstractSet{V},NTuple{N,V}}}
        return new{V}(sortunique!(collect(ω); alg = InsertionSort, lt = varlt))
    end
end

function Base.isempty(t::Term{V}) where {V}
    return isempty(t.ω)
end

function Base.length(t::Term{V}) where {V}
    return length(t.ω)
end

function Base.iterate(t::Term{V}) where {V}
    return iterate(t.ω)
end

function Base.iterate(t::Term{V}, i) where {V}
    return iterate(t.ω, i)
end

function Base.eltype(::Term{V}) where {V}
    return V
end

function Base.:(==)(u::Term{V}, v::Term{V}) where {V}
    return u.ω == v.ω
end

function Base.hash(t::Term{V}) where {V}
    return hash(t.ω)
end

function Base.hash(t::Term{V}, h::Integer) where {V}
    return hash(t.ω, h)
end

function varlt(u::Term{V}, v::Term{V}) where {V}
    return varlt(u.ω, v.ω)
end

function varmul(u::Term{V}, v::Term{V}) where {V}
    return Term{V}(sortedmergewith(u.ω, v.ω))
end

function varmul(u::Term{V}, v::V) where {V}
    return Term{V}(sortedmergewith(u.ω, V[v]))
end

function varmul(u::V, v::Term{V}) where {V}
    return Term{V}(sortedmergewith(V[u], v.ω))
end

function varmul(u::V, v::V) where {V}
    if varlt(u, v)
        return Term{V}([u, v])
    else
        return Term{V}([v, u])
    end
end

function varshow(t::Term{V}) where {V}
    return join(varshow.(t), " ")
end
