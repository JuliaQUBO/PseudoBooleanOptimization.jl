@doc raw"""
    Function{V,T}() where {V,T}

A pseudo-Boolean Function[^Boros2002] ``f \in \mathscr{F}`` over some field ``\mathbb{T}`` takes the form

```math
f(\mathbf{x}) = \sum_{\omega \in \Omega\left[f\right]} c_\omega \prod_{j \in \omega} x_j
```

where each ``\Omega\left[{f}\right]`` is the multi-linear representation of ``f`` as a set of terms.
Each term is given by a unique set of indices ``\omega \subseteq \mathbb{S}`` related to some coefficient ``c_\omega \in \mathbb{T}``.
We say that ``\omega \in \Omega\left[{f}\right] \iff c_\omega \neq 0``.
Variables ``x_j`` are boolean, thus ``f : \mathbb{B}^{n} \to \mathbb{T}``.

[^Boros2002]:
    Endre Boros, Peter L. Hammer, **Pseudo-Boolean optimization**, *Discrete Applied Mathematics*, 2002 [{doi}](https://doi.org/10.1016/S0166-218X(01)00341-9)
"""
struct Function{V,T} <: AbstractFunction{V,T}
    Ω::Vector{PBT{V,T}}

    function Function{V,T}(X::AbstractVector{PBT{V,T}}) where {V,T}
        Ω = sort!(collect(X); lt=varlt)

        return new{V,T}(Ω)
    end
end

# Alias 
const PBF{V,T} = Function{V,T}

# Broadcast as scalar
Base.broadcastable(f::PBF) = Ref(f)

# Copy 
function Base.copy!(f::PBF{S,T}, g::PBF{S,T}) where {S,T}
    sizehint!(f, length(g))
    copy!(f.Ω, g.Ω)

    return f
end

function Base.copy(f::PBF{S,T}) where {S,T}
    return copy!(PBF{S,T}(), f)
end

#  Iterator & Length 
Base.keys(f::PBF)                = keys(f.Ω)
Base.values(f::PBF)              = values(f.Ω)
Base.length(f::PBF)              = length(f.Ω)
Base.empty!(f::PBF)              = empty!(f.Ω)
Base.isempty(f::PBF)             = isempty(f.Ω)
Base.iterate(f::PBF)             = iterate(f.Ω)
Base.iterate(f::PBF, i::Integer) = iterate(f.Ω, i)

Base.haskey(f::PBF{S}, ω::Set{S}) where {S} = haskey(f.Ω, ω)
Base.haskey(f::PBF{S}, ξ::S) where {S}      = haskey(f, Set{S}([ξ]))
Base.haskey(f::PBF{S}, ::Nothing) where {S} = haskey(f, Set{S}())

#  Indexing: Get  #
Base.getindex(f::PBF{S,T}, ω::Set{S}) where {S,T} = get(f.Ω, ω, zero(T))
Base.getindex(f::PBF{S}, η::Vector{S}) where {S}  = getindex(f, Set{S}(η))
Base.getindex(f::PBF{S}, ξ::S) where {S}          = getindex(f, Set{S}([ξ]))
Base.getindex(f::PBF{S}, ::Nothing) where {S}     = getindex(f, Set{S}())

#  Indexing: Set  #
function Base.setindex!(f::PBF{S,T}, c::T, ω::Set{S}) where {S,T}
    if !iszero(c)
        setindex!(f.Ω, c, ω)
    elseif haskey(f, ω)
        delete!(f, ω)
    end

    return c
end

Base.setindex!(f::PBF{S,T}, c::T, η::Vector{S}) where {S,T} = setindex!(f, c, Set{S}(η))
Base.setindex!(f::PBF{S,T}, c::T, ξ::S) where {S,T}         = setindex!(f, c, Set{S}([ξ]))
Base.setindex!(f::PBF{S,T}, c::T, ::Nothing) where {S,T}    = setindex!(f, c, Set{S}())

#  Indexing: Delete  #
Base.delete!(f::PBF{S}, ω::Set{S}) where {S}    = delete!(f.Ω, ω)
Base.delete!(f::PBF{S}, η::Vector{S}) where {S} = delete!(f, Set{S}(η))
Base.delete!(f::PBF{S}, k::S) where {S}         = delete!(f, Set{S}([k]))
Base.delete!(f::PBF{S}, ::Nothing) where {S}    = delete!(f, Set{S}())

#  Properties 
Base.size(f::PBF{S,T}) where {S,T} = (length(f),)

function Base.sizehint!(f::PBF, n::Integer)
    sizehint!(f.Ω, n)

    return f
end

#  Type conversion 
function Base.convert(U::Type{<:T}, f::PBF{<:Any,T}) where {T}
    if isempty(f)
        return zero(U)
    elseif degree(f) == 0
        return convert(U, f[nothing])
    else
        error("Can't convert non-constant Pseudo-boolean Function to scalar type '$U'")
    end
end
