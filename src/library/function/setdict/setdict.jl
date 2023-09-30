const SetDict{V,T} = Dict{Set{V},T}

# Constructors
function PBF(Φ::S) where {V,T,S<:SetDict{V,T}}
    return PBF{V,T,S}(SetDict{V,T}(ω => c for (ω, c) in Φ if !iszero(c)))
end

function Base.zero(::Type{PBF{V,T,S}}) where {V,T,S<:SetDict{V,T}}
    return PBF{V,T,S}(SetDict{V,T}())
end

function Base.one(::Type{PBF{V,T,S}}) where {V,T,S<:SetDict{V,T}}
    return PBF{V,T,S}(SetDict{V,T}(Set{V}() => one(T)))
end

# Type promotion
function Base.promote_rule(::Type{PBF{V,Tf,SetDict{V,Tf}}}, ::Type{PBF{V,Tg,S}}) where {V,Tf,Tg,S}
    T = promote_type(Tf, Tg)

    return PBF{V,T,SetDict{V,T}}
end

# Term parser
function term(Φ::Type{SetDict{V,T}}, ω, c) where {V,T}
    c_ = term_tail(Φ, c)

    if iszero(c_)
        return (Set{V}() => zero(T))
    else
        ω_ = term_head(Φ, ω)

        return (ω_ => c_)
    end
end

term_head(::Type{PBF{V,_,SetDict{V,_}}}, ω::Set{V}) where {V,_}            = ω
term_head(::Type{PBF{V,_,SetDict{V,_}}}, ::Nothing) where {V,_}            = Set{V}()
term_head(::Type{PBF{V,_,SetDict{V,_}}}, ω::V) where {V,_}                 = Set{V}([ω])
term_head(::Type{PBF{V,_,SetDict{V,_}}}, ω::AbstractSet{V}) where {V,_}    = Set{V}(ω)
term_head(::Type{PBF{V,_,SetDict{V,_}}}, ω::AbstractVector{V}) where {V,_} = Set{V}(ω)
term_head(::Type{PBF{V,_,SetDict{V,_}}}, ω::NTuple{N,V}) where {N,V,_}     = Set{V}(ω)

term_tail(::Type{PBF{_,T,SetDict{_,T}}}, c::T) where {_,T} = c
term_tail(::Type{PBF{_,T,SetDict{_,T}}}, c) where {_,T}    = convert(T, c)

# Copy
function Base.copy!(f::PBF{V,T,SetDict{V,T}}, g::PBF{V,T,SetDict{V,T}}) where {V,T}
    sizehint!(f, length(g))

    copy!(f.Φ, g.Φ)

    return f
end

function Base.copy(f::F) where {V,T,F<:PBF{V,T,SetDict{V,T}}}
    return copy!(zero(F), f)
end

function Base.sizehint!(f::PBF{V,T,SetDict{V,T}}, n::Integer) where {V,T}
    sizehint!(f.Φ, n)

    return f
end

# Iterator & Length 
Base.length(f::PBF{V,T,SetDict{V,T}}) where {V,T}              = length(f.Φ)
Base.iterate(f::PBF{V,T,SetDict{V,T}}) where {V,T}             = iterate(f.Φ)
Base.iterate(f::PBF{V,T,SetDict{V,T}}, i::Integer) where {V,T} = iterate(f.Φ, i)

# Emptiness
Base.empty!(f::PBF{V,T,SetDict{V,T}}) where {V,T}  = empty!(f.Φ)
Base.isempty(f::PBF{V,T,SetDict{V,T}}) where {V,T} = isempty(f.Φ)

# Dictionary interface
Base.keys(f::PBF{V,T,SetDict{V,T}}) where {V,T}   = keys(f.Φ)
Base.values(f::PBF{V,T,SetDict{V,T}}) where {V,T} = values(f.Φ)

# Base.map!(φ::Function, f::PBF{V,T,SetDict{V,T}}) where {V,T} = map!(φ, values(f))

# Broadcast as scalar
Base.broadcastable(f::PBF{V,T,S}) where {V,T,S} = Ref(f)

# Indexing - in
function Base.haskey(f::F, ω) where {V,_,F<:PBF{V,_,SetDict{V,_}}}
    return haskey(f.Φ, term_head(F, ω))
end

# Indexing - get
function Base.getindex(f::F, ω) where {V,T,F<:PBF{V,T,SetDict{V,T}}}
    return get(f.Φ, term_head(F, ω), zero(T))
end

# Indexing - set
function Base.setindex!(f::F, c, ω) where {V,T,F<:PBF{V,T,SetDict{V,T}}}
    ω_ = term_head(F, ω)
    c_ = term_tail(F, c)

    if !iszero(c_)
        setindex!(f.Φ, c_, ω_)
    elseif haskey(f, ω_)
        delete!(f, ω_)
    end

    return c_
end

function Base.delete!(f::F, ω) where {V,T,F<:PBF{V,T,SetDict{V,T}}}
    delete!(f.Φ, term_head(F, ω))

    return f
end

#####




function isscalar(f::DictFunction)
    return isempty(f) || (length(f) == 1 && haskey(f, nothing))
end

Base.zero(::Type{DictFunction{V,T}}) where {V,T}    = DictFunction{V,T}()
Base.iszero(f::DictFunction)                        = isempty(f)
Base.one(::Type{DictFunction{V,T}}) where {V,T}     = DictFunction{V,T}(one(T))
Base.isone(f::DictFunction)                         = isscalar(f) && isone(f[nothing])
Base.round(f::DictFunction{V,T}; kw...) where {V,T} = DictFunction{V,T}(ω => round(c; kw...) for (ω, c) in f)

