const SetDict{V,T} = Dict{Set{V},T}

const SetDictKey{V} = Union{AbstractSet{V},AbstractVector{V},Nothing}

function PBF{V,T,S}() where {V,T,S<:SetDict{V,T}}
    return PBF{V,T,S}(SetDict{V,T}())
end

function PBF{V,T}(Ω::Dict{SetDictKey{V},T}) where {V,T}
    return new{V,T,SetDict{V,T}}(
        SetDict{V,T}((isnothing(ω) ? Set{V}() : ω) => c for (ω, c) in Ω if !iszero(c))
    )
end

struct DictFunction{V,T} <: AbstractPBF{V,T}
    Ω::Dict{Set{V},T}

    

    function DictFunction{V,T}(v::AbstractVector) where {V,T}
        Ω = Dict{Set{V},T}()

        for x in v
            t = Term{V,T}(x)
            ω = Set{V}(first(t))
            a = last(t)
            
            Ω[ω] = get(Ω, ω, zero(T)) + a
        end

        return DictFunction{V,T}(Ω)
    end

    function DictFunction{V,T}(x::Base.Generator) where {V,T}
        return DictFunction{V,T}(collect(x))
    end

    function DictFunction{V,T}(x::Vararg{Any}) where {V,T}
        return DictFunction{V,T}(collect(x))
    end

    function DictFunction{V,T}() where {V,T}
        return new{V,T}(Dict{Set{V},T}())
    end
end

# Broadcast as scalar
Base.broadcastable(f::DictFunction) = Ref(f)

# Copy 
function Base.copy!(f::DictFunction{V,T}, g::DictFunction{V,T}) where {V,T}
    sizehint!(f, length(g))
    copy!(f.Ω, g.Ω)

    return f
end

function Base.copy(f::DictFunction{V,T}) where {V,T}
    return copy!(DictFunction{V,T}(), f)
end

#  Iterator & Length 
Base.keys(f::DictFunction)                = keys(f.Ω)
Base.values(f::DictFunction)              = values(f.Ω)
Base.length(f::DictFunction)              = length(f.Ω)
Base.empty!(f::DictFunction)              = empty!(f.Ω)
Base.isempty(f::DictFunction)             = isempty(f.Ω)
Base.iterate(f::DictFunction)             = iterate(f.Ω)
Base.iterate(f::DictFunction, i::Integer) = iterate(f.Ω, i)

Base.haskey(f::DictFunction{V}, ω::Set{V}) where {V} = haskey(f.Ω, ω)
Base.haskey(f::DictFunction{V}, ξ::V) where {V}      = haskey(f, Set{V}([ξ]))
Base.haskey(f::DictFunction{V}, ::Nothing) where {V} = haskey(f, Set{V}())

#  Indexing: Get  #
Base.getindex(f::DictFunction{V,T}, ω::Set{V}) where {V,T} = get(f.Ω, ω, zero(T))
Base.getindex(f::DictFunction{V}, η::Vector{V}) where {V}  = getindex(f, Set{V}(η))
Base.getindex(f::DictFunction{V}, ξ::V) where {V}          = getindex(f, Set{V}([ξ]))
Base.getindex(f::DictFunction{V}, ::Nothing) where {V}     = getindex(f, Set{V}())

#  Indexing: Set  #
function Base.setindex!(f::DictFunction{V,T}, c::T, ω::Set{V}) where {V,T}
    if !iszero(c)
        setindex!(f.Ω, c, ω)
    elseif haskey(f, ω)
        delete!(f, ω)
    end

    return c
end

Base.setindex!(f::DictFunction{V,T}, c::T, η::Vector{V}) where {V,T} = setindex!(f, c, Set{V}(η))
Base.setindex!(f::DictFunction{V,T}, c::T, ξ::V) where {V,T}         = setindex!(f, c, Set{V}([ξ]))
Base.setindex!(f::DictFunction{V,T}, c::T, ::Nothing) where {V,T}    = setindex!(f, c, Set{V}())

#  Indexing: Delete  #
Base.delete!(f::DictFunction{V}, ω::Set{V}) where {V}    = delete!(f.Ω, ω)
Base.delete!(f::DictFunction{V}, η::Vector{V}) where {V} = delete!(f, Set{V}(η))
Base.delete!(f::DictFunction{V}, k::V) where {V}         = delete!(f, Set{V}([k]))
Base.delete!(f::DictFunction{V}, ::Nothing) where {V}    = delete!(f, Set{V}())

#  Properties 
Base.size(f::DictFunction{V,T}) where {V,T} = (length(f),)

function Base.sizehint!(f::DictFunction, n::Integer)
    sizehint!(f.Ω, n)

    return f
end