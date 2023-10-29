function test_print()
    @testset "⊛ Print" verbose = true begin
        @testset "∴ TermDict/Integer" begin
            let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
                @test repr(MIME"text/plain"(), F(0)) == "x₀"
                @test repr(MIME"text/plain"(), F(0.0)) == "0.0"
                @test repr(MIME"text/plain"(), F(1.0)) == "1.0"
                @test repr(MIME"text/plain"(), F(1.0, 2 => -3.0)) == "1.0 - 3.0 x₂"
                @test repr(MIME"text/plain"(), F(-1.0, 2 => -3.0, 3 => 4.0)) == "-1.0 - 3.0 x₂ + 4.0 x₃"
                @test repr(MIME"text/plain"(), F([2, 3] => -4.0, [2, 4] => 1.5)) == "-4.0 x₂ x₃ + 1.5 x₂ x₄"
            end
        end

        @testset "∴ TermDict/Symbol" begin
            let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}
                @test repr(MIME"text/plain"(), F(:x)) == "x"
                @test repr(MIME"text/plain"(), F(0.0)) == "0.0"
                @test repr(MIME"text/plain"(), F(1.0)) == "1.0"
                @test repr(MIME"text/plain"(), F(1.0, :x => -3.0)) == "1.0 - 3.0 x"
                @test repr(MIME"text/plain"(), F(-1.0, :x => -3.0, :y => 4.0)) == "-1.0 - 3.0 x + 4.0 y"
                @test repr(MIME"text/plain"(), F([:x, :y] => -4.0, [:x, :z] => 1.5)) == "-4.0 x y + 1.5 x z"
            end
        end
    end

    return nothing
end