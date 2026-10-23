# Quadratization

A Quadratization is a mapping ``\mathcal{Q}\{f\}: \mathscr{F} \to \mathscr{F}^{2}`` that preserves the optimization over auxiliary variables.

For minimization, the default `sign = 1` gives

```math
\min_{\mathbf{y}} \mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}) = f(\mathbf{x}) ~\forall \mathbf{x} \in \mathbb{B}^{n}.~\forall f \in \mathscr{F}.
```

For maximization, use `sign = -1` so that

```math
\max_{\mathbf{y}} \mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}) = f(\mathbf{x}) ~\forall \mathbf{x} \in \mathbb{B}^{n}.~\forall f \in \mathscr{F}.
```

The `sign` keyword controls the objective sense used to select and validate term reductions. The quadratized function keeps coefficients in the original objective scale.

## Reusable Quadratization Records and Auxiliary Completion

Pass `record = true` to [`PBO.quadratize`](@ref) or [`PBO.quadratize!`](@ref) to obtain a reusable [`PBO.QuadratizationRecord`](@ref) alongside the quadratized function. Given a binary assignment ``\mathbf{x}`` for the original variables (or a raw sampled state ``(\mathbf{x}, \mathbf{y}_{\text{raw}})``), [`PBO.complete_auxiliaries`](@ref) returns a new completed state ``(\mathbf{x}, \mathbf{y}^{*})`` satisfying ``\mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}^{*}) = f(\mathbf{x})`` while leaving the input state unchanged.

!!! warning "Conditional Auxiliary Optimization vs. Problem Feasibility"
    Auxiliary variables in term reductions such as [`PBO.PTR_BG`](@ref) are **not** necessarily simple products of the original variables. Completing quadratization auxiliaries optimizes ``\mathbf{y}`` **conditionally on a fixed** ``\mathbf{x}``:
    - It restores the exact reduction identity ``\mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}^{*}) = f(\mathbf{x})`` at that fixed ``\mathbf{x}``.
    - It does **not** find a global optimum of ``f(\mathbf{x})``.
    - It does **not** repair original model constraints, domain feasibility, or integer/slack variable encodings.

### Example: Restoring ``\mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}^{*}) = f(\mathbf{x})`` on a Sampled State

For ``f(x_1, x_2, x_3) = x_1 x_2 x_3``, [`PBO.PTR_BG`](@ref) produces

```math
\mathcal{Q}\{f\}(x_1, x_2, x_3; y_1) = y_1 (1 + x_1 - x_2 - x_3) + x_2 x_3.
```

At ``\mathbf{x} = (0, 1, 1)``, ``f(\mathbf{x}) = 0``, but setting ``y_1 = 0`` (the naive product ``x_1 x_2 x_3``) yields ``\mathcal{Q}\{f\}(0, 1, 1; 0) = 1 \neq f(\mathbf{x})``. Completing the auxiliary variable sets ``y_1^{*} = 1`` and restores ``\mathcal{Q}\{f\}(0, 1, 1; 1) = 0 = f(\mathbf{x})``:

```@example quadratization
import PseudoBooleanOptimization as PBO

f = PBO.PBF{Symbol,Float64}((:x1, :x2, :x3) => 1.0)
quad = PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = 1)
q, rec = PBO.quadratize(f, quad; record = true)

raw_sample = Dict(:x1 => 0, :x2 => 1, :x3 => 1, :aux_1 => 0)
repaired_sample = PBO.complete_auxiliaries(rec, raw_sample)

(
    original_energy = convert(Float64, f(raw_sample)),
    raw_qubo_energy = convert(Float64, q(raw_sample)),
    repaired_qubo_energy = convert(Float64, q(repaired_sample)),
    raw_aux = raw_sample[:aux_1],
    repaired_aux = repaired_sample[:aux_1],
)
```

### Record Validity and Invalidation

A [`PBO.QuadratizationRecord`](@ref) is tied to the exact formulation and [`PBO.Quadratization`](@ref) configuration that produced it:

- **Tracked formulation identity**: Out-of-place `q, rec = PBO.quadratize(f, quad; record = true)` tracks both the original polynomial `f` and the returned quadratic polynomial `q`. In-place `f, rec = PBO.quadratize!(f, quad; record = true)` snapshots the pre-quadratization polynomial and tracks the mutated in-place polynomial `f`.
- **Automatic invalidation on mutation**: Modifying any term or coefficient of the tracked original polynomial `f` (for out-of-place `quadratize`) or the tracked quadratic polynomial `q` (including in-place mutation of mutable coefficient types such as `BigFloat`) causes `isvalid(rec)` to return `false` and [`PBO.complete_auxiliaries`](@ref) / [`PBO.complete_auxiliaries!`](@ref) to throw an `ArgumentError`.
- **Explicit invalidation and mismatch checks**: Call [`PBO.invalidate!`](@ref) to explicitly invalidate a record, or pass `qubo`, `original`, or `quad` to `isvalid(rec; qubo, original, quad)` / [`PBO.complete_auxiliaries`](@ref) to verify that the record matches a specific formulation object and reduction configuration. Whenever the original coefficients, quadratized coefficients, or reduction configuration change, rerun `quadratize` / `quadratize!` with `record = true` to build a fresh record.
