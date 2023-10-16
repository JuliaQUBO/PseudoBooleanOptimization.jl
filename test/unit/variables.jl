function test_variable_system()
    @testset "⊛ Variable System" verbose = true begin
        @testset "→ Ordering" begin
            @testset "∴ Symbol" begin
                @test PBO.varlt(:x, :x) === false
                @test PBO.varlt(:x, :y) === true
                @test PBO.varlt(:y, :x) === false

                @test PBO.varlt(:xx, :y) === false
                @test PBO.varlt(:y, :xx) === true
            end

            @testset "∴ Integer" begin
                @test PBO.varlt(1, 1) === false
                @test PBO.varlt(1, 2) === true
                @test PBO.varlt(2, 1) === false

                @test PBO.varlt(1, -1) === true
                @test PBO.varlt(-1, 1) === false

                @test PBO.varlt(-1, -1) === false
                @test PBO.varlt(-1, -2) === true
                @test PBO.varlt(-2, -1) === false
            end
        end
    end

    return nothing
end