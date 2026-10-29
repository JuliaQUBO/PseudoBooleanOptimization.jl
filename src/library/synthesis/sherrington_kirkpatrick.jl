@doc raw"""
    sherrington_kirkpatrick(
        rng,
        ::Type{F},
        n::Integer;
        μ::T = zero(T),
        σ::T = one(T),
        normalize::Bool = false,
        gauge_invariant::Bool = true,
    ) where {V,T,F<:AbstractPBF{V,T}}

Generate an ``n``-variable Sherrington-Kirkpatrick (SK) quadratic pseudo-Boolean
function with Gaussian couplings ``J_{i, j} \sim \mathcal{N}(\mu, \sigma^2)``
for ``1 \le i < j \le n``.

When `normalize = true` (and ``n > 0``), each sampled coupling is scaled by
``\alpha = 1 / \sqrt{n}`` (otherwise ``\alpha = 1``). For the centered
Sherrington-Kirkpatrick ensemble (``\mu = 0``), ``\alpha = 1 / \sqrt{n}`` yields
an intensive spin-glass ground-state energy per variable as ``n \to \infty``
(whereas for ``\mu \neq 0`` the ferromagnetic/antiferromagnetic mean bias
contributes ``\mathcal{O}(\alpha n \mu)`` per spin).

When `gauge_invariant = true` (default), the zero-field Ising Hamiltonian

```math
H_{\textrm{SK}}(\mathbf{s}) = \sum_{i = 1}^{n} \sum_{j = i + 1}^{n} \alpha J_{i, j} s_i s_j,
\qquad s_i = 2 x_i - 1 \in \{-1, +1\}
```

is expanded into the ``\mathbb{Z}_2`` gauge-invariant pseudo-Boolean form

```math
f^{(n)}_{\textrm{SK}}(\mathbf{x})
= \sum_{i = 1}^{n} \sum_{j = i + 1}^{n} \alpha J_{i, j} (4 x_i x_j - 2 x_i - 2 x_j + 1),
```

which has zero induced Ising coercive local fields (``h_i = 0`` for all ``i``).
When `gauge_invariant = false`, the naive Boolean QUBO
``\sum_{i < j} 4 \alpha J_{i, j} x_i x_j`` is returned without the linear/constant
gauge-invariance terms, inducing coercive local fields
``h_i = \alpha \sum_{j \neq i} J_{i, j}`` with mean
``\mathbb{E}[h_i] = \alpha (n - 1) \mu`` and standard deviation
``\operatorname{sd}(h_i) = \alpha |\sigma| \sqrt{n - 1}`` (so for ``\mu = 0``,
``\operatorname{sd}(h_i) = |\sigma| \sqrt{n - 1} = \mathcal{O}(\sqrt{n})`` when
`normalize = false` and ``\operatorname{sd}(h_i) = |\sigma| \sqrt{(n - 1) / n} = \mathcal{O}(1)``
relative to ``\mathcal{O}(1 / \sqrt{n})`` couplings when `normalize = true`).
"""
function sherrington_kirkpatrick(
    rng,
    ::Type{F},
    n::Integer;
    μ::T = zero(T),
    σ::T = one(T),
    normalize::Bool = false,
    gauge_invariant::Bool = true,
) where {V,T,F<:AbstractPBF{V,T}}
    n >= 0 || throw(ArgumentError("number of variables n must be nonnegative; got $n"))
    scale = (normalize && n > 0) ? convert(T, inv(sqrt(n))) : one(T)
    J = Dict{Tuple{Int,Int},T}(
        (i, j) => scale * (σ * randn(rng, T) + μ) for i = 1:n for j = (i+1):n
    )

    # Convert to boolean:
    # let s_i = 2x_i - 1
    # ⟹ s_i s_j = (2x_i - 1) (2x_j - 1) = 4x_i x_j - 2x_i - 2x_j + 1
    # ⟹ Jij s_i s_j = 4Jij x_i x_j - 2Jij x_i - 2Jij x_j + Jij
    f = sizehint!(zero(F), length(J) + (gauge_invariant ? n : 0))

    for ((i, j), c) in J
        xi = varmap(V, i)
        xj = varmap(V, j)

        f[xi, xj] += 4c
        if gauge_invariant
            f[xi]      -= 2c
            f[xj]      -= 2c
            f[nothing] += c
        end
    end

    return (f, Dict{V,Int}[]) # no planted solutions
end

function sherrington_kirkpatrick(
    ::Type{F},
    n::Integer;
    μ::T = zero(T),
    σ::T = one(T),
    normalize::Bool = false,
    gauge_invariant::Bool = true,
) where {V,T,F<:AbstractPBF{V,T}}
    return sherrington_kirkpatrick(
        Random.GLOBAL_RNG,
        F,
        n;
        μ,
        σ,
        normalize,
        gauge_invariant,
    )
end
