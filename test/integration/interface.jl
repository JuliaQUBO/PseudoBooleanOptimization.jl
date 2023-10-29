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

            @test PBO.Term([VI(4), VI(2), VI(1), VI(2), VI(4)]) == PBO.Term{VI}([VI(1), VI(2), VI(4)])
        end

        @testset "varshow" begin
            @test PBO.varshow(VI(101)) == "x₁₀₁"
            @test PBO.varshow(VI(-12)) == "x₋₁₂"

            @test PBO.varshow(PBO.Term([VI(1), VI(2), VI(4)])) == "x₁ x₂ x₄"
        end

        @testset "varmul" begin
            let x = VI(1)
                y = VI(2)
                z = VI(3)

                let xy = PBO.Term([x, y])
                    xz = PBO.Term([x, z])
                    yz = PBO.Term([y, z])

                    @test PBO.varmul(x, y) == xy
                    @test PBO.varmul(y, x) == xy

                    @test PBO.varmul(x, z) == xz
                    @test PBO.varmul(z, x) == xz

                    @test PBO.varmul(y, z) == yz
                    @test PBO.varmul(z, y) == yz

                    @test PBO.varmul(xy, z) == PBO.Term([x, y, z])
                    @test PBO.varmul(xz, y) == PBO.Term([x, y, z])
                    @test PBO.varmul(x, yz) == PBO.Term([x, y, z])
                end
            end
        end
    end

    return nothing
end
