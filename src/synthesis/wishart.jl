@doc raw"""
    wishart(rng, n::Integer, m::Integer)

Generate a ``K_{n}`` (complete graph) Ising weight matrix ``J`` with the ``(+)^{n}`` state as a planted GS.

Diagonal of ``J`` is zero.

Hamiltonian is zero field, i.e:

```math
E(\mathbf{s}) = -\frac{1}{2} \mathbf{s}' J \mathbf{s}
```

- ``M`` specifies the number of columns in ``W`` (for ``M \ge n``, FM and easy.)

- `precision`: number of decimal points to round the uncorrelated Gaussian used to generate the w elements. This is to avoid numerical issues where a spurious state takes over as the GS.

Alternatively, can even replace the Gaussian with a bounded range uniform discrete distribution in ``[-range, +range]``...

"""
function wishart end

function wishart(::Type{F}, n::Integer, m::Integer = 1; discretize_bonds::Bool = false, precision = nothing) where {V,T,F<:AbstractFunction{V,T}}
    return wishart(GLOBAL_RNG, F, n, m; discretize_bonds, precision)
end

function wishart(rng, ::Type{F}, n::Integer, m::Integer = 1; discretize_bonds::Bool = false, precision = nothing) where {V,T,F<:AbstractFunction{V,T}}
    # Plants the FM GS
    t = ones(n, 1)

    # Sample correlated Gaussian with covariance matrix sigma
    # NOTE: rank(sigma) = n - 1
    σ = (n * I - (t * t')) / (n - 1)
    s = √((n - 1) / n) * σ

    if discretize_bonds
        R = rand(rng, (-1,+1), n, m)
    else
        R = randn(rng, n, m)

        if precision !== nothing
            R = round.(R; digits = precision)
        end
    end

    W = s'R
    J̃ = -(W * W') / n
    J = J̃ - diagm(diag(J̃))

    if discretize_bonds
        J *= n^2 * (n - 1)
        J = round.(J)
    end

    # Convert to boolean
    # s = 2x - 1
    return sum([J[i,j] * F(i => T(2), T(-1)) * F(j => T(2), T(-1)) for i = 1:n for j = 1:n])
end
