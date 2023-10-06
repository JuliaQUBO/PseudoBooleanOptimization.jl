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

@doc raw"""
    varmap(::Type{V}, i::Integer) where {V}
"""
function varmap end

@doc raw"""
    vargen(::AbstractPBF{V,T}; name::AbstractString = "x") where {V<:AbstractString,T}

Creates a function that, when called multiple times, returns the strings `"aux_1"`, `"aux_2"`, ... and so on.

    vargen(::AbstractPBF{Symbol,T}; name::Symbol = :x) where {T}

Creates a function that, when called multiple times, returns the symbols `:x₋₁`, `:x₋₂`, ... and so on.

    vargen(::AbstractPBF{V,T}; start::V = V(0), step::V = V(-1)) where {V<:Integer,T}

Creates a function that, when called multiple times, returns the integers ``-1``, ``-2``, ... and so on.
"""
function vargen end
