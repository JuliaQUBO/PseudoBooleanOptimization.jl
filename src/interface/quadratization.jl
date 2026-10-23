#  :: Quadratization ::  #
@doc raw"""
    QuadratizationMethod

Abstract supertype for pseudo-Boolean quadratization methods.
"""
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
    original_variables(record)

Returns the sorted vector of original variables associated with `record`.
"""
function original_variables end

@doc raw"""
    auxiliary_variables(record)

Returns the vector of auxiliary variable labels allocated during the
quadratization recorded in `record`, in allocation order.
"""
function auxiliary_variables end

@doc raw"""
    quadratization_steps(record)

Returns the ordered vector of [`QuadratizationStep`](@ref)s recorded during
quadratization.
"""
function quadratization_steps end

@doc raw"""
    objective_sense(record)

Returns the objective sense sign (`1` for minimization, `-1` for maximization)
associated with `record`.
"""
function objective_sense end

@doc raw"""
    original_function(record)

Returns a copy of the original pseudo-Boolean function prior to quadratization.
"""
function original_function end

@doc raw"""
    quadratized_function(record)

Returns the quadratized pseudo-Boolean function associated with `record`.
"""
function quadratized_function end

@doc raw"""
    invalidate!(record)

Marks `record` as invalid so subsequent auxiliary completions are rejected.
"""
function invalidate! end

@doc raw"""
    complete_auxiliaries(record, assignment::AbstractDict)
    complete_auxiliaries(assignment::AbstractDict, record)

Given a complete binary assignment `assignment` for the original variables in
`record`, returns a new `Dict{V,Int}` containing `(x, y_star)` with all original
coordinates unchanged and auxiliary variables set to their optimal conditional
completion `y_star` so that ``\mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}^{*}) = f(\mathbf{x})``.

When both `y = 0` and `y = 1` achieve the same conditional objective value for a
term reduction, ties are broken deterministically in favor of `0`.

The input `assignment` is not modified, keeping raw and repaired states
separately available to the caller.
"""
function complete_auxiliaries end

@doc raw"""
    complete_auxiliaries!(assignment::AbstractDict, record)
    complete_auxiliaries!(record, assignment::AbstractDict)

In-place version of [`complete_auxiliaries`](@ref) that writes the completed
auxiliary assignments into `assignment` and returns it.
"""
function complete_auxiliaries! end

@doc raw"""
    infer_quadratization(f::AbstractPBF)

For a given PBF, returns whether it should be quadratized or not, based on its characteristics.
"""
function infer_quadratization end

@doc raw"""
    quadratize(aux, f::PBF{V, T}, ::Quadratization{Q}; record::Bool = false, original_variables = nothing) where {V,T,Q}

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

When `record = true`, returns `(q, rec)` where `q` is the quadratized function
and `rec` is a reusable [`QuadratizationRecord`](@ref).

## Auxiliary variables
The `aux` function is expected to produce auxiliary variables with the following signatures:

    aux()::V where {V}

Creates and returns a single variable.

    aux(n::Integer)::Vector{V} where {V}

Creates and returns a vector with ``n`` variables.

    quadratize(f::PBF{V, T}, ::Quadratization{Q}; record::Bool = false, original_variables = nothing) where {V,T,Q}

When `aux` is not specified, uses [`vargen`](@ref) to generate variables.
"""
function quadratize end

@doc raw"""
    quadratize!(aux, f::PBF{V, T}, ::Quadratization{Q}; record::Bool = false, original_variables = nothing) where {V,T,Q}
    quadratize!(f::PBF{V, T}, ::Quadratization{Q}; record::Bool = false, original_variables = nothing) where {V,T,Q}

In-place version of [`quadratize`](@ref).
"""
function quadratize! end

