function test_bounds()
    @testset "Bounds" begin
        let f = PBO.PBF{Symbol,Float64}(:x => 1.0, :y => -1.0)
            @test PBO.lowerbound(f) ≈ -1.0
            @test PBO.upperbound(f) ≈  1.0
            @test all(PBO.bounds(f) .≈ (-1.0, 1.0))
        end

        let f = zero(PBO.PBF{Symbol,Float64})
            @test PBO.lowerbound(f) ≈ 0.0
            @test PBO.upperbound(f) ≈ 0.0
            @test all(PBO.bounds(f) .≈ (0.0, 0.0))
        end
    end

    return nothing
end
