_showvar(x::Any) = x
_showvar(s::Set) = _showvar.(sort(collect(s); lt = PBO.varlt))
_showvar(x::Integer, v::Symbol = :x) = join([v; Char(0x2080) .+ reverse(digits(x))])

function _showterm(ω::Set{S}, c::T, isfirst::Bool) where {S,T}
    if isfirst
        "$(c)$(join(_showvar(ω), "*"))"
    else
        if c < zero(T)
            " - $(abs(c))$(join(_showvar(ω), "*"))"
        else
            " + $(abs(c))$(join(_showvar(ω), "*"))"
        end
    end
end

function Base.show(io::IO, f::PBF{<:Any,T}) where {T}
    Ω = sort!(collect(f); lt = (x, y) -> varlt(first(x), first(y)))

    print(io, if isempty(f)
        zero(T)
    else
        join(_showterm(ω, c, isone(i)) for (i, (ω, c)) in enumerate(Ω))
    end)
end
