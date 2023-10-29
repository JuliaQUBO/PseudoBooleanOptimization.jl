function test_operators()
    @testset "Operators" verbose = true begin
        test_TermDict_operators()
    end

    return nothing
end

function test_TermDict_operators()
    @testset "∴ TermDict" begin
        let S = Symbol
            T = Float64
            F = PBO.TermDictPBF{S,T}

            @testset "+" begin
                let a = -1.0
                    f = F(:x => 1.0, (:x, :y) => -2.0, 0.5)
                    g = F(:y => -1.0, (:x, :y) => 2.0, 1.0)

                    @test f + g == g + f == F(:x => 1.0, :y => -1.0, 1.5)
                    @test f + a == a + f == F(:x => 1.0, (:x, :y) => -2.0, -0.5)
                    @test g + a == a + g == F(:y => -1.0, (:x, :y) => 2.0)
                end
            end

            @testset "-" begin
                let a = 2.0
                    f = F(:x => 1.0, (:x, :y) => -2.0, 0.5)
                    g = F(:y => -1.0, (:x, :y) => 2.0, 1.0)

                    @test -f == F(:x => -1.0, (:x, :y) => 2.0, -0.5)
                    @test -g == F(:y => 1.0, (:x, :y) => -2.0, -1.0)

                    @test iszero(f - f)
                    @test iszero(g - g)

                    @test f - g == F(:x => 1.0, :y => 1.0, (:x, :y) => -4.0, -0.5)
                    @test g - f == F(:x => -1.0, :y => -1.0, (:x, :y) => 4.0, 0.5)

                    @test f - a == F(:x => 1.0, (:x, :y) => -2.0, -1.5)
                    @test a - f == F(:x => -1.0, (:x, :y) => 2.0, 1.5)
                    @test g - a == F(:y => -1.0, (:x, :y) => 2.0, -1.0)
                    @test a - g == F(:y => 1.0, (:x, :y) => -2.0, 1.0)
                end
            end

            @testset "*" begin
                let a = 0.25
                    f = F(:x => 1.0, (:x, :y) => -2.0, 0.5)
                    g = F(:z => -1.0, (:y, :z) => 2.0, 1.0)

                    @test f * g == g * f == F(
                        0.5,
                        :x => 1.0,
                        :z => -0.5,
                        (:x, :z) => -1.0,
                        (:x, :y) => -2.0,
                        (:y, :z) => 1.0,
                    )

                    @test f * a == a * f == F(0.125, :x => 0.25, (:x, :y) => -0.5)
                    @test g * a == a * g == F(0.25, :z => -0.25, (:y, :z) => 0.5)
                end
            end

            @testset "/" begin
                let a = 2.0
                    f = F(:x => 1.0, (:x, :y) => -2.0, 0.5)

                    @test f / a == F(:x => 0.5, (:x, :y) => -1.0, 0.25)
                end
            end

            @testset "^" begin
                let f = F(:x => 1.0, (:x, :y) => -2.0, 0.5)
                    @test f^0 == one(f)
                    @test f^1 == f
                    @test f^2 == f * f == F(
                        :x => 2.0,
                        (:x, :y) => -2.0,
                        0.25,
                    )
                    @test f^3 == f * f * f == F(
                        :x => 3.25,
                        (:x, :y) => -3.5,
                        0.125,
                    )
                end
            end
        end
    end

    return nothing
end