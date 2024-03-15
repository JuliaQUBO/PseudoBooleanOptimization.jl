@doc raw"""
    varlt(u::V, v::V) where {V}

Compares two variables, ``u`` and ``v``, with respect to their length-lexicographic order.

## Rationale
This function exists to define an arbitrary ordering for a given type and was created to address [^MOI].
There is no predefined comparison between instances MOI's `VariableIndex` type.
        
    [^MOI]: MathOptInterface Issue [#1985](https://github.com/jump-dev/MathOptInterface.jl/issues/1985)
"""
function varlt end

const ≺ = varlt # \prec[tab]

@doc raw"""
    varmul(u::V, v::V) where {V}
"""
function varmul end

const × = varmul # \times[tab]

@doc raw"""
    varshow(v::V) where {V}
    varshow(io::IO, v::V) where {V}
"""
function varshow end
