function test_term_parser()
    @testset "⊛ Term Parser" verbose = true begin
        @testset "∴ SetDict" begin
            let F = PBO.PBF{Symbol,Float64,PBO.SetDict{Symbol,Float64}}
                @test PBO.term(F, 1) == (Set{Symbol}() => 1.0)
                @test PBO.term(F, 1.0) == (Set{Symbol}() => 1.0)
                @test PBO.term(F, nothing => 1.0) == (Set{Symbol}() => 1.0)
                @test PBO.term(F, 1 // 1) == (Set{Symbol}() => 1.0)
                @test PBO.term(F, :x) == (Set{Symbol}([:x]) => 1.0)
                @test PBO.term(F, (:x, :x)) == (Set{Symbol}([:x]) => 1.0)
                @test PBO.term(F, (:x, :y)) == (Set{Symbol}([:x, :y]) => 1.0)
                @test PBO.term(F, [:x, :y, :z]) == (Set{Symbol}([:x, :y, :z]) => 1.0)
                @test PBO.term(F, [:x, :y, :z]) == (Set{Symbol}([:x, :y, :z]) => 1.0)
                @test PBO.term(F, [:x, :z] => -3.0) == (Set{Symbol}([:x, :z]) => -3.0)
                @test PBO.term(F, [:x, :z] => 0.0) == (Set{Symbol}() => 0.0)
                @test_throws Exception PBO.term(F, 1.0 => 1.0)
            end

            let F = PBO.PBF{Int,Int,PBO.SetDict{Int,Int}}
                @test PBO.term(F, 1) == (Set{Int}([1]) => 1)
                @test PBO.term(F, 2) == (Set{Int}([2]) => 1)
                @test PBO.term(F, 1.0) == (Set{Int}() => 1)
                @test PBO.term(F, 2.0) == (Set{Int}() => 2)
                @test PBO.term(F, nothing => 1.0) == (Set{Int}() => 1)
                @test PBO.term(F, 1 // 1) == (Set{Int}() => 1)
                @test_throws Exception PBO.term(F, :x)
                @test_throws Exception PBO.term(F, 1.0 => 1)
            end
        end
    end

    return nothing
end
