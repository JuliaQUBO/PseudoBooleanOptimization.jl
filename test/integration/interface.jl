function test_interface()
    @testset "☉ Interface" verbose = true begin
        test_variable_interface()
    end

    return nothing
end

function test_variable_interface()
    @testset "→ Variables" begin
        @testset "varlt" begin
            @test PBO.varlt(VI(1), VI(2)) === true
            @test PBO.varlt(VI(2), VI(1)) === false
            @test PBO.varlt(VI(1), VI(1)) === false
            @test PBO.varlt(VI(1), VI(-1)) === true
            @test PBO.varlt(VI(-1), VI(1)) === false
            @test PBO.varlt(VI(-1), VI(-1)) === false
        end
    end

    return nothing
end
