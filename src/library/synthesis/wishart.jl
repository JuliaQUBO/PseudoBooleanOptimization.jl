@doc raw"""
    wishart(rng, n::Integer, m::Integer)

Generate a ``K_{n}`` (complete graph) Ising weight matrix ``J`` with the ``(+)^{n}`` state as a planted GS.

Diagonal of ``J`` is zero.

Hamiltonian is zero field, i.e:

```math
E(\mathbf{s}) = -\frac{1}{2} \mathbf{s}' J \mathbf{s}
```

- ``m`` specifies the number of columns in ``W`` (for ``m \ge n``, FM and easy.)

- `precision`: number of decimal points to round the uncorrelated Gaussian used to generate the w elements. This is to avoid numerical issues where a spurious state takes over as the GS.

Alternatively, can even replace the Gaussian with a bounded range uniform discrete distribution in ``[-range, +range]``...

"""
function wishart end

function wishart(rng, ::Type{F}, n::Integer, m::Integer = 1; discretize_bonds::Bool = false, precision = nothing) where {V,T,F<:AbstractPBF{V,T}}
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

        if !isnothing(precision)
            map!(x -> round(x; digits = precision), R, R)
        end
    end

    W = s'R
    J = W * W'
    
    for i = 1:n
        J[i,i] = zero(T)
    end

    if discretize_bonds
        map!(x -> round((n^2 - n^3) * x; digits = precision), J, J)
    else
        map!(x -> round((n - n^2) * x; digits = precision), J, J)
    end

    # Convert to boolean
    # let s_i = 2x_i - 1
    # ⟹ s_i s_j = (2x_i - 1) (2x_j - 1) = 4x_i x_j - 2x_i - 2x_j + 1
    # ⟹ Jij s_i s_j = 4Jij x_i x_j - 2Jij x_i - 2Jij x_j + Jij
    f = sizehint!(zero(F), n^2 ÷ 2)

    for i = 1:n, j = 1:n
        c = J[i, j]

        f[i, j]    += 4c
        f[i]       -= 2c
        f[j]       -= 2c
        f[nothing] += c
    end

    x = [t] # planted solution

    return (f, x)
end

function wishart(::Type{F}, n::Integer, m::Integer = 1; discretize_bonds::Bool = false, precision = nothing) where {V,T,F<:AbstractPBF{V,T}}
    return wishart(GLOBAL_RNG, F, n, m; discretize_bonds, precision)
end
