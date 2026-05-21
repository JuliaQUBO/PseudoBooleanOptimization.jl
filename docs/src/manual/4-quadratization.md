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
