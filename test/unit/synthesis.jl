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
        for (V, seed) in ((Int, 33), (Symbol, 34))
            n = 6
            k = 3
            F = PBO.TermDictPBF{V,Float64}
            rng = Random.MersenneTwister(seed)
            quad = PBO.Quadratization(PBO.DEFAULT(); stable = true)

            f, solutions = PBO.k_regular_k_xorsat(rng, F, n, k; quad)
            x = only(solutions)

            @test Set(keys(x)) == Set(PBO.variables(f))
            @test all(v -> v in (0, 1), values(x))

            y = f(x)

            @test PBO.isconstant(y)
            @test y[nothing] ≈ -n
        end
    end

    return nothing
end
