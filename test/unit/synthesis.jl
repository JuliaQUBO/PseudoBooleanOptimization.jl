using Random

function test_synthesis()
    @testset "Synthesis" verbose = true begin
        test_regular_xorsat_planted_solutions()
        test_quadratized_regular_xorsat_planted_solutions()
        test_sherrington_kirkpatrick_synthesis()
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

function test_sherrington_kirkpatrick_synthesis()
    @testset "Sherrington-Kirkpatrick synthesis" begin
        for V in (Int, Symbol)
            F = PBO.TermDictPBF{V,Float64}
            n = 6

            @test_throws ArgumentError PBO.sherrington_kirkpatrick(F, -1)

            f0, sol0 = PBO.sherrington_kirkpatrick(Random.MersenneTwister(11), F, 0)
            @test isempty(f0)
            @test isempty(sol0)

            f_gauge, sol_gauge = PBO.sherrington_kirkpatrick(
                Random.MersenneTwister(42),
                F,
                n;
                normalize = false,
                gauge_invariant = true,
            )
            f_naive, sol_naive = PBO.sherrington_kirkpatrick(
                Random.MersenneTwister(42),
                F,
                n;
                normalize = false,
                gauge_invariant = false,
            )
            f_norm, _ = PBO.sherrington_kirkpatrick(
                Random.MersenneTwister(42),
                F,
                n;
                normalize = true,
                gauge_invariant = true,
            )

            @test isempty(sol_gauge)
            @test isempty(sol_naive)
            @test PBO.degree(f_gauge) == 2
            @test PBO.degree(f_naive) == 2

            # Gauge-invariant SK has zero Ising coercive fields and Z2 bit-flip symmetry
            @test PBO.is_gauge_invariant(f_gauge; atol = 1e-12)
            # Naive SK QUBO omits linear/constant gauge correction and induces O(sqrt(n)) coercive fields
            @test !PBO.is_gauge_invariant(f_naive; atol = 1e-6)
            @test iszero(f_naive[nothing])
            for i = 1:n
                xi = PBO.varmap(V, i)
                @test iszero(f_naive[xi])
            end

            # Projecting the naive SK QUBO via gauge_invariant_qubo recovers the gauge-invariant non-constant form
            f_projected = PBO.gauge_invariant_qubo(f_naive; keep_constant = false)
            f_gauge_zero_const = PBO.gauge_invariant_qubo(f_gauge; keep_constant = false)
            for (ω, c) in f_gauge_zero_const
                @test isapprox(f_projected[ω], c; atol = 1e-12)
            end

            # Normalized SK scales every coefficient by 1 / sqrt(n)
            inv_sqrt_n = 1.0 / sqrt(n)
            for (ω, c) in f_gauge
                @test isapprox(f_norm[ω], c * inv_sqrt_n; atol = 1e-12)
            end

            # Global RNG overload
            f_global, sol_global = PBO.sherrington_kirkpatrick(F, 3; normalize = true)
            @test isempty(sol_global)
            @test PBO.is_gauge_invariant(f_global; atol = 1e-12)

            # Deterministic 2-spin analytical oracle (μ = 1.0, σ = 0.0 => J_{1,2} = 1.0):
            # Gauge-invariant SK must equal 4 x_1 x_2 - 2 x_1 - 2 x_2 + 1 with energies (1, -1, -1, 1)
            x1 = PBO.varmap(V, 1)
            x2 = PBO.varmap(V, 2)
            f_det_gauge, _ = PBO.sherrington_kirkpatrick(
                Random.MersenneTwister(7),
                F,
                2;
                μ = 1.0,
                σ = 0.0,
                normalize = false,
                gauge_invariant = true,
            )
            @test f_det_gauge == F(1.0, x1 => -2.0, x2 => -2.0, [x1, x2] => 4.0)
            @test f_det_gauge(Dict(x1 => 0, x2 => 0))[nothing] == 1.0
            @test f_det_gauge(Dict(x1 => 1, x2 => 0))[nothing] == -1.0
            @test f_det_gauge(Dict(x1 => 0, x2 => 1))[nothing] == -1.0
            @test f_det_gauge(Dict(x1 => 1, x2 => 1))[nothing] == 1.0

            # Naive Boolean SK with μ = 1.0, σ = 0.0 must equal 4 x_1 x_2 with energies (0, 0, 0, 4)
            f_det_naive, _ = PBO.sherrington_kirkpatrick(
                Random.MersenneTwister(7),
                F,
                2;
                μ = 1.0,
                σ = 0.0,
                normalize = false,
                gauge_invariant = false,
            )
            @test f_det_naive == F([x1, x2] => 4.0)
            @test f_det_naive(Dict(x1 => 0, x2 => 0))[nothing] == 0.0
            @test f_det_naive(Dict(x1 => 1, x2 => 0))[nothing] == 0.0
            @test f_det_naive(Dict(x1 => 0, x2 => 1))[nothing] == 0.0
            @test f_det_naive(Dict(x1 => 1, x2 => 1))[nothing] == 4.0

            # Normalized 2-spin SK with μ = 1.0, σ = 0.0 scales J_{1,2} by 1/sqrt(2)
            α2 = inv(sqrt(2.0))
            f_det_norm, _ = PBO.sherrington_kirkpatrick(
                Random.MersenneTwister(7),
                F,
                2;
                μ = 1.0,
                σ = 0.0,
                normalize = true,
                gauge_invariant = true,
            )
            @test isapprox(f_det_norm[nothing], α2; atol = 1e-12)
            @test isapprox(f_det_norm[x1], -2.0 * α2; atol = 1e-12)
            @test isapprox(f_det_norm[x2], -2.0 * α2; atol = 1e-12)
            @test isapprox(f_det_norm[x1, x2], 4.0 * α2; atol = 1e-12)
            @test isapprox(f_det_norm(Dict(x1 => 0, x2 => 0))[nothing], α2; atol = 1e-12)
            @test isapprox(f_det_norm(Dict(x1 => 1, x2 => 0))[nothing], -α2; atol = 1e-12)
            @test isapprox(f_det_norm(Dict(x1 => 0, x2 => 1))[nothing], -α2; atol = 1e-12)
            @test isapprox(f_det_norm(Dict(x1 => 1, x2 => 1))[nothing], α2; atol = 1e-12)
        end
    end

    return nothing
end
