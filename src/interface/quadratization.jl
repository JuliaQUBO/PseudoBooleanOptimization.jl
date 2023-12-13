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
    infer_quadratization(f::AbstractPBF)

For a given PBF, returns whether it should be quadratized or not, based on its characteristics.
"""
function infer_quadratization end

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

When `aux` is not specified, uses [`vargen`](@ref) to generate variables.
"""
function quadratize end

@doc raw"""
    quadratize!(aux, f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}
    quadratize!(f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}

In-place version of [`quadratize`](@ref).
"""
function quadratize! end
