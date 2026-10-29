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

                    # Overflow-safe integer row sums and invariance checks
                    f_typemin = F_int(1 => typemin(Int))
                    @test !PBO.is_gauge_invariant(f_typemin)
                    @test !PBO.is_gauge_invariant(f_typemin; atol = 1.0)
                    @test PBO.coercive_field(f_typemin, 1) == Float64(BigInt(typemin(Int)) // 2)
                    @test PBO.coercive_fields(f_typemin)[1] == Float64(BigInt(typemin(Int)) // 2)

                    # Int8 row sum overflow (120 + 8 = 128) where -128/2 = -64 is representable in Int8
                    F_i8 = PBO.TermDictPBF{Int,Int8}
                    f_i8_rep = F_i8((1, 2) => Int8(120), (1, 3) => Int8(8))
                    @test PBO.coercive_field(f_i8_rep, 1) == 32.0
                    @test PBO.coercive_fields(f_i8_rep)[1] == 32.0
                    g_i8 = PBO.gauge_invariant_qubo(f_i8_rep)
                    @test g_i8[1] == Int8(-64)
                    @test g_i8[2] == Int8(-60)
                    @test g_i8[3] == Int8(-4)
                    @test PBO.is_gauge_invariant(g_i8)

                    # Int8 row sum whose projected linear term (-130) is outside typemin(Int8):typemax(Int8)
                    f_i8_unrep = F_i8(1 => Int8(7), (1, 2) => Int8(120), (1, 3) => Int8(120), (1, 4) => Int8(20))
                    @test_throws ArgumentError PBO.gauge_invariant_qubo!(f_i8_unrep)
                    @test f_i8_unrep[1] == Int8(7)

                    # Precision preservation for 64-bit integers beyond Float64 53-bit significand
                    A = Int64(2)^53
                    F_i64 = PBO.TermDictPBF{Int,Int64}
                    f_prec = F_i64(1 => A, 2 => A, (1, 2) => -2 * A + 1)
                    @test PBO.coercive_field(f_prec, 1) == 0.25
                    @test PBO.coercive_field(f_prec, 2) == 0.25
                    @test PBO.coercive_fields(f_prec) == Dict(1 => 0.25, 2 => 0.25)
                    @test !PBO.is_gauge_invariant(f_prec)
                    @test !PBO.is_gauge_invariant(f_prec; atol = 1e-12)
                    @test PBO.is_gauge_invariant(f_prec; atol = 0.25)

                    # Float64 large coefficients that would overflow 2*l_u or intermediate row sum in Float64
                    F_f64 = PBO.TermDictPBF{Int,Float64}
                    f_huge_lin = F_f64(1 => 1e308)
                    @test PBO.coercive_field(f_huge_lin, 1) == 5e307
                    @test PBO.coercive_fields(f_huge_lin) == Dict(1 => 5e307)
                    @test !PBO.is_gauge_invariant(f_huge_lin; atol = 1e307)
                    @test PBO.is_gauge_invariant(f_huge_lin; atol = 6e307)

                    f_huge_quad = F_f64((1, 2) => 1e308, (1, 3) => 1e308)
                    @test PBO.coercive_field(f_huge_quad, 1) == 5e307
                    @test PBO.coercive_fields(f_huge_quad)[1] == 5e307
                    g_huge_quad = PBO.gauge_invariant_qubo(f_huge_quad)
                    @test g_huge_quad[1] == -1e308
                    @test g_huge_quad[2] == -5e307
                    @test g_huge_quad[3] == -5e307
                    @test PBO.is_gauge_invariant(g_huge_quad)

                    # BigFloat wide exponent span cancellation (2^2200 and 2^100000 vs 1)
                    setprecision(BigFloat, 256) do
                        F_bf = PBO.TermDictPBF{Int,BigFloat}
                        for exp_hi in (2200, 100_000)
                            A_bf = BigFloat(2)^exp_hi
                            f_bf = F_bf(
                                1 => -A_bf / 2,
                                2 => -A_bf / 2,
                                3 => -BigFloat(1) / 2,
                                (1, 2) => A_bf,
                                (1, 3) => BigFloat(1),
                            )
                            @test PBO.coercive_field(f_bf, 1) == BigFloat(0.25)
                            @test precision(PBO.coercive_field(f_bf, 1)) == 256
                            @test PBO.coercive_fields(f_bf) == Dict(
                                1 => BigFloat(0.25),
                                2 => BigFloat(0.0),
                                3 => BigFloat(0.0),
                            )
                            @test !PBO.is_gauge_invariant(f_bf)
                            @test !PBO.is_gauge_invariant(f_bf; atol = 1e-12)
                            @test PBO.is_gauge_invariant(f_bf; atol = 0.25)
                        end
                    end

                    # Exact comparison against high-precision Rational atol without premature rounding
                    f_unit = F_f64(1 => 2.0) # h_1 = 1.0
                    b_2200 = big(2)^2200
                    @test !PBO.is_gauge_invariant(f_unit; atol = (b_2200 - 1) // b_2200)
                    @test PBO.is_gauge_invariant(f_unit; atol = b_2200 // b_2200)
                    @test PBO.is_gauge_invariant(f_unit; atol = (b_2200 + 1) // b_2200)
                end
            end
        end
    end

    return nothing
end
