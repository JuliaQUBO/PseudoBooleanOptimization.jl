using Random

function test_synthesis()
    @testset "Synthesis" verbose = true begin
        test_regular_xorsat_planted_solutions()
        test_quadratized_regular_xorsat_planted_solutions()
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
