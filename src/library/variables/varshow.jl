varshow(io::IO, v::V) where {V}                       = show(io, varshow(v))
varshow(v::Integer, x::AbstractString = "x")          = "$(x)$(_subscript(v))"
varshow(v::V) where {V<:Union{Symbol,AbstractString}} = string(v)

function Base.show(io::IO, ::MIME"text/plain", f::AbstractPBF{V,T}) where {V,T}
    if isconstant(f)
        print(io, f[nothing])

        return nothing
    end

    terms = sort!(map(((ω, c)::Pair) -> (sort(collect(ω)) => c), pairs(f)); by=first, lt=varlt)

    for (i, (ω, c)) in enumerate(terms)
        if i > 1
            if c < zero(T)
                print(io, " - ")
            else
                print(io, " + ")
            end
        else
            if c < zero(T)
                print(io, "-")
            end
        end

        c_ = abs(c)

        if isone(c_)
            join(io, varshow.(ω), " ")
        else
            join(io, [string(c_); varshow.(ω)], " ")
        end
    end

    return nothing
end

# function Base.show(io::IO, f::VectorFunction{V,T}) where {V,T}
#     join(io, f.Ω, " + ")
# end
