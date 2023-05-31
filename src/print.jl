function Base.show(io::IO, term::Term{V,T}) where {V,T}
    if isone(term.c)
        join(io, varshow.(term.ω), "*")
    else
        join(io, [string(term.c); varshow.(term.ω)], "*")
    end
end

function Base.show(io::IO, func::DictFunction{V,T}) where {V,T}
    terms = Term{V,T}.(sort!(collect(func); by=first, lt=varlt))

    join(io, terms, " + ")
end

# function Base.show(io::IO, func::VectorFunction{V,T}) where {V,T}
#     join(io, func.Ω, " + ")
# end
