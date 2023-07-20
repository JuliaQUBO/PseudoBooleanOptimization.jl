function Base.show(io::IO, term::Term{V,T}) where {V,T}
    if isempty(term.ω)
        print(io, string(term.c))
    elseif isone(term.c)
        join(io, varshow.(term.ω), "*")
    else
        join(io, [string(term.c); varshow.(term.ω)], "*")
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
