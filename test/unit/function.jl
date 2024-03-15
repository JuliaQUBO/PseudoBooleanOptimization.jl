function test_constructors()
    @testset "Constructors" begin
        for (x, y) in Assets.PBF_CONSTRUCTOR_LIST
            @test x == y
        end
    end

    return nothing
end