# API Reference

## Variables

```@docs
PBO.varlt
PBO.varmul
PBO.varmap
PBO.vargen
PBO.varshow
```

## Terms

```@docs
PBO.AbstractTerm
PBO.Term
PBO.term
PBO.term_head
PBO.term_tail
```

## Functions

```@docs
PBO.AbstractPBF
PBO.PBF
PBO.data
```

## Analysis

```@docs
PBO.isconstant
PBO.degree
```

```@docs
PBO.lowerbound
PBO.upperbound
PBO.bounds
PBO.mingap
PBO.maxgap
```

```@docs
PBO.derivative
PBO.gradient
PBO.residual
PBO.coercive_field
PBO.coercive_fields
PBO.is_gauge_invariant
PBO.gauge_invariant_qubo
PBO.gauge_invariant_qubo!
```

```@docs
PBO.discretize
PBO.discretize!
```

```@docs
PBO.relaxedgcd
```

## Quadratization

```@docs
PBO.QuadratizationMethod
PBO.Quadratization
PBO.QuadratizationStep
PBO.QuadratizationRecord
PBO.quadratize
PBO.quadratize!
PBO.complete_auxiliaries
PBO.complete_auxiliaries!
PBO.original_variables
PBO.auxiliary_variables
PBO.quadratization_steps
PBO.objective_sense
PBO.original_function
PBO.quadratized_function
PBO.invalidate!
PBO.infer_quadratization
```

```@docs
PBO.PTR_BG
PBO.NTR_KZFD
PBO.DEFAULT
```

## Synthesis

```@docs
PBO.wishart
PBO.sherrington_kirkpatrick
PBO.not_all_equal_3sat
PBO.k_regular_k_xorsat
PBO.r_regular_k_xorsat
```
