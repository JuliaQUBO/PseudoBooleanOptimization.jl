function Base.show(io::IO, term::Term{V,T}) where {V,T}
    if isone(term.c)
        join(io, term.ω, "*")
    else
        join(io, [term.c; term.ω], "*")
    end
end

function Base.show(io::IO, func::DictFunction{V,T}) where {V,T}
    join(io, (join([c;sort(collect(ω); lt=varlt)], "*") for (ω, c) in func), " + ")
end

# function Base.show(io::IO, func::VectorFunction{V,T}) where {V,T}
#     join(io, func.Ω, " + ")
# end
