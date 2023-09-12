#  :: Quadratization ::  #
abstract type QuadratizationMethod end

struct Quadratization{Q<:QuadratizationMethod}
    method::Q
    stable::Bool

    function Quadratization{Q}(method::Q, stable::Bool = false) where {Q<:QuadratizationMethod}
        return new{Q}(method, stable)
    end
end

function Quadratization(method::Q; stable::Bool = false) where {Q<:QuadratizationMethod}
    return Quadratization{Q}(method, stable)
end

@doc raw"""
    quadratize(aux, f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}

Quadratizes a given PBF, i.e., applies a mapping ``\mathcal{Q} : \mathscr{F}^{k} \to \mathscr{F}^{2}``, where ``\mathcal{Q}`` is the quadratization method.

## Auxiliary variables
The `aux` function is expected to produce auxiliary variables with the following signatures:

    aux()::V where {V}

Creates and returns a single variable.

    aux(n::Integer)::Vector{V} where {V}

Creates and returns a vector with ``n`` variables.

    quadratize(f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}

When `aux` is not specified, uses [`auxgen`](@ref) to generate variables.
"""
function quadratize end

@doc raw"""
    quadratize!(aux, f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}
    quadratize!(f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}

In-place version of [`quadratize`](@ref).
"""
function quadratize! end

@doc raw"""
    auxgen(::AbstractPBF{V,T}; name::AbstractString = "aux") where {V<:AbstractString,T}

Creates a function that, when called multiple times, returns the strings `"aux_1"`, `"aux_2"`, ... and so on.

    auxgen(::AbstractPBF{Symbol,T}; name::Symbol = :aux) where {T}

Creates a function that, when called multiple times, returns the symbols `:aux_1`, `:aux_2`, ... and so on.

    auxgen(::AbstractPBF{V,T}; start::V = V(0), step::V = V(-1)) where {V<:Integer,T}

Creates a function that, when called multiple times, returns the integers ``-1``, ``-2``, ... and so on.
"""
function auxgen end
