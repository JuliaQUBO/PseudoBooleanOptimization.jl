function test_print()
    @testset "Print" begin
        @test "$(Assets.r)" == "1.0 + -1.0*z"
        @test "$(Assets.s)" == "3.0*x*y*z"
    end

    return nothing
end