const DefaultPBF{V,T} = PBF{V,T,TermDict{V,T}}

function PBF{V,T}(args...; kwargs...) where {V,T}
    return DefaultPBF{V,T}(args...; kwargs...)
end

function Base.zero(::Type{PBF{V,T}}) where {V,T}
    return zero(DefaultPBF{V,T})
end

function Base.one(::Type{PBF{V,T}}) where {V,T}
    return one(DefaultPBF{V,T})
end
