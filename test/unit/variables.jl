function test_variable_system()
    @testset "⊛ Variable System" verbose = true begin
        @testset "→ Ordering (varlt)" begin
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

        @testset "→ Display (varshow)" begin
            @testset "∴ Symbol" begin
                @test PBO.varshow(:x) == "x"
                @test PBO.varshow(:y) == "y"

                @test PBO.varshow(PBO.Term([:x, :y])) == "x y"
                @test PBO.varshow(PBO.Term([:z, :x])) == "x z"
            end
        end

        @testset "→ Product (varmul)" begin
            @testset "∴ Symbol" begin
                let x = PBO.Term([:x])
                    y = PBO.Term([:y])

                    @test PBO.varmul(x, x) == PBO.Term([:x])
                    @test PBO.varmul(x, y) == PBO.Term([:x, :y])
                    @test PBO.varmul(y, x) == PBO.Term([:x, :y])

                    let xy = PBO.Term([:x, :y])
                        zw = PBO.Term([:z, :w])
                        @test PBO.varmul(x, xy) == PBO.Term([:x, :y])
                        @test PBO.varmul(xy, y) == PBO.Term([:x, :y])

                        @test PBO.varmul(xy, zw) == PBO.Term([:x, :y, :z, :w])
                    end
                end
            end
        end
    end

    return nothing
end