function test_term_parser()
    @testset "⊛ PBO.Term Parser" verbose = true begin
        @testset "∴ TermDict" begin
            let F = PBO.PBF{Symbol,Float64,PBO.TermDict{Symbol,Float64}}
                @test PBO.term(F, 1) == (PBO.Term{Symbol}() => 1.0)
                @test PBO.term(F, 1.0) == (PBO.Term{Symbol}() => 1.0)
                @test PBO.term(F, nothing => 1.0) == (PBO.Term{Symbol}() => 1.0)
                @test PBO.term(F, 1 // 1) == (PBO.Term{Symbol}() => 1.0)
                @test PBO.term(F, :x) == (PBO.Term{Symbol}([:x]) => 1.0)
                @test PBO.term(F, (:x, :x)) == (PBO.Term{Symbol}([:x]) => 1.0)
                @test PBO.term(F, (:x, :y)) == (PBO.Term{Symbol}([:x, :y]) => 1.0)
                @test PBO.term(F, [:x, :y, :z]) == (PBO.Term{Symbol}([:x, :y, :z]) => 1.0)
                @test PBO.term(F, [:x, :y, :z]) == (PBO.Term{Symbol}([:x, :y, :z]) => 1.0)
                @test PBO.term(F, [:x, :z] => -3.0) == (PBO.Term{Symbol}([:x, :z]) => -3.0)
                @test PBO.term(F, [:x, :z] => 0.0) == (PBO.Term{Symbol}() => 0.0)
                @test_throws Exception PBO.term(F, 1.0 => 1.0)
            end

            let F = PBO.PBF{Int,Int,PBO.TermDict{Int,Int}}
                @test PBO.term(F, 1) == (PBO.Term{Int}([1]) => 1)
                @test PBO.term(F, 2) == (PBO.Term{Int}([2]) => 1)
                @test PBO.term(F, 1.0) == (PBO.Term{Int}() => 1)
                @test PBO.term(F, 2.0) == (PBO.Term{Int}() => 2)
                @test PBO.term(F, nothing => 1.0) == (PBO.Term{Int}() => 1)
                @test PBO.term(F, 1 // 1) == (PBO.Term{Int}() => 1)
                @test_throws Exception PBO.term(F, :x)
                @test_throws Exception PBO.term(F, 1.0 => 1)
            end
        end
    end

    return nothing
end
