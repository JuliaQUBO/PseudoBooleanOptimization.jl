function Base.show(io::IO, term::PBT{V,T}) where {V,T}
    if isone(term.c)
        join(io, term.ω, "*")
    else
        join(io, [term.c; term.ω], "*")
    end
end

function Base.show(io::IO, func::PBF{V,T}) where {V,T}
    join(io, func.Ω, " + ")
end