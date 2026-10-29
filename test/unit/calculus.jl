function test_calculus()
    @testset "⊛ Calculus" verbose = true begin
        @testset "∴ TermDict" begin
            @testset "→ Derivatives" begin
                let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}
                    f = F(
                        -1.0,
                        :x => 2.0,
                        :y => -3.0,
                        :z => 4.0,
                        :w => -5.0,
                        [:x, :y] => 6.0,
                        [:x, :z] => -7.0,
                        [:x, :w] => 8.0,
                        [:y, :z] => -9.0,
                        [:y, :w] => 10.0,
                        [:z, :w] => -11.0,
                        [:x, :y, :z] => 12.0,
                        [:x, :y, :w] => -13.0,
                        [:x, :z, :w] => 14.0,
                        [:y, :z, :w] => -15.0,
                        [:x, :y, :z, :w] => 16.0,
                    )

                    fx = F(
                        2.0,
                        :y => 6.0,
                        :z => -7.0,
                        :w => 8.0,
                        [:y, :z] => 12.0,
                        [:y, :w] => -13.0,
                        [:z, :w] => 14.0,
                        [:y, :z, :w] => 16.0,
                    )

                    fy = F(
                        -3.0,
                        :x => 6.0,
                        :z => -9.0,
                        :w => 10.0,
                        [:x, :z] => 12.0,
                        [:x, :w] => -13.0,
                        [:z, :w] => -15.0,
                        [:x, :z, :w] => 16.0,
                    )

                    fz = F(
                        4.0,
                        :x => -7.0,
                        :y => -9.0,
                        :w => -11.0,
                        [:x, :y] => 12.0,
                        [:x, :w] => 14.0,
                        [:y, :w] => -15.0,
                        [:x, :y, :w] => 16.0,
                    )

                    fw = F(
                        -5.0,
                        :x => 8.0,
                        :y => 10.0,
                        :z => -11.0,
                        [:x, :y] => -13.0,
                        [:x, :z] => 14.0,
                        [:y, :z] => -15.0,
                        [:x, :y, :z] => 16.0,
                    )

                    @test PBO.derivative(f, :x) == fx
                    @test PBO.derivative(f, :y) == fy
                    @test PBO.derivative(f, :z) == fz
                    @test PBO.derivative(f, :w) == fw
                    @test PBO.derivative(f, :u) == zero(F)

                    @test PBO.gradient(f, [:x, :y, :z, :w]) == [fx, fy, fz, fw]

                    # Degree > 2 rejection for quadratic coercive-field & gauge-invariance tools
                    @test_throws ArgumentError PBO.coercive_field(f, :x)
                    @test_throws ArgumentError PBO.coercive_fields(f)
                    @test_throws ArgumentError PBO.is_gauge_invariant(f)
                    @test_throws ArgumentError PBO.gauge_invariant_qubo(f)
                    @test_throws ArgumentError PBO.gauge_invariant_qubo!(copy(f))
                end
            end

            @testset "→ Coercive fields and Z2 gauge invariance" begin
                let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}
                    # q = -3.0 + 2.0 x - 4.0 y + 1.0 z + 8.0 x y - 12.0 x z + 4.0 y z
                    # h_x = 0.5*(2.0) + 0.25*(8.0 - 12.0) = 1.0 - 1.0 = 0.0
                    # h_y = 0.5*(-4.0) + 0.25*(8.0 + 4.0) = -2.0 + 3.0 = 1.0
                    # h_z = 0.5*(1.0) + 0.25*(-12.0 + 4.0) = 0.5 - 2.0 = -1.5
                    # Isolated linear term :w => 6.0 has h_w = 3.0
                    q = F(
                        -3.0,
                        :x => 2.0,
                        :y => -4.0,
                        :z => 1.0,
                        :w => 6.0,
                        [:x, :y] => 8.0,
                        [:x, :z] => -12.0,
                        [:y, :z] => 4.0,
                    )

                    @test PBO.coercive_field(q, :x) == 0.0
                    @test PBO.coercive_field(q, :y) == 1.0
                    @test PBO.coercive_field(q, :z) == -1.5
                    @test PBO.coercive_field(q, :w) == 3.0
                    @test PBO.coercive_field(q, :unused) == 0.0

                    fields = PBO.coercive_fields(q)
                    @test fields == Dict(:x => 0.0, :y => 1.0, :z => -1.5, :w => 3.0)
                    @test !PBO.is_gauge_invariant(q)
                    @test !PBO.is_gauge_invariant(q; atol = 1.0)
                    @test PBO.is_gauge_invariant(q; atol = 3.0)
                    @test_throws ArgumentError PBO.is_gauge_invariant(q; atol = -1e-6)
                    @test_throws ArgumentError PBO.is_gauge_invariant(q; atol = NaN)

                    g = PBO.gauge_invariant_qubo(q)
                    # Original q is unmutated
                    @test PBO.coercive_field(q, :y) == 1.0
                    @test q[:w] == 6.0
                    # Projected g has zero coercive fields and preserves constant + quadratic terms
                    @test PBO.is_gauge_invariant(g)
                    @test all(iszero, values(PBO.coercive_fields(g)))
                    @test g[nothing] == -3.0
                    @test g[:x, :y] == 8.0
                    @test g[:x, :z] == -12.0
                    @test g[:y, :z] == 4.0
                    @test g[:x] == 2.0
                    @test g[:y] == -6.0
                    @test g[:z] == 4.0
                    @test g[:w] == 0.0

                    # Exhaustive Z2 bit-flip symmetry: g(1 - x) == g(x) for all x in {0, 1}^3
                    vars = PBO.variables(g)
                    for mask = 0:((1 << length(vars)) - 1)
                        x_assign = Dict(vars[i] => ((mask >> (i - 1)) & 1) for i in eachindex(vars))
                        x_flip = Dict(v => 1 - b for (v, b) in x_assign)
                        @test g(x_assign)[nothing] ≈ g(x_flip)[nothing]
                    end

                    g0 = PBO.gauge_invariant_qubo(q; keep_constant = false)
                    @test PBO.is_gauge_invariant(g0)
                    @test g0[nothing] == 0.0
                    @test g0(Dict(:x => 0, :y => 0, :z => 0))[nothing] == 0.0
                    @test g0(Dict(:x => 1, :y => 1, :z => 1))[nothing] == 0.0
                end

                # Integer and Rational PBFs
                let F_int = PBO.TermDictPBF{Int,Int}, F_rat = PBO.TermDictPBF{Int,Rational{Int}}
                    q_even = F_int(1 => 3, (1, 2) => 4, (2, 3) => -6)
                    @test !PBO.is_gauge_invariant(q_even)
                    PBO.gauge_invariant_qubo!(q_even)
                    @test PBO.is_gauge_invariant(q_even)
                    @test q_even[1] == -2
                    @test q_even[2] == 1
                    @test q_even[3] == 3

                    # Odd row sum cannot be divided by 2 in an integer PBF; must throw atomically
                    q_odd = F_int(1 => 5, (1, 2) => 3)
                    @test_throws ArgumentError PBO.gauge_invariant_qubo!(q_odd)
                    @test q_odd[1] == 5
                    @test q_odd[1, 2] == 3

                    q_rat = F_rat(1 => 5//1, (1, 2) => 3//1)
                    g_rat = PBO.gauge_invariant_qubo(q_rat; keep_constant = false)
                    @test PBO.is_gauge_invariant(g_rat)
                    @test g_rat[1] == -3//2
                    @test g_rat[2] == -3//2
                    @test PBO.coercive_field(g_rat, 1) == 0//1
                end
            end
        end
    end

    return nothing
end
