using Random

function test_synthesis()
    @testset "Synthesis" verbose = true begin
        test_regular_xorsat_planted_solutions()
        test_quadratized_regular_xorsat_planted_solutions()
        test_quadratization_auxiliary_assignments()
    end

    return nothing
end

function test_regular_xorsat_planted_solutions()
    @testset "Regular XORSAT planted solutions" begin
        for (V, n, k) in ((Int, 4, 2), (Symbol, 6, 3), (Int, 8, 4), (Symbol, 8, 5))
            F = PBO.TermDictPBF{V,Float64}
            rng = Random.MersenneTwister(27 + n)

            f, solutions = PBO.k_regular_k_xorsat(rng, F, n, k)

            @test length(solutions) == 1

            x = only(solutions)

            @test Set(keys(x)) == Set(PBO.varmap(V, i) for i = 1:n)
            @test all(v -> v in (0, 1), values(x))

            y = f(x)

            @test PBO.isconstant(y)
            @test y[nothing] ≈ -n
        end
    end

    return nothing
end

function test_quadratization_auxiliary_assignments()
    @testset "Quadratization auxiliary assignments" begin
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
            end
        end
    end

    return nothing
end

function test_quadratized_regular_xorsat_planted_solutions()
    @testset "Quadratized regular XORSAT planted solutions" begin
        for (V, n, k, seed, quad) in (
            (Int, 6, 3, 33, PBO.Quadratization(PBO.DEFAULT(); stable = true)),
            (Symbol, 6, 3, 34, PBO.Quadratization(PBO.DEFAULT(); stable = true)),
            (Int, 8, 4, 35, PBO.Quadratization(PBO.DEFAULT(); stable = false)),
            (Symbol, 8, 4, 36, PBO.Quadratization(PBO.DEFAULT(); stable = true)),
            (Int, 10, 5, 37, PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = -1)),
        )
            F = PBO.TermDictPBF{V,Float64}

            raw_f, raw_solutions =
                PBO.k_regular_k_xorsat(Random.MersenneTwister(seed), F, n, k)
            f, solutions =
                PBO.k_regular_k_xorsat(Random.MersenneTwister(seed), F, n, k; quad)

            @test f == PBO.quadratize(raw_f, quad)

            raw_x = only(raw_solutions)
            x = only(solutions)

            @test Set(keys(x)) == Set(PBO.variables(f))
            @test all(x[PBO.varmap(V, i)] == raw_x[PBO.varmap(V, i)] for i = 1:n)
            @test all(v -> v in (0, 1), values(x))

            raw_y = raw_f(raw_x)
            y = f(x)

            @test PBO.isconstant(raw_y)
            @test PBO.isconstant(y)
            @test y[nothing] ≈ raw_y[nothing] ≈ -n
        end
    end

    return nothing
end
