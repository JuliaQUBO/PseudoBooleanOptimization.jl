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
function wishart(rng, ::Type{F}, n::Integer, m::Integer = 1; discretize_bonds::Bool, precision = nothing) where {V,T,F<:AbstractFunction{V,T}}
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
    J = J̃ - diagm(diag(J_tilde))

    if discretize_bonds
        J *= n^2 * (n - 1)
        J = round.(J)
    end

    return F([[i, j] => J[i,j] for i = 1:n, j = 1:n])
end
