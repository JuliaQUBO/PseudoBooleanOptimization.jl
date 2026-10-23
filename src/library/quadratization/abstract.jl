_clone_value(x) = isbits(x) ? x : deepcopy(MA.copy_if_mutable(x))

function _snapshot_pbf(f::F)::F where {V,T,F<:AbstractPBF{V,T}}
    g = copy(f)
    isbitstype(T) && isbitstype(V) && return g

    empty!(g)
    sizehint!(g, length(f))
    for (ω, c) in f
        g[Term{V}(V[_clone_value(v) for v in ω])] = _clone_value(c)
    end

    return g
end

@doc raw"""
    QuadratizationStep{V,T,M<:QuadratizationMethod}

Records the quadratization of a single higher-degree pseudo-Boolean term.

## Fields
- `term::Term{V}`: original higher-degree term ``\omega`` with ``|\omega| > 2``.
- `coefficient::T`: coefficient ``c_\omega`` in the original pseudo-Boolean function.
- `method::M`: concrete [`QuadratizationMethod`](@ref) selected to reduce ``c_\omega \prod_{j \in \omega} x_j``.
- `auxiliary_variables::Vector{V}`: auxiliary variable labels allocated for this term, in allocation order.
"""
struct QuadratizationStep{V,T,M<:QuadratizationMethod}
    term::Term{V}
    coefficient::T
    method::M
    auxiliary_variables::Vector{V}

    function QuadratizationStep{V,T,M}(
        term::Term{V},
        coefficient::T,
        method::M,
        auxiliary_variables::Vector{V},
    ) where {V,T,M<:QuadratizationMethod}
        return new{V,T,M}(
            Term{V}(V[_clone_value(v) for v in term]),
            _clone_value(coefficient),
            method,
            V[_clone_value(v) for v in auxiliary_variables],
        )
    end
end

function QuadratizationStep(
    term::Term{V},
    coefficient::T,
    method::M,
    auxiliary_variables::Vector{V},
) where {V,T,M<:QuadratizationMethod}
    return QuadratizationStep{V,T,M}(term, coefficient, method, auxiliary_variables)
end

@doc raw"""
    QuadratizationRecord{V,T,F<:AbstractPBF{V,T}}

Reusable record of a quadratization ``\mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y})``
capturing the original variable set, allocated auxiliary variable labels,
per-term reduction steps, objective sense, and snapshots of the associated
formulation.

Use [`complete_auxiliaries`](@ref) or [`complete_auxiliaries!`](@ref) to compute
an optimal auxiliary assignment ``\mathbf{y}^{*}(\mathbf{x})`` conditioned on a
fixed binary assignment ``\mathbf{x} \in \mathbb{B}^{n}`` such that
``\mathcal{Q}\{f\}(\mathbf{x}, \mathbf{y}^{*}) = f(\mathbf{x})``.

!!! note
    Auxiliary variables introduced by reductions such as [`PTR_BG`](@ref) are not
    necessarily simple products of the original variables. Completing
    quadratization auxiliaries optimizes ``\mathbf{y}`` **conditionally on a
    fixed** ``\mathbf{x}``; it neither finds a global optimum of ``f`` nor
    repairs original model constraints or integer/slack encodings.
"""
struct QuadratizationRecord{V,T,F<:AbstractPBF{V,T}}
    original_variables::Vector{V}
    auxiliary_variables::Vector{V}
    steps::Vector{QuadratizationStep{V,T}}
    sign::Int
    quadratization::Union{Quadratization,Nothing}
    original::Union{F,Nothing}
    original_snapshot::F
    qubo::F
    qubo_snapshot::F
    valid::Base.RefValue{Bool}

    function QuadratizationRecord{V,T,F}(
        original_variables::Vector{V},
        auxiliary_variables::Vector{V},
        steps::Vector{QuadratizationStep{V,T}},
        sign::Integer,
        quadratization::Union{Quadratization,Nothing},
        original::Union{F,Nothing},
        original_snapshot::F,
        qubo::F,
        qubo_snapshot::F,
        valid::Base.RefValue{Bool} = Ref(true),
    ) where {V,T,F<:AbstractPBF{V,T}}
        if !(sign in (-1, 1))
            throw(ArgumentError("Quadratization sign must be either -1 or 1"))
        end

        return new{V,T,F}(
            V[_clone_value(v) for v in original_variables],
            V[_clone_value(v) for v in auxiliary_variables],
            QuadratizationStep{V,T}[
                QuadratizationStep(s.term, s.coefficient, s.method, s.auxiliary_variables)
                for s in steps
            ],
            Int(sign),
            quadratization,
            original,
            _snapshot_pbf(original_snapshot),
            qubo,
            _snapshot_pbf(qubo_snapshot),
            valid,
        )
    end
end

_supports_auxiliary_completion(::QuadratizationMethod) = false

function _select_term_quadratization(
    ::AbstractTerm,
    c,
    quad::Quadratization,
)
    return quad
end

function _same_pbf(f::AbstractPBF{V,Tf}, g::AbstractPBF{V,Tg}) where {V,Tf,Tg}
    length(f) == length(g) || return false

    for (ω, c) in f
        haskey(g, ω) || return false
        isequal(g[ω], c) || return false
    end

    return true
end

function _normalize_original_variables(
    f::AbstractPBF{V,T},
    original_variables = nothing,
)::Vector{V} where {V,T}
    f_vars = variables(f)
    if isnothing(original_variables)
        return f_vars
    end

    orig_vars = V[_clone_value(v) for v in original_variables]
    sortunique!(orig_vars; lt = varlt)
    orig_set = Set{V}(orig_vars)

    for v in f_vars
        if !(v in orig_set)
            throw(
                ArgumentError(
                    "Function variable $(repr(v)) is missing from the provided original_variables collection",
                ),
            )
        end
    end

    return orig_vars
end

function original_variables(record::QuadratizationRecord{V}) where {V}
    return V[_clone_value(v) for v in record.original_variables]
end

function auxiliary_variables(record::QuadratizationRecord{V}) where {V}
    return V[_clone_value(v) for v in record.auxiliary_variables]
end

function quadratization_steps(record::QuadratizationRecord{V,T}) where {V,T}
    return QuadratizationStep{V,T}[
        QuadratizationStep(s.term, s.coefficient, s.method, s.auxiliary_variables)
        for s in record.steps
    ]
end

function objective_sense(record::QuadratizationRecord)
    return record.sign
end

function original_function(record::QuadratizationRecord)
    _validate_record(record)
    return _snapshot_pbf(record.original_snapshot)
end

function quadratized_function(record::QuadratizationRecord)
    _validate_record(record)
    return record.qubo
end

function invalidate!(record::QuadratizationRecord)
    record.valid[] = false
    return record
end

function Base.isvalid(
    record::QuadratizationRecord{V,T,F};
    qubo::Union{AbstractPBF,Nothing} = nothing,
    original::Union{AbstractPBF,Nothing} = nothing,
    quad = missing,
) where {V,T,F<:AbstractPBF{V,T}}
    record.valid[] || return false
    record.sign in (-1, 1) || return false

    if !isnothing(record.quadratization) && record.sign != record.quadratization.sign
        return false
    end

    if !ismissing(quad) && quad != record.quadratization
        return false
    end

    if !isnothing(record.original) && !_same_pbf(record.original, record.original_snapshot)
        return false
    end

    if !isnothing(original) && !_same_pbf(original, record.original_snapshot)
        return false
    end

    if !_same_pbf(record.qubo, record.qubo_snapshot)
        return false
    end

    if !isnothing(qubo) && (qubo !== record.qubo || !_same_pbf(qubo, record.qubo_snapshot))
        return false
    end

    orig_set = Set{V}(record.original_variables)
    if length(orig_set) != length(record.original_variables)
        return false
    end

    for v in variables(record.original_snapshot)
        v in orig_set || return false
    end

    expected_step_count =
        isnothing(record.quadratization) ? 0 :
        count(kv -> length(kv[1]) > 2, record.original_snapshot)
    length(record.steps) == expected_step_count || return false

    seen_aux = Set{V}()
    flat_aux = V[]

    for step in record.steps
        length(step.term) > 2 || return false
        haskey(record.original_snapshot, step.term) || return false
        isequal(record.original_snapshot[step.term], step.coefficient) || return false
        _supports_auxiliary_completion(step.method) || return false

        if !isnothing(record.quadratization)
            expected_quad = _select_term_quadratization(
                step.term,
                step.coefficient,
                record.quadratization,
            )
            step.method == expected_quad.method || return false
        end

        for v in step.auxiliary_variables
            (v in orig_set || v in seen_aux) && return false
            push!(seen_aux, v)
            push!(flat_aux, v)
        end
    end

    return record.auxiliary_variables == flat_aux
end

function Base.isvalid(
    record::QuadratizationRecord,
    qubo::AbstractPBF,
    quad = missing,
)
    return isvalid(record; qubo, quad)
end

function _validate_record(
    record::QuadratizationRecord;
    qubo::Union{AbstractPBF,Nothing} = nothing,
    original::Union{AbstractPBF,Nothing} = nothing,
    quad = missing,
)
    if !record.valid[]
        throw(ArgumentError("QuadratizationRecord has been explicitly invalidated"))
    end

    if !ismissing(quad) && quad != record.quadratization
        throw(
            ArgumentError(
                "QuadratizationRecord was created with $(repr(record.quadratization)), which does not match $(repr(quad))",
            ),
        )
    end

    if !isnothing(record.original) && !_same_pbf(record.original, record.original_snapshot)
        throw(
            ArgumentError(
                "QuadratizationRecord is invalid because the original function was modified after quadratization",
            ),
        )
    end

    if !isnothing(original) && !_same_pbf(original, record.original_snapshot)
        throw(
            ArgumentError(
                "Provided original function does not match the QuadratizationRecord snapshot",
            ),
        )
    end

    if !_same_pbf(record.qubo, record.qubo_snapshot)
        throw(
            ArgumentError(
                "QuadratizationRecord is invalid because the quadratized function was modified after quadratization",
            ),
        )
    end

    if !isnothing(qubo) && (qubo !== record.qubo || !_same_pbf(qubo, record.qubo_snapshot))
        throw(
            ArgumentError(
                "Provided quadratized function is not the unmodified formulation associated with this QuadratizationRecord",
            ),
        )
    end

    if !isvalid(record; qubo, original, quad)
        throw(
            ArgumentError(
                "QuadratizationRecord metadata is inconsistent with the recorded formulation",
            ),
        )
    end

    return nothing
end

function Base.show(io::IO, record::QuadratizationRecord{V,T,F}) where {V,T,F}
    status = isvalid(record) ? "valid" : "invalid"
    print(
        io,
        "QuadratizationRecord{$V,$T}(",
        length(record.original_variables),
        " original, ",
        length(record.auxiliary_variables),
        " auxiliary, ",
        length(record.steps),
        " steps, sign=",
        record.sign,
        ", ",
        status,
        ")",
    )
    return nothing
end

function _quadratize_impl!(
    aux,
    f::F,
    quad::Union{Quadratization,Nothing};
    record::Bool = false,
    original_variables = nothing,
    tracked_original::Union{F,Nothing} = nothing,
) where {V,T,F<:AbstractPBF{V,T}}
    if !record
        if !isnothing(original_variables)
            _normalize_original_variables(f, original_variables)
        end

        if isnothing(quad)
            return f
        end

        Ω = collect(f)
        quad.stable && sort!(Ω; by = first, lt = varlt)

        for (ω, c) in Ω
            if length(ω) > 2
                quadratize!(aux, f, ω, c, quad)
            end
        end

        return f
    end

    orig_vars = _normalize_original_variables(f, original_variables)
    orig_set = Set{V}(orig_vars)
    orig_snapshot = _snapshot_pbf(f)
    steps = QuadratizationStep{V,T}[]
    all_aux = V[]
    seen_aux = Set{V}()

    if !isnothing(quad)
        if !_supports_auxiliary_completion(quad.method)
            throw(
                ArgumentError(
                    "Unsupported quadratization method $(typeof(quad.method)) for auxiliary completion",
                ),
            )
        end

        Ω = collect(f)
        quad.stable && sort!(Ω; by = first, lt = varlt)

        for (ω, c) in Ω
            length(ω) > 2 || continue

            c_snapshot = _clone_value(c)
            term_quad = _select_term_quadratization(ω, c_snapshot, quad)
            if !_supports_auxiliary_completion(term_quad.method)
                throw(
                    ArgumentError(
                        "Unsupported quadratization method $(typeof(term_quad.method)) for auxiliary completion",
                    ),
                )
            end

            term_aux_vars = V[]
            recording_aux = function (n::Union{Integer,Nothing} = nothing)
                if isnothing(n)
                    v_raw = aux()
                    v = v_raw isa V ? v_raw : convert(V, v_raw)::V
                    if v in orig_set
                        throw(
                            ArgumentError(
                                "Auxiliary variable $(repr(v)) collides with an original variable",
                            ),
                        )
                    elseif v in seen_aux
                        throw(
                            ArgumentError(
                                "Duplicate auxiliary variable $(repr(v)) allocated during quadratization",
                            ),
                        )
                    end
                    push!(seen_aux, v)
                    push!(term_aux_vars, v)
                    push!(all_aux, v)
                    return v
                else
                    n < 0 && throw(
                        ArgumentError(
                            "Auxiliary variable count must be non-negative, got $n",
                        ),
                    )
                    vs_raw = aux(n)
                    vs = V[v isa V ? v : convert(V, v)::V for v in vs_raw]
                    if length(vs) != n
                        throw(
                            ArgumentError(
                                "Auxiliary allocator returned $(length(vs)) variables, expected $n",
                            ),
                        )
                    end
                    for v in vs
                        if v in orig_set
                            throw(
                                ArgumentError(
                                    "Auxiliary variable $(repr(v)) collides with an original variable",
                                ),
                            )
                        elseif v in seen_aux
                            throw(
                                ArgumentError(
                                    "Duplicate auxiliary variable $(repr(v)) allocated during quadratization",
                                ),
                            )
                        end
                        push!(seen_aux, v)
                        push!(term_aux_vars, v)
                        push!(all_aux, v)
                    end
                    return vs
                end
            end

            quadratize!(recording_aux, f, ω, c_snapshot, term_quad)
            push!(
                steps,
                QuadratizationStep(
                    Term{V}(collect(ω)),
                    c_snapshot,
                    term_quad.method,
                    term_aux_vars,
                ),
            )
        end
    end

    sign = isnothing(quad) ? 1 : quad.sign
    qubo_snapshot = _snapshot_pbf(f)
    rec = QuadratizationRecord{V,T,F}(
        orig_vars,
        all_aux,
        steps,
        sign,
        quad,
        tracked_original,
        orig_snapshot,
        f,
        qubo_snapshot,
    )

    return (f, rec)
end

function quadratize!(
    aux,
    f::AbstractPBF{V,T},
    quad::Quadratization;
    record::Bool = false,
    original_variables = nothing,
) where {V,T}
    return _quadratize_impl!(aux, f, quad; record, original_variables)
end

function quadratize!(
    aux,
    f::AbstractPBF{V,T},
    ::Nothing;
    record::Bool = false,
    original_variables = nothing,
) where {V,T}
    return _quadratize_impl!(aux, f, nothing; record, original_variables)
end

function quadratize!(
    f::AbstractPBF,
    quad::Union{Quadratization,Nothing} = Quadratization(DEFAULT());
    record::Bool = false,
    original_variables = nothing,
)
    aux = vargen(f; start = -1, step = -1)
    if !record
        if !isnothing(original_variables)
            _normalize_original_variables(f, original_variables)
        end
        return quadratize!(aux, f, quad)
    end
    return _quadratize_impl!(aux, f, quad; record = true, original_variables)
end

function quadratize(
    aux,
    f::AbstractPBF,
    quad::Union{Quadratization,Nothing} = Quadratization(DEFAULT());
    record::Bool = false,
    original_variables = nothing,
)
    if !record
        if !isnothing(original_variables)
            _normalize_original_variables(f, original_variables)
        end
        return quadratize!(aux, _snapshot_pbf(f), quad)
    end
    return _quadratize_impl!(
        aux,
        _snapshot_pbf(f),
        quad;
        record = true,
        original_variables,
        tracked_original = f,
    )
end

function quadratize(
    f::AbstractPBF,
    quad::Union{Quadratization,Nothing} = Quadratization(DEFAULT());
    record::Bool = false,
    original_variables = nothing,
)
    if !record
        if !isnothing(original_variables)
            _normalize_original_variables(f, original_variables)
        end
        return quadratize!(_snapshot_pbf(f), quad)
    end
    return quadratize(
        vargen(f; start = -1, step = -1),
        f,
        quad;
        record = true,
        original_variables,
    )
end

function _binary_int(val, v)::Int
    if val isa Bool
        return Int(val)
    elseif val isa Integer && (val == 0 || val == 1)
        return Int(val)
    else
        throw(
            ArgumentError(
                "Non-binary value $(repr(val)) for variable $(repr(v)); expected 0 or 1",
            ),
        )
    end
end

function _validated_assignment(
    record::QuadratizationRecord{V,T},
    assignment::AbstractDict,
)::Dict{V,Int} where {V,T}
    state = Dict{V,Int}()
    sizehint!(state, length(assignment) + length(record.auxiliary_variables))

    for (k, raw_v) in pairs(assignment)
        if !(k isa V)
            throw(
                ArgumentError(
                    "Invalid variable key $(repr(k)) of type $(typeof(k)); expected $V",
                ),
            )
        end
        state[k] = _binary_int(raw_v, k)
    end

    for v in record.original_variables
        if !haskey(state, v)
            throw(
                ArgumentError(
                    "Missing binary assignment for original variable $(repr(v))",
                ),
            )
        end
    end

    return state
end

function _complete_term_auxiliaries!(
    solution::AbstractDict{V,Int},
    variables::AbstractVector{V},
    ω::AbstractTerm{V},
    c::T,
    quad::Quadratization,
) where {V,T}
    throw(
        ArgumentError(
            "Unsupported quadratization method $(typeof(quad.method)) for auxiliary completion",
        ),
    )
end

function complete_auxiliaries(
    record::QuadratizationRecord{V,T},
    assignment::AbstractDict;
    qubo::Union{AbstractPBF,Nothing} = nothing,
    original::Union{AbstractPBF,Nothing} = nothing,
    quad = missing,
)::Dict{V,Int} where {V,T}
    _validate_record(record; qubo, original, quad)
    state = _validated_assignment(record, assignment)
    stable = !isnothing(record.quadratization) && record.quadratization.stable

    for step in record.steps
        step_quad = Quadratization(step.method; stable, sign = record.sign)
        _complete_term_auxiliaries!(
            state,
            step.auxiliary_variables,
            step.term,
            step.coefficient,
            step_quad,
        )
    end

    return state
end

function complete_auxiliaries(
    assignment::AbstractDict,
    record::QuadratizationRecord;
    kwargs...,
)
    return complete_auxiliaries(record, assignment; kwargs...)
end

function complete_auxiliaries(
    record::QuadratizationRecord{V},
    ps::Pair...;
    kwargs...,
) where {V}
    assignment = Dict{Any,Any}()
    for (k, v) in ps
        assignment[k] = v
    end
    return complete_auxiliaries(record, assignment; kwargs...)
end

function complete_auxiliaries!(
    assignment::AbstractDict,
    record::QuadratizationRecord{V,T};
    qubo::Union{AbstractPBF,Nothing} = nothing,
    original::Union{AbstractPBF,Nothing} = nothing,
    quad = missing,
) where {V,T}
    completed = complete_auxiliaries(record, assignment; qubo, original, quad)

    for (v, val) in completed
        assignment[v] = val
    end

    return assignment
end

function complete_auxiliaries!(
    record::QuadratizationRecord,
    assignment::AbstractDict;
    kwargs...,
)
    return complete_auxiliaries!(assignment, record; kwargs...)
end

function (record::QuadratizationRecord)(assignment::AbstractDict; kwargs...)
    return complete_auxiliaries(record, assignment; kwargs...)
end

function (record::QuadratizationRecord)(ps::Pair...; kwargs...)
    return complete_auxiliaries(record, ps...; kwargs...)
end

function _quadratization_auxiliaries!(
    aux,
    solution::Dict{V,Int},
    ω::AbstractTerm{V},
    c::T,
    quad::Quadratization,
) where {V,T}
    throw(
        ArgumentError(
            "Unsupported quadratization method $(typeof(quad.method)) for planted solution completion",
        ),
    )
end

function _quadratize_with_solution!(
    f::AbstractPBF{V,T},
    solution::Dict{V,Int},
    quad::Union{Quadratization,Nothing},
) where {V,T}
    isnothing(quad) && return f

    _, record = quadratize!(
        vargen(f; start = -1, step = -1),
        f,
        quad;
        record = true,
        original_variables = collect(keys(solution)),
    )
    complete_auxiliaries!(solution, record)

    return f
end
