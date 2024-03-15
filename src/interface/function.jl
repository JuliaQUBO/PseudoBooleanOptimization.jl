@doc raw"""

"""
abstract type AbstractPseudoBooleanTerm{V,T} end

const AbstractPBT{V,T} = AbstractPseudoBooleanTerm{V,T}

@doc raw"""
    AbstractPseudoBooleanFunction{V,T}

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
abstract type AbstractPseudoBooleanFunction{V,T} end

const AbstractPBF{V,T} = AbstractPseudoBooleanFunction{V,T}

@doc raw"""
    term
"""
function term end

@doc raw"""
    maxgap(f::AbstractPBF{V,T}) where {V,T}

Computes the least upper bound for the greatest variantion possible of ``f \in \mathscr{F}`` i. e.

```math
\begin{array}{rl}
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
    mingap(f::AbstractPBF{V,T}, tol::T = T(1e-6)) where {V,T}

The ideal minimum gap is the greatest lower bound on the smallest non-zero value taken by ``f \in \mathscr{F}``.
"""
function mingap end

const ϵ = mingap # \epsilon [tab]

@doc raw"""
    derivative(f::AbstractPBF{V,T}, x::V) where {V,T}

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
    gradient(f::AbstractPBF)

Computes the gradient of ``f \in \mathscr{F}`` where the ``i``-th derivative is given by [`derivative`](@ref).
"""
function gradient end

const ∇ = gradient # \nabla [tab]

@doc raw"""
    residual(f::AbstractPBF{V,T}, x::S) where {V,T}

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
    discretize(f::AbstractPBF{V,T}; tol::T) where {V,T}

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
    discretize!(f::AbstractPBF{V,T}; tol::T) where {V,T}

In-place version of [`discretize`](@ref).
"""
function discretize! end

@doc raw"""
    degree(f::AbstractPBF)
"""
function degree end

@doc raw"""
    lowerbound(f::AbstractPBF)

Computes an approximate value for the greatest ``\forall \mathbf{x}. l \le f(\mathbf{x})``.
"""
function lowerbound end

@doc raw"""
    upperbound(f::AbstractPBF)

Computes an approximate value for the least ``\forall \mathbf{x}. u \ge f(\mathbf{x})``.
"""
function upperbound end

@doc raw"""
    bounds(f::AbstractPBF)

Given ``f : \mathbb{B}^{n} \to [a, b]``, returns the approximate extrema for the tightest ``[l, u] \supset [a, b]``.
"""
function bounds end
