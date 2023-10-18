function test_calculus()
    @testset "⊛ Calculus" verbose = true begin
        @testset "∴ SetDict" begin
            @testset "→ Derivatives" begin
                let V = Symbol, T = Float64, F = PBO.SetDictPBF{V,T}
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
                end
            end
        end
    end

    return nothing
end
