varshow(io::IO, v::V) where {V}                       = show(io, varshow(v))
varshow(v::Integer, x::AbstractString = "x")          = "$(x)$(_subscript(v))"
varshow(v::V) where {V<:Union{Symbol,AbstractString}} = string(v)
