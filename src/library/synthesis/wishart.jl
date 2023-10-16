@doc raw"""
    wishart(rng, n::Integer, m::Integer)

Generate a ``K_{n}`` (complete graph) Ising weight matrix ``J`` with the
``\mathbf{1} \in {\pm 1}^{n}`` state as a planted ground state.

The main diagonal of ``J`` is zero.

The Hamiltonian is zero field, i.e,

```math
E(\mathbf{s}) = -\frac{1}{2} \mathbf{s}' J \mathbf{s}
```

- ``m`` specifies the number of columns in ``W`` (for ``m \ge n``, FM and easy.)

- `precision`: number of decimal points to round the uncorrelated Gaussian used to generate the w elements. This is to avoid numerical issues where a spurious state takes over as the GS.

Alternatively, can even replace the Gaussian with a bounded range uniform discrete distribution in ``[-range, +range]``...

"""
function wishart end

function wishart(
    rng,
    ::Type{F},
    n::Integer,
    m::Integer = 1;
    discretize_bonds::Bool = false,
    precision = nothing,
) where {V,T,F<:AbstractPBF{V,T}}
    # Plants the FM ground state
    s = ones(Int, n)

    # Sample correlated Gaussian with covariance matrix sigma
    # NOTE: rank(sigma) = n - 1
    σ = (n * I - (s * s')) / (n - 1)
    θ = √((n - 1) / n) * σ

    if discretize_bonds
        R = rand(rng, (-1, +1), n, m)
    else
        R = randn(rng, n, m)

        if !isnothing(precision)
            map!(x -> round(x; digits = precision), R, R)
        end
    end

    W = θ'R
    J = W * W'

    for i = 1:n
        J[i, i] = zero(T)
    end

    if discretize_bonds
        map!(x -> round((n^2 - n^3) * x; digits = something(precision, 0)), J, J)
    else
        map!(x -> round((n - n^2) * x; digits = something(precision, 0)), J, J)
    end

    # Convert to boolean
    # let s_i = 2x_i - 1
    # ⟹ s_i s_j = (2x_i - 1) (2x_j - 1) = 4x_i x_j - 2x_i - 2x_j + 1
    # ⟹ Jij s_i s_j = 4Jij x_i x_j - 2Jij x_i - 2Jij x_j + Jij
    f = sizehint!(zero(F), n^2 ÷ 2)

    for i = 1:n, j = 1:n
        xi = varmap(V, i)
        xj = varmap(V, j)

        c = J[i, j]

        f[xi, xj]  += 4c
        f[xi]      -= 2c
        f[xj]      -= 2c
        f[nothing] += c
    end

    x = Dict{V,Int}[Dict{V,Int}(varmap(V, i) => (s[i] + 1) ÷ 2 for i = 1:n)]

    return (f, x) # one planted solution! Yeah!
end

function wishart(
    ::Type{F},
    n::Integer,
    m::Integer = 1;
    discretize_bonds::Bool = false,
    precision = nothing,
) where {V,T,F<:AbstractPBF{V,T}}
    return wishart(Random.GLOBAL_RNG, F, n, m; discretize_bonds, precision)
end
