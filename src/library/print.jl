function Base.show(io::IO, (ω, c)::Term{V,T}) where {V,T}
    if isempty(ω)
        print(io, c)
    elseif isone(c)
        join(io, varshow.(ω), "*")
    else
        join(io, [string(c); varshow.(ω)], "*")
    end
end

function Base.show(io::IO, func::DictFunction{V,T}) where {V,T}
    terms = Term{V,T}.(sort!(collect(func); by=first, lt=varlt))

    if isempty(terms)
        print(io, zero(T))
    else
        join(io, terms, " + ")
    end
end

# function Base.show(io::IO, func::VectorFunction{V,T}) where {V,T}
#     join(io, func.Ω, " + ")
# end
