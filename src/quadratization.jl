#  :: Quadratization ::  #
abstract type QuadratizationMethod end

struct Quadratization{Q<:QuadratizationMethod}
    stable::Bool

    function Quadratization{Q}(stable::Bool = false) where {Q<:QuadratizationMethod}
        return new{Q}(stable)
    end
end

@doc raw"""
    quadratize(aux, f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}

Quadratizes a given PBF, i.e., applies a mapping ``\mathcal{Q} : \mathscr{F}^{k} \to \mathscr{F}^{2}``, where ``\mathcal{Q}`` is the quadratization method.

## Auxiliary variables
The `aux` function is expected to produce auxiliary variables with the following signatures:

    aux()::V where {V}

Creates and returns a single variable.

    aux(n::Integer)::Vector{V} where {V}

Creates and returns a vector with ``n`` variables.

    quadratize(f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}

When `aux` is not specified, uses [`auxgen`](@ref) to generate variables.
"""
function quadratize end

@doc raw"""
    quadratize!(aux, f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}
    quadratize!(f::PBF{V, T}, ::Quadratization{Q}) where {V,T,Q}

In-place version of [`quadratize`](@ref).
"""
function quadratize! end

@doc raw"""
    Quadratization{NTR_KZFD}(stable::Bool = false)

Negative term reduction NTR-KZFD (Kolmogorov & Zabih, 2004; Freedman & Drineas, 2005)

Let ``f(\mathbf{x}) = -x_{1} x_{2} \dots x_{k}``.

```math
\mathcal{Q}\left\lbrace{f}\right\rbrace(\mathbf{x}; z) = (k - 1) z - \sum_{i = 1}^{k} x_{i} z
```

where ``\mathbf{x} \in \mathbb{B}^k``

!!! info
    Introduces a new variable ``z`` and no non-submodular terms.
"""
struct NTR_KZFD <: QuadratizationMethod end

function quadratize!(
    aux,
    f::PBF{V,T},
    ω::Set{V},
    c::T,
    ::Quadratization{NTR_KZFD},
) where {V,T}
    # Degree
    k = length(ω)

    # Fast-track
    k < 3 && return nothing

    # Variables
    s = aux()::V

    # Stabilize
    # NOTE: This method is stable by construction

    # Quadratization
    delete!(f, ω)

    f[s] += -c * (k - 1)

    for i ∈ ω
        f[i×s] += c
    end

    return f
end

@doc raw"""
    Quadratization{PTR_BG}(stable::Bool = false)

Positive term reduction PTR-BG (Boros & Gruber, 2014)

Let ``f(\mathbf{x}) = x_{1} x_{2} \dots x_{k}``.

```math
\mathcal{Q}\left\lbrace{f}\right\rbrace(\mathbf{x}; \mathbf{z}) = \left[{
    \sum_{i = 1}^{k-2} z_{i} \left({ k - i - 1 + x_{i} - \sum_{j = i+1}^{k} x_{j} }\right)
}\right] + x_{k-1} x_{k}
```
where ``\mathbf{x} \in \mathbb{B}^k`` and ``\mathbf{z} \in \mathbb{B}^{k-2}``

!!! info
    Introduces ``k - 2`` new variables ``z_{1}, \dots, z_{k-2}`` and ``k - 1`` non-submodular terms.
"""
struct PTR_BG <: QuadratizationMethod end

function quadratize!(
    aux,
    f::PBF{V,T},
    ω::Set{V},
    c::T,
    quad::Quadratization{PTR_BG},
) where {V,T}
    # Degree
    k = length(ω)

    # Fast-track
    k < 3 && return nothing

    # Variables
    s = aux(k - 2)::Vector{V}
    b = collect(ω)::Vector{V}

    # Stabilize
    quad.stable && sort!(b; lt = varlt)

    # Quadratization
    delete!(f, ω)

    f[b[k]×b[k-1]] += c

    for i = 1:(k-2)
        f[s[i]] += c * (k - i - 1)

        f[s[i]×b[i]] += c

        for j = (i+1):k
            f[s[i]×b[j]] -= c
        end
    end

    return f
end

@doc raw"""
    Quadratization{DEFAULT}(stable::Bool = false)

Employs other methods, specifically [`NTR_KZFD`](@ref) and [`PTR_BG`](@ref).
"""
struct DEFAULT <: QuadratizationMethod end

function quadratize!(
    aux,
    f::PBF{V,T},
    ω::Set{V},
    c::T,
    quad::Quadratization{DEFAULT},
) where {V,T}
    if c < zero(T)
        quadratize!(aux, f, ω, c, Quadratization{NTR_KZFD}(quad.stable))
    else
        quadratize!(aux, f, ω, c, Quadratization{PTR_BG}(quad.stable))
    end

    return f
end

function quadratize!(
    aux,
    f::PBF{V,T},
    quad::Quadratization,
) where {V,T}
    # Collect Terms
    Ω = collect(f)

    # Stable Quadratization
    quad.stable && sort!(Ω; by = first, lt = varlt)

    for (ω, c) in Ω
        quadratize!(aux, f, ω, c, quad)
    end

    return f
end

@doc raw"""
    Quadratization{INFER}(stable::Bool = false)
"""
struct INFER <: QuadratizationMethod end

@doc raw"""
    infer_quadratization(f::PBF)

For a given PBF, returns whether it should be quadratized or not, based on its degree.
"""
function infer_quadratization(f::PBF, stable::Bool = false)
    k = degree(f)

    if k <= 2
        return nothing
    else
        # Without any extra knowledge, it is better to
        # quadratize using the default approach
        return Quadratization{DEFAULT}(stable)
    end
end

function quadratize!(aux, f::PBF, quad::Quadratization{INFER})
    quadratize!(aux, f, infer_quadratization(f, quad.stable))

    return f
end

function quadratize!(::Function, f::PBF, ::Nothing)
    return f
end

@doc raw"""
    auxgen(::AbstractFunction{V,T}; name::AbstractString = "aux") where {V<:AbstractString,T}

Creates a function that, when called multiple times, returns the strings `"aux_1"`, `"aux_2"`, ... and so on.

    auxgen(::AbstractFunction{Symbol,T}; name::Symbol = :aux) where {T}

Creates a function that, when called multiple times, returns the symbols `:aux_1`, `:aux_2`, ... and so on.

    auxgen(::AbstractFunction{V,T}; start::V = V(0), step::V = V(-1)) where {V<:Integer,T}

Creates a function that, when called multiple times, returns the integers ``-1``, ``-2``, ... and so on.
"""
function auxgen end

function auxgen(::AbstractFunction{Symbol,T}; name::Symbol = :aux) where {T}
    counter = Int[0]

    function aux(n::Union{Integer,Nothing} = nothing)
        if isnothing(n)
            return first(aux(1))
        else
            return [Symbol("$(name)_$(counter[] += 1)") for _ in 1:n]
        end
    end

    return aux
end

function auxgen(::AbstractFunction{V,T}; name::AbstractString = "aux") where {V<:AbstractString,T}
    counter = Int[0]

    function aux(n::Union{Integer,Nothing} = nothing)
        if isnothing(n)
            return first(aux(1))
        else
            return ["$(name)_$(counter[] += 1)" for _ in 1:n]
        end
    end

    return aux
end

function auxgen(::AbstractFunction{V,T}; start::V = V(0), step::V = V(-1)) where {V<:Integer,T}
    counter = [start]

    function aux(n::Union{Integer,Nothing} = nothing)
        if isnothing(n)
            return first(aux(1))
        else
            return [(counter[] += step) for _ in 1:n]
        end
    end

    return aux
end

function quadratize!(f::PBF, quad::Union{Quadratization,Nothing})
    return quadratize!(auxgen(f), f, quad)
end

function quadratize(aux, f::PBF, quad::Union{Quadratization,Nothing})
    return quadratize!(aux, copy(f), quad)
end

function quadratize(f::PBF, quad::Union{Quadratization,Nothing})
    return quadratize!(copy(f), quad)
end
