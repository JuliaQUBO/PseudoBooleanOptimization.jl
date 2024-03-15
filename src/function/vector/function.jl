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
