function test_calculus()
    @testset "Calculus" begin
        for f in Assets.PBF_LIST
            @test PBO.maxgap(f) ≈ (PBO.upperbound(f) - PBO.lowerbound(f))
        end
    end

    return nothing
end
