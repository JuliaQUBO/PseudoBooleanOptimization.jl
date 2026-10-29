@doc raw"""
    AbstractTerm{V}
"""
abstract type AbstractTerm{V} end

@doc raw"""
    AbstractPBF{V,T}

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
abstract type AbstractPBF{V,T} end

const AbstractFunction{V,T} = AbstractPBF{V,T}

@doc raw"""
    data(f::AbstractPBF{V,T})

Returns the internal representation of ``f \in \mathscr{F}``.
"""
function data end

@doc raw"""
    isconstant(f::AbstractPBF)::Bool

Check if the given Pseudo-Boolean function `f` is a constant, i.e., if it has no variables.
"""
function isconstant end

@doc raw"""
    term
"""
function term end

@doc raw"""
    term_head
"""
function term_head end

@doc raw"""
    term_tail
"""
function term_tail end

@doc raw"""
    variables(f::AbstractPBF)

Returns an ordered vector of variables used by ``f \in \mathscr{F}``.
"""
function variables end

@doc raw"""
    image(f::AbstractPBF)

Returns the image of ``f \in \mathscr{F}`` i. e. the set of values taken by ``f`` as a sorted vector.
"""
function image end

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

@doc raw"""
    coercive_field(f::AbstractPBF{V,T}, x::V) where {V,T}

Computes the induced Ising coercive local field ``h_x`` on variable ``x`` for a
quadratic pseudo-Boolean function (``\deg(f) \le 2``) under the spin
transformation ``x_i = (s_i + 1) / 2`` with ``s_i \in \{-1, +1\}``:

```math
h_x = \frac{1}{2} c_{\{x\}} + \frac{1}{4} \sum_{y \neq x} c_{\{x, y\}}.
```

Throws an `ArgumentError` if ``\deg(f) > 2``.
"""
function coercive_field end

@doc raw"""
    coercive_fields(f::AbstractPBF{V,T}) where {V,T}

Returns a dictionary mapping each variable ``x \in \mathrm{variables}(f)`` of a
quadratic pseudo-Boolean function (``\deg(f) \le 2``) to its induced Ising
coercive local field [`coercive_field`](@ref) ``h_x = \frac{1}{2} c_{\{x\}} + \frac{1}{4} \sum_{y \neq x} c_{\{x, y\}}``.

Throws an `ArgumentError` if ``\deg(f) > 2``.
"""
function coercive_fields end

@doc raw"""
    is_gauge_invariant(f::AbstractPBF{V,T}; atol::Real = 0.0)::Bool where {V,T}

Checks whether a quadratic pseudo-Boolean function (``\deg(f) \le 2``) is
globally ``\mathbb{Z}_2`` bit-flip gauge invariant, i.e., ``f(\mathbf{1} - \mathbf{x}) = f(\mathbf{x})``
for all ``\mathbf{x} \in \mathbb{B}^n``, which holds if and only if every induced
Ising coercive local field vanishes (``|h_i| \le \mathrm{atol}`` for all ``i``).

Throws an `ArgumentError` if ``\deg(f) > 2`` or ``\mathrm{atol} < 0``.
"""
function is_gauge_invariant end

@doc raw"""
    gauge_invariant_qubo(f::AbstractPBF{V,T}; keep_constant::Bool = true) where {V,T}

Projects a quadratic pseudo-Boolean function (``\deg(f) \le 2``) onto its
zero-field ``\mathbb{Z}_2`` gauge-invariant QUBO form[^Boettcher2019] by setting
each linear coefficient to

```math
c_{\{i\}}^{\mathrm{gauge}} = -\frac{1}{2} \sum_{j \neq i} c_{\{i, j\}},
```

so that the non-constant interaction takes the bit-flip symmetric form

```math
\sum_{i < j} c_{\{i, j\}} \left(x_i x_j - \frac{1}{2} x_i - \frac{1}{2} x_j\right)
= -\frac{1}{2} \sum_{i < j} c_{\{i, j\}} (x_i + x_j - 2 x_i x_j),
```

with ``h_i = 0`` for every variable. When `keep_constant = false`, the constant
term ``c_\varnothing`` is also zeroed so that ``f(\mathbf{0}) = f(\mathbf{1}) = 0``.

[^Boettcher2019]:
    Stefan Boettcher, **Analysis of the relation between quadratic unconstrained binary optimization (QUBO) and the spin-glass ground-state problem**, *Physical Review Research* **1**, 033142, 2019 [{doi}](https://doi.org/10.1103/PhysRevResearch.1.033142)
"""
function gauge_invariant_qubo end

@doc raw"""
    gauge_invariant_qubo!(f::AbstractPBF{V,T}; keep_constant::Bool = true) where {V,T}

In-place version of [`gauge_invariant_qubo`](@ref).
"""
function gauge_invariant_qubo! end
