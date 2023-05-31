@doc raw"""
    AbstractTerm{V,T}

In the context of pseudo-Boolean functions, a term is a pair ``(\omega \subset \mathbb{V}, c_{\omega} \in \mathbb{T})``.
"""
abstract type AbstractTerm{V,T} end

@doc raw"""
    AbstractFunction{V,T}

A pseudo-Boolean Function[^Boros2002] ``f \in \mathscr{F}`` over some field ``\mathbb{T}`` takes the form

```math
f(\mathbf{x}) = \sum_{\omega \in \Omega\left[f\right]} c_\omega \prod_{j \in \omega} x_j
```

where each ``\Omega\left[{f}\right]`` is the multi-linear representation of ``f`` as a set of terms.
Each term is given by a unique set of indices ``\omega \subseteq \mathbb{V}`` related to some coefficient ``c_\omega \in \mathbb{T}``.
We say that ``\omega \in \Omega\left[{f}\right] \iff c_\omega \neq 0``.
Variables ``x_j`` are boolean, thus ``f : \mathbb{B}^{n} \to \mathbb{T}``.

[^Boros2002]:
    Endre Boros, Peter L. Hammer, **Pseudo-Boolean optimization**, *Discrete Applied Mathematics*, 2002 [{doi}](https://doi.org/10.1016/S0166-218X(01)00341-9)
"""
abstract type AbstractFunction{V,T} end

@doc raw"""
    maxgap(f::AbstractFunction{V,T}; bound::Symbol=:loose) where {V,T}

Computes the least upper bound for the greatest variantion possible of `` f \in \mathscr{F} `` i. e.

```math
\begin{array}{r l}
    \min        & M \\
    \text{s.t.} & \left|{f(\mathbf{x}) - f(\mathbf{y})}\right| \le M ~~ \forall \mathbf{x}, \mathbf{y} \in \mathbb{B}^{n} 
\end{array}
```

A simple approach is to define
```math
M \triangleq \sum_{\omega \neq \varnothing} \left|{c_\omega}\right|
```
"""
function maxgap end

const δ = maxgap # \delta [tab]

@doc raw"""
    mingap(f::AbstractFunction{V,T}; bound::Symbol=:loose, tol::T = T(1e-6)) where {V,T}
"""
function mingap end

const ϵ = mingap # \epsilon [tab]

@doc raw"""
    derivative(f::AbstractFunction{V,T}, x::V) where {V,T}

The partial derivate of function ``f \in \mathscr{F}`` with respect to the ``x`` variable.

```math
    \Delta_i f(\mathbf{x}) = \frac{\partial f(\mathbf{x})}{\partial \mathbf{x}_i} =
    \sum_{\omega \in \Omega\left[{f}\right] \setminus \left\{{i}\right\}}
    c_{\omega \cup \left\{{i}\right\}} \prod_{k \in \omega} \mathbf{x}_k
```
"""
function derivative end

const Δ = derivative # \Delta [tab]
const ∂ = derivative # \partial [tab]

@doc raw"""
    gradient(f::AbstractFunction)

Computes the gradient of ``f \in \mathscr{F}`` where the ``i``-th derivative is given by [`derivative`](@ref).
"""
function gradient end

const ∇ = gradient # \nabla [tab]

@doc raw"""
    residual(f::AbstractFunction{V,T}, x::S) where {V,T}

The residual of ``f \in \mathscr{F}`` with respect to ``x``.

```math
    \Theta_i f(\mathbf{x}) = f(\mathbf{x}) - \mathbf{x}_i\, \Delta_i f(\mathbf{x}) =
    \sum_{\omega \in \Omega\left[{f}\right] \setminus \left\{{i}\right\}}
    c_{\omega} \prod_{k \in \omega} \mathbf{x}_k
```
"""
function residual end

const Θ = residual # \Theta [tab]

@doc raw"""
    discretize(f::AbstractFunction{V,T}; tol::T) where {V,T}

For a given function ``f \in \mathscr{F}`` written as

```math
    f\left({\mathbf{x}}\right) = \sum_{\omega \in \Omega\left[{f}\right]} c_\omega \prod_{i \in \omega} \mathbf{x}_i
```

computes an approximate function  ``g : \mathbb{B}^{n} \to \mathbb{Z}`` such that

```math
    \text{argmin}_{\mathbf{x} \in \mathbb{B}^{n}} g\left({\mathbf{x}}\right) = \text{argmin}_{\mathbf{x} \in \mathbb{B}^{n}} f\left({\mathbf{x}}\right)
```

This is done by rationalizing every coefficient ``c_\omega`` according to some tolerance `tol`.

"""
function discretize end

@doc raw"""
    discretize!(f::AbstractFunction{V,T}; tol::T) where {V,T}

In-place version of [`discretize`](@ref).
"""
function discretize! end

@doc raw"""
    varlt(u::V, v::V) where {V}

Compares two variables, ``u`` and ``v``, with respect to their length-lexicographic order.

## Rationale
This function exists to define an arbitrary ordering for a given type and was created to address [^MOI].
There is no predefined comparison between instances MOI's `VariableIndex` type.
        
    [^MOI]: MathOptInterface Issue [#1985](https://github.com/jump-dev/MathOptInterface.jl/issues/1985)
"""
function varlt end

varlt(u::V, v::V) where {V}         = isless(u, v) # fallback
varlt(u::V, v::V) where {V<:Symbol} = varlt(string(u), string(v))

function varlt(u::V, v::V) where {V<:AbstractString}
    if length(u) == length(v)
        return u < v
    else
        return length(u) < length(v)
    end
end

const ≺ = varlt  # \prec[tab]

@doc raw"""
    varmul(u::V, v::V) where {V}
"""
function varmul end

const × = varmul # \times[tab]

@doc raw"""
    degree(f::AbstractTerm)
    degree(f::AbstractFunction)
"""
function degree end

@doc raw"""
    lowerbound(f::AbstractFunction)

Computes an approximate value for the greatest ``l \le f(\mathbf{x})``.
"""
function lowerbound end

@doc raw"""
    upperbound(f::AbstractFunction)

Computes an approximate value for the least ``u \ge f(\mathbf{x})``.
"""
function upperbound end

@doc raw"""
    bounds(f::AbstractFunction)

Given ``f : \mathbb{B}^{n} \to [a, b]``, returns the approximate extrema for the tightest ``[l, u] \supset [a, b]``.
"""
function bounds end
