function test_discretization()
    @testset "Discretization" begin
        @test PBO.discretize(Assets.p; tol = 0.1) == PBO.PBF{Symbol,Float64}(nothing => 1.0, :x => 2.0, [:x, :y] => -4.0)
        @test PBO.discretize(Assets.q; tol = 0.1) == PBO.PBF{Symbol,Float64}(nothing => 1.0, :y => 2.0, [:x, :y] => 4.0)
        @test PBO.discretize(Assets.r; tol = 0.1) == PBO.PBF{Symbol,Float64}(nothing => 1.0, :z => -1.0)
    end

    return nothing
end