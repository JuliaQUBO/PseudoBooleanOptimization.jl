struct UnsupportedQuadratizationAuxiliaries <: PBO.QuadratizationMethod end
struct CustomWholePolyQuadratization <: PBO.QuadratizationMethod end

function PBO.quadratize!(
    aux,
    f::PBO.AbstractPBF,
    quad::PBO.Quadratization{CustomWholePolyQuadratization},
)
    return PBO.quadratize!(
        aux,
        f,
        PBO.Quadratization(PBO.DEFAULT(); stable = quad.stable, sign = quad.sign),
    )
end

function _all_binary_assignments(vars::Vector{V}) where {V}
    n = length(vars)
    assignments = Vector{Dict{V,Int}}(undef, 1 << n)
    digits_buf = zeros(Int, n)

    for mask = 0:((1 << n) - 1)
        digits!(digits_buf, mask; base = 2)
        assignments[mask + 1] = Dict{V,Int}(vars[i] => digits_buf[i] for i = 1:n)
    end

    return assignments
end

function test_quadratization_auxiliary_completion()
    @testset "Auxiliary assignments" begin
        let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
            for (f, x, quad) in (
                (
                    F((1, 2, 3) => -2.0),
                    Dict{V,Int}(1 => 1, 2 => 1, 3 => 1),
                    PBO.Quadratization(PBO.NTR_KZFD()),
                ),
                (
                    F((1, 2, 3, 4) => 2.0),
                    Dict{V,Int}(1 => 1, 2 => 0, 3 => 1, 4 => 1),
                    PBO.Quadratization(PBO.PTR_BG()),
                ),
                (
                    F((1, 2, 3) => 2.0),
                    Dict{V,Int}(1 => 1, 2 => 1, 3 => 1),
                    PBO.Quadratization(PBO.NTR_KZFD(); sign = -1),
                ),
                (
                    F((1, 2, 3, 4) => -2.0),
                    Dict{V,Int}(1 => 1, 2 => 0, 3 => 1, 4 => 1),
                    PBO.Quadratization(PBO.PTR_BG(); sign = -1),
                ),
                (
                    F((3, 1, 2, 4) => 2.0),
                    Dict{V,Int}(1 => 0, 2 => 1, 3 => 1, 4 => 0),
                    PBO.Quadratization(PBO.DEFAULT(); stable = true),
                ),
                (
                    F((1, 2, 3, 4, 5) => -2.0),
                    Dict{V,Int}(1 => 1, 2 => 0, 3 => 1, 4 => 1, 5 => 0),
                    PBO.Quadratization(PBO.DEFAULT(); sign = -1),
                ),
            )
                original_f = copy(f)
                original_x = copy(x)

                PBO._quadratize_with_solution!(f, x, quad)

                @test f == PBO.quadratize(original_f, quad)
                @test Set(keys(x)) == Set(PBO.variables(f))
                @test all(v -> v in (0, 1), values(x))

                y = f(x)
                original_y = original_f(original_x)

                @test PBO.isconstant(y)
                @test PBO.isconstant(original_y)
                @test y[nothing] ≈ original_y[nothing]

                q_rec, rec = PBO.quadratize(
                    original_f,
                    quad;
                    record = true,
                    original_variables = collect(keys(original_x)),
                )
                @test q_rec == f
                @test PBO.complete_auxiliaries(rec, original_x) == x
            end

            err = try
                PBO._quadratize_with_solution!(
                    F((1, 2, 3) => 2.0),
                    Dict{V,Int}(1 => 1, 2 => 0, 3 => 1),
                    PBO.Quadratization(UnsupportedQuadratizationAuxiliaries()),
                )

                nothing
            catch err
                err
            end

            @test err isa ArgumentError
            @test occursin("Unsupported quadratization method", sprint(showerror, err))
        end
    end

    @testset "Exhaustive reusable record & completion verification" begin
        let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
            cases = (
                (
                    F(() => 3.5, 1 => -1.0, (1, 2) => 2.0, (1, 2, 3) => -4.0),
                    PBO.Quadratization(PBO.NTR_KZFD(); stable = true, sign = 1),
                ),
                (
                    F(() => -2.0, 2 => 1.5, (1, 2, 3, 4) => -3.0),
                    PBO.Quadratization(PBO.NTR_KZFD(); stable = true, sign = 1),
                ),
                (
                    F(() => 1.0, (1, 2, 3) => 2.5, (1, 2, 3, 4) => 1.5),
                    PBO.Quadratization(PBO.NTR_KZFD(); stable = true, sign = -1),
                ),
                (
                    F(() => -1.0, 1 => 2.0, (1, 2, 3) => 3.0),
                    PBO.Quadratization(PBO.PTR_BG(); stable = true, sign = 1),
                ),
                (
                    F(() => 2.0, (1, 3) => -1.0, (1, 2, 3, 4) => 2.0),
                    PBO.Quadratization(PBO.PTR_BG(); stable = true, sign = 1),
                ),
                (
                    F(() => 0.5, (1, 2, 3) => -2.5, (1, 2, 3, 4) => -1.5),
                    PBO.Quadratization(PBO.PTR_BG(); stable = true, sign = -1),
                ),
                (
                    F(
                        () => 4.0,
                        1 => -2.0,
                        (2, 3) => 1.5,
                        (1, 2, 3) => 3.0,
                        (1, 3, 4) => -2.5,
                        (1, 2, 3, 4) => 2.0,
                    ),
                    PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = 1),
                ),
                (
                    F(
                        () => -3.0,
                        2 => 1.0,
                        (1, 4) => -2.0,
                        (1, 2, 3) => 3.0,
                        (1, 3, 4) => -2.5,
                        (1, 2, 3, 4) => -2.0,
                    ),
                    PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = -1),
                ),
                (
                    F((1, 2, 3, 4, 5) => 1.5, (1, 2, 5) => -2.0),
                    PBO.Quadratization(PBO.DEFAULT(); stable = false, sign = 1),
                ),
            )

            for (f, quad) in cases
                q, rec = PBO.quadratize(f, quad; record = true)

                @test q == PBO.quadratize(f, quad)
                @test isvalid(rec)
                @test isvalid(rec, q)
                @test isvalid(rec, q, quad)
                @test PBO.objective_sense(rec) == quad.sign
                @test PBO.original_function(rec) == f
                @test PBO.quadratized_function(rec) === q

                orig_vars = PBO.original_variables(rec)
                aux_vars = PBO.auxiliary_variables(rec)
                @test orig_vars == PBO.variables(f)
                @test isempty(intersect(orig_vars, aux_vars))
                @test Set(PBO.variables(q)) ⊆ union(Set(orig_vars), Set(aux_vars))

                x_states = _all_binary_assignments(orig_vars)
                y_states = _all_binary_assignments(aux_vars)

                for x in x_states
                    x_snapshot = copy(x)
                    completed = PBO.complete_auxiliaries(rec, x)
                    @test x == x_snapshot
                    @test PBO.complete_auxiliaries(x, rec) == completed
                    @test rec(x) == completed

                    for v in orig_vars
                        @test completed[v] == x[v]
                    end
                    for v in aux_vars
                        @test completed[v] in (0, 1)
                    end

                    fx = convert(T, f(x))
                    qx_star = convert(T, q(completed))
                    @test qx_star ≈ fx

                    all_q_values = T[]
                    for y in y_states
                        raw_state = merge(x, y)
                        raw_snapshot = copy(raw_state)
                        q_raw = convert(T, q(raw_state))
                        push!(all_q_values, q_raw)

                        repaired = PBO.complete_auxiliaries(rec, raw_state)
                        @test raw_state == raw_snapshot
                        @test repaired == completed

                        q_repaired = convert(T, q(repaired))
                        @test quad.sign * q_repaired <= quad.sign * q_raw + 1e-12
                    end

                    best_q = quad.sign == 1 ? minimum(all_q_values) : maximum(all_q_values)
                    @test best_q ≈ fx
                    @test qx_star ≈ best_q

                    # Deterministic tie-breaking: flipping any single auxiliary from 1 to 0
                    # must strictly worsen the signed objective (since ties choose 0).
                    for v in aux_vars
                        if completed[v] == 1
                            alt = copy(completed)
                            alt[v] = 0
                            q_alt = convert(T, q(alt))
                            @test quad.sign * qx_star < quad.sign * q_alt
                        end
                    end
                end
            end
        end
    end

    @testset "Custom auxiliary labels, symbols, zero-aux, and in-place completion" begin
        let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}
            f = F(
                () => 1.0,
                :a => -2.0,
                (:a, :b, :c) => 3.0,
                (:b, :c, :d) => -4.0,
            )
            custom_pool = [:y_ptr_1, :y_ntr_1]
            idx = Ref(0)
            custom_aux = function (n::Union{Integer,Nothing} = nothing)
                if isnothing(n)
                    idx[] += 1
                    return custom_pool[idx[]]
                else
                    out = Symbol[]
                    for _ = 1:n
                        idx[] += 1
                        push!(out, custom_pool[idx[]])
                    end
                    return out
                end
            end

            quad = PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = 1)
            q, rec = PBO.quadratize(custom_aux, f, quad; record = true)

            @test PBO.original_variables(rec) == [:a, :b, :c, :d]
            @test PBO.auxiliary_variables(rec) == [:y_ptr_1, :y_ntr_1]

            steps = PBO.quadratization_steps(rec)
            @test length(steps) == 2
            @test steps[1].term == PBO.Term([:a, :b, :c])
            @test steps[1].coefficient == 3.0
            @test steps[1].method == PBO.PTR_BG()
            @test steps[1].auxiliary_variables == [:y_ptr_1]
            @test steps[2].term == PBO.Term([:b, :c, :d])
            @test steps[2].coefficient == -4.0
            @test steps[2].method == PBO.NTR_KZFD()
            @test steps[2].auxiliary_variables == [:y_ntr_1]

            # Counterexample where naive product y_ptr_1 = a*b*c = 0 gives wrong energy
            raw_sample = Dict(:a => 0, :b => 1, :c => 1, :d => 1, :y_ptr_1 => 0, :y_ntr_1 => 0)
            repaired_sample = PBO.complete_auxiliaries(rec, raw_sample)
            @test raw_sample[:y_ptr_1] == 0
            @test raw_sample[:y_ntr_1] == 0
            @test repaired_sample[:y_ptr_1] == 1
            @test repaired_sample[:y_ntr_1] == 1
            @test convert(T, q(raw_sample)) != convert(T, f(raw_sample))
            @test convert(T, q(repaired_sample)) == convert(T, f(raw_sample))

            # Pair varargs and in-place completion
            @test rec(:a => 0, :b => 1, :c => 1, :d => 1) == repaired_sample
            in_place = Dict(:a => 0, :b => 1, :c => 1, :d => 1)
            @test PBO.complete_auxiliaries!(in_place, rec) === in_place
            @test in_place == repaired_sample

            in_place_2 = Dict(:a => 1, :b => 1, :c => 1, :d => 0)
            @test PBO.complete_auxiliaries!(rec, in_place_2) === in_place_2
            @test convert(T, q(in_place_2)) == convert(T, f(in_place_2))

            # Zero-auxiliary quadratic / constant functions and quad = nothing
            f_quad = F(() => 2.0, :x => -1.0, (:x, :y) => 3.0)
            q_quad, rec_quad = PBO.quadratize(f_quad, quad; record = true)
            @test isempty(PBO.auxiliary_variables(rec_quad))
            @test isempty(PBO.quadratization_steps(rec_quad))
            state_xy = Dict(:x => 1, :y => 0)
            @test PBO.complete_auxiliaries(rec_quad, state_xy) == state_xy
            @test convert(T, q_quad(state_xy)) == convert(T, f_quad(state_xy))

            q_noop, rec_noop = PBO.quadratize!(copy(f_quad), nothing; record = true)
            @test isempty(PBO.auxiliary_variables(rec_noop))
            @test PBO.complete_auxiliaries(rec_noop, state_xy) == state_xy
        end
    end

    @testset "Validation, invalidation, and error handling" begin
        let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
            f = F((1, 2, 3) => 2.0)
            quad = PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = 1)
            q, rec = PBO.quadratize(f, quad; record = true)

            @test occursin("valid", sprint(show, rec))

            # Missing original variable
            bad_missing = Dict(1 => 1, 2 => 1)
            @test_throws ArgumentError PBO.complete_auxiliaries(rec, bad_missing)
            @test_throws ArgumentError PBO.complete_auxiliaries!(bad_missing, rec)
            @test bad_missing == Dict(1 => 1, 2 => 1)

            # Non-binary original or auxiliary values
            @test_throws ArgumentError PBO.complete_auxiliaries(rec, Dict(1 => 2, 2 => 1, 3 => 0))
            @test_throws ArgumentError PBO.complete_auxiliaries(rec, Dict(1 => -1, 2 => 1, 3 => 0))
            @test_throws ArgumentError PBO.complete_auxiliaries(rec, Dict(1 => 0.5, 2 => 1.0, 3 => 0.0))
            @test_throws ArgumentError PBO.complete_auxiliaries(rec, Dict(1 => 1, 2 => 1, 3 => 0, -1 => 2))
            @test_throws ArgumentError PBO.complete_auxiliaries(rec, Dict(:x => 1))

            # Boolean Dict values are accepted and normalized to 0/1 Int
            bool_completed = PBO.complete_auxiliaries(rec, Dict(1 => false, 2 => true, 3 => true))
            @test bool_completed == Dict(1 => 0, 2 => 1, 3 => 1, -1 => 1)

            # Unsupported custom method
            @test_throws ArgumentError PBO.quadratize(
                f,
                PBO.Quadratization(UnsupportedQuadratizationAuxiliaries());
                record = true,
            )

            # Custom aux collisions and wrong count
            @test_throws ArgumentError PBO.quadratize(
                (_ = nothing) -> 1,
                F((1, 2, 3) => -1.0),
                quad;
                record = true,
            )
            @test_throws ArgumentError PBO.quadratize(
                (_ = nothing) -> -1,
                F((1, 2, 3) => -1.0, (1, 2, 4) => -1.0),
                quad;
                record = true,
            )
            @test_throws ArgumentError PBO.quadratize(
                (n = nothing) -> [-1, -2],
                F((1, 2, 3) => 1.0),
                quad;
                record = true,
            )
            @test_throws ArgumentError PBO.quadratize(
                f,
                quad;
                record = true,
                original_variables = [1, 2],
            )

            # Mismatched quad or formulation passed to completion/isvalid
            other_quad = PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = -1)
            @test !isvalid(rec; quad = other_quad)
            @test_throws ArgumentError PBO.complete_auxiliaries(
                rec,
                Dict(1 => 0, 2 => 1, 3 => 1);
                quad = other_quad,
            )
            @test !isvalid(rec, copy(q))
            @test_throws ArgumentError PBO.complete_auxiliaries(
                rec,
                Dict(1 => 0, 2 => 1, 3 => 1);
                qubo = copy(q),
            )
            sym_pbf = PBO.TermDictPBF{Symbol,T}((:x, :y, :z) => 2.0)
            @test !isvalid(rec; original = sym_pbf)
            @test !isvalid(rec; qubo = sym_pbf)
            @test_throws ArgumentError PBO.complete_auxiliaries(
                rec,
                Dict(1 => 0, 2 => 1, 3 => 1);
                original = sym_pbf,
            )
            @test_throws ArgumentError PBO.complete_auxiliaries(
                rec,
                Dict(1 => 0, 2 => 1, 3 => 1);
                qubo = sym_pbf,
            )

            # Invalidation when quadratized coefficients change
            q[-1] += 1.0
            @test !isvalid(rec)
            @test occursin("invalid", sprint(show, rec))
            @test_throws ArgumentError PBO.complete_auxiliaries(rec, Dict(1 => 0, 2 => 1, 3 => 1))

            # Invalidation when original function coefficients change
            f2 = F((1, 2, 3) => 2.0)
            _, rec2 = PBO.quadratize(f2, quad; record = true)
            @test isvalid(rec2)
            f2[(1, 2, 3)] = 5.0
            @test !isvalid(rec2)
            @test_throws ArgumentError PBO.complete_auxiliaries(rec2, Dict(1 => 0, 2 => 1, 3 => 1))

            # Invalidation when in-place quadratized function is modified
            f3 = F((1, 2, 3) => 2.0)
            q3, rec3 = PBO.quadratize!(f3, quad; record = true)
            @test q3 === f3
            @test isvalid(rec3)
            PBO.invalidate!(rec3)
            @test !isvalid(rec3)
            @test_throws ArgumentError PBO.complete_auxiliaries(rec3, Dict(1 => 0, 2 => 1, 3 => 1))

            # Invalidation when mutable (BigFloat) coefficients are mutated in-place
            let BF = PBO.TermDictPBF{Int,BigFloat}
                f_bf_q = BF((1, 2, 3) => big"2.0")
                q_bf, rec_bf_q = PBO.quadratize(f_bf_q, quad; record = true)
                @test isvalid(rec_bf_q)
                PBO.MA.operate!(+, q_bf[-1], big"10.0")
                @test !isvalid(rec_bf_q)
                @test_throws ArgumentError PBO.complete_auxiliaries(
                    rec_bf_q,
                    Dict(1 => 0, 2 => 1, 3 => 1),
                )

                f_bf_orig = BF((1, 2, 3) => big"2.0")
                _, rec_bf_orig = PBO.quadratize(f_bf_orig, quad; record = true)
                @test isvalid(rec_bf_orig)
                PBO.MA.operate!(+, f_bf_orig[(1, 2, 3)], big"10.0")
                @test !isvalid(rec_bf_orig)
                @test_throws ArgumentError PBO.complete_auxiliaries(
                    rec_bf_orig,
                    Dict(1 => 0, 2 => 1, 3 => 1),
                )
            end

            # Custom whole-polynomial quadratize! overload compatibility
            custom_whole_quad = PBO.Quadratization(CustomWholePolyQuadratization(); stable = true, sign = 1)
            expected_whole = PBO.quadratize(f, quad)
            @test PBO.quadratize(f, custom_whole_quad) == expected_whole
            @test PBO.quadratize(PBO.vargen(f; start = -1, step = -1), f, custom_whole_quad) == expected_whole
            f_whole_inplace = copy(f)
            @test PBO.quadratize!(f_whole_inplace, custom_whole_quad) == expected_whole
            @test_throws ArgumentError PBO.quadratize(f, custom_whole_quad; record = true)
        end
    end

    return nothing
end

function test_NTR_KZFD()
    @testset "→ NTR-KZFD" begin
        @testset "∴ TermDict/Symbol" begin
            let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}

                let f = F([:x, :y, :z] => -1.0)
                    q = PBO.quadratize(f, PBO.Quadratization(PBO.NTR_KZFD(); stable = true))

                    @test q == F([
                        :aux_1       => 2.0,
                        (:x, :aux_1) => -1.0,
                        (:y, :aux_1) => -1.0,
                        (:z, :aux_1) => -1.0,
                    ])
                end

                let g = F([:x, :y, :z, :w] => -2.0)
                    q = PBO.quadratize(g, PBO.Quadratization(PBO.NTR_KZFD(); stable = true))

                    @test q == F([
                        :aux_1       => 6.0,
                        (:x, :aux_1) => -2.0,
                        (:y, :aux_1) => -2.0,
                        (:z, :aux_1) => -2.0,
                        (:w, :aux_1) => -2.0,
                    ])
                end

                let f = F([:x, :y, :z] => 1.0)
                    q = PBO.quadratize(
                        f,
                        PBO.Quadratization(PBO.NTR_KZFD(); stable = true, sign = -1),
                    )

                    @test q == F([
                        :aux_1       => -2.0,
                        (:x, :aux_1) => 1.0,
                        (:y, :aux_1) => 1.0,
                        (:z, :aux_1) => 1.0,
                    ])
                end

                @test_throws AssertionError PBO.quadratize(
                    F([:x, :y, :z] => -1.0),
                    PBO.Quadratization(PBO.NTR_KZFD(); stable = true, sign = -1),
                )
            end
        end
    end

    return nothing
end

function test_PTR_BG()
    @testset "→ PTR-BG" begin
        @testset "∴ TermDict/Symbol" begin
            let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}

                f = F([[:x, :y, :z] => 1.0])
                q = PBO.quadratize(f, PBO.Quadratization(PBO.PTR_BG(); stable = true))

                @test q == F([
                    :aux_1       => 1.0,
                    (:x, :aux_1) => 1.0,
                    (:y, :aux_1) => -1.0,
                    (:z, :aux_1) => -1.0,
                    (:y, :z)     => 1.0,
                ])

                let g = F([:x, :y, :z, :w] => 2.0)
                    q = PBO.quadratize(g, PBO.Quadratization(PBO.PTR_BG(); stable = true))

                    @test q == F([
                        :aux_1 => 4.0,
                        :aux_2 => 2.0,
                        (:w, :aux_1) => 2.0,
                        (:x, :aux_1) => -2.0,
                        (:y, :aux_1) => -2.0,
                        (:z, :aux_1) => -2.0,
                        (:x, :aux_2) => 2.0,
                        (:y, :aux_2) => -2.0,
                        (:z, :aux_2) => -2.0,
                        (:y, :z) => 2.0,
                    ])
                end

                let f = F([:x, :y, :z] => -1.0)
                    q = PBO.quadratize(
                        f,
                        PBO.Quadratization(PBO.PTR_BG(); stable = true, sign = -1),
                    )

                    @test q == F([
                        :aux_1       => -1.0,
                        (:x, :aux_1) => -1.0,
                        (:y, :aux_1) => 1.0,
                        (:z, :aux_1) => 1.0,
                        (:y, :z)     => -1.0,
                    ])
                end

                @test_throws AssertionError PBO.quadratize(
                    F([:x, :y, :z] => 1.0),
                    PBO.Quadratization(PBO.PTR_BG(); stable = true, sign = -1),
                )
            end

            @testset "∴ TermDict/Integer" begin
                let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
                    f = F(
                        (1, 2, 3)    => 18,
                        (1, 2, 4)    => 40,
                        (1, 3, 4)    => 20,
                        (2, 3, 4)    => 20,
                        (1, 2, 3, 4) => 8,
                    )

                    g = F(
                        -1      => 18,
                        -2      => 40,
                        -3      => 20,
                        -4      => 20,
                        -5      => 16,
                        -6      => 8,
                        (2, 3)  => 18,
                        (2, 4)  => 40,
                        (3, 4)  => 48,
                        (1, -1) => 18,
                        (2, -1) => -18,
                        (3, -1) => -18,
                        (1, -2) => 40,
                        (2, -2) => -40,
                        (4, -2) => -40,
                        (1, -3) => 20,
                        (3, -3) => -20,
                        (4, -3) => -20,
                        (2, -4) => 20,
                        (3, -4) => -20,
                        (4, -4) => -20,
                        (1, -5) => 8,
                        (2, -5) => -8,
                        (3, -5) => -8,
                        (4, -5) => -8,
                        (2, -6) => 8,
                        (3, -6) => -8,
                        (4, -6) => -8,
                    )

                    q = PBO.quadratize(f, PBO.Quadratization(PBO.PTR_BG(); stable = true))

                    @test g == q
                end
            end
        end
    end

    return nothing
end

function test_DEFAULT()
    @testset "→ DEFAULT" begin
        @test_throws ArgumentError PBO.Quadratization(PBO.DEFAULT(); sign = 0)

        @testset "∴ TermDict/Integer" begin
            let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
                let f = F(
                        () => 49,
                        1  => -40,
                        2  => -40,
                        3  => -24,
                        4  => -40,
                        (1, 2) => 32,
                        (1, 3) => 15,
                        (1, 4) => 40,
                        (2, 3) => 15,
                        (2, 4) => 40,
                        (3, 4) => 16,
                        (1, 2, 3) => 18,
                        (1, 2, 4) => 40,
                        (1, 3, 4) => 20,
                        (2, 3, 4) => 20,
                        (1, 2, 3, 4) => 8,
                    )

                    g = F(
                        ()      => 49,
                        1       => -40,
                        2       => -40,
                        3       => -24,
                        4       => -40,
                        -1      => 18,
                        -2      => 40,
                        -3      => 20,
                        -4      => 20,
                        -5      => 16,
                        -6      => 8,
                        (1, 2)  => 32,
                        (1, 3)  => 15,
                        (1, 4)  => 40,
                        (2, 3)  => 33,
                        (2, 4)  => 80,
                        (3, 4)  => 64,
                        (1, -1) => 18,
                        (2, -1) => -18,
                        (3, -1) => -18,
                        (1, -2) => 40,
                        (2, -2) => -40,
                        (4, -2) => -40,
                        (1, -3) => 20,
                        (3, -3) => -20,
                        (4, -3) => -20,
                        (2, -4) => 20,
                        (3, -4) => -20,
                        (4, -4) => -20,
                        (1, -5) => 8,
                        (2, -5) => -8,
                        (3, -5) => -8,
                        (4, -5) => -8,
                        (2, -6) => 8,
                        (3, -6) => -8,
                        (4, -6) => -8,
                    )

                    q = PBO.quadratize(f, PBO.Quadratization(PBO.DEFAULT(); stable = true))

                    @test q == g
                end
            end
        end

        @testset "∴ TermDict/Symbol/Maximization" begin
            let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}
                let f = F([:x, :y, :z] => 1.0)
                    q = PBO.quadratize(
                        f,
                        PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = -1),
                    )

                    @test q == F([
                        :aux_1       => -2.0,
                        (:x, :aux_1) => 1.0,
                        (:y, :aux_1) => 1.0,
                        (:z, :aux_1) => 1.0,
                    ])

                    for x in 0:1, y in 0:1, z in 0:1
                        ξ = Dict(:x => x, :y => y, :z => z)
                        @test maximum(
                            convert(T, q(merge(ξ, Dict(:aux_1 => s)))) for s in 0:1
                        ) == convert(T, f(ξ))
                    end
                end

                let f = F([:x, :y, :z] => -1.0)
                    q = PBO.quadratize(
                        f,
                        PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = -1),
                    )

                    @test q == F([
                        :aux_1       => -1.0,
                        (:x, :aux_1) => -1.0,
                        (:y, :aux_1) => 1.0,
                        (:z, :aux_1) => 1.0,
                        (:y, :z)     => -1.0,
                    ])

                    for x in 0:1, y in 0:1, z in 0:1
                        ξ = Dict(:x => x, :y => y, :z => z)
                        @test maximum(
                            convert(T, q(merge(ξ, Dict(:aux_1 => s)))) for s in 0:1
                        ) == convert(T, f(ξ))
                    end
                end
            end
        end
    end

    return nothing
end

function test_quadratization()
    @testset "⊛ Quadratization" begin
        test_quadratization_auxiliary_completion()
        test_NTR_KZFD()
        test_PTR_BG()
        test_DEFAULT()
    end

    return nothing
end
