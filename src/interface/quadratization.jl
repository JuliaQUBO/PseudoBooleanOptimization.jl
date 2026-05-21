#  :: Quadratization ::  #
abstract type QuadratizationMethod end

@doc raw"""
    Quadratization(method::QuadratizationMethod; stable::Bool = false, sign::Integer = 1)

Configures a quadratization method.

The `sign` keyword controls the objective sense used to choose and validate term
reductions. Use `sign = 1` for minimization and `sign = -1` for maximization.
Coefficients in the quadratized function remain in the original objective
scale.
"""
struct Quadratization{Q<:QuadratizationMethod}
    method::Q
    stable::Bool
    sign::Int

    function Quadratization{Q}(
        method::Q,
        stable::Bool = false,
        sign::Integer = 1,
    ) where {Q<:QuadratizationMethod}
        if !(sign in (-1, 1))
            throw(ArgumentError("Quadratization sign must be either -1 or 1"))
        end

        return new{Q}(method, stable, Int(sign))
    end
end

function Quadratization(
    method::Q;
    stable::Bool = false,
    sign::Integer = 1,
) where {Q<:QuadratizationMethod}
    return Quadratization{Q}(method, stable, sign)
end

@doc raw"""
    infer_quadratization(f::AbstractPBF)

For a given PBF, returns whether it should be quadratized or not, based on its characteristics.
"""
function infer_quadratization end

@doc raw"""
    quadratize(aux, f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}

Quadratizes a given PBF, i.e., applies a mapping ``\mathcal{Q} : \mathscr{F}^{k} \to \mathscr{F}^{2}``, where ``\mathcal{Q}`` is the quadratization method.

For `Quadratization(...; sign = 1)`, the returned function preserves
minimization over auxiliary variables:

```math
\min_{\mathbf{y}} \mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}) = f(\mathbf{x}).
```

For `Quadratization(...; sign = -1)`, it preserves maximization over auxiliary
variables:

```math
\max_{\mathbf{y}} \mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}) = f(\mathbf{x}).
```

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
