function test_constructors()
    @testset "⊛ Constructors" verbose = true begin
        test_setdict_constructors()
    end

    return nothing
end

function test_setdict_constructors()
    @testset "∴ SetDict" begin
        let S = Symbol
            T = Float64
            F = PBO.SetDictPBF{S,T}

            @test PBO.data(F()) == Dict{Set{S},T}()
            @test PBO.data(F(0)) == Dict{Set{S},T}()
            @test PBO.data(F(0.0)) == Dict{Set{S},T}()
            @test PBO.data(zero(F)) == Dict{Set{S},T}()

            let f = F(
                    nothing => 0.5,
                    :x => 1.0,
                    :y => 1.0,
                    :z => 1.0,
                    [:x, :y] => -2.0,
                    [:x, :z] => -2.0,
                    [:y, :z] => -2.0,
                    [:x, :y, :z] => 3.0,
                )
                Φ = Dict{Set{S},T}(
                    Set{S}() => 0.5,
                    Set{S}([:x]) => 1.0,
                    Set{S}([:y]) => 1.0,
                    Set{S}([:z]) => 1.0,
                    Set{S}([:x, :y]) => -2.0,
                    Set{S}([:x, :z]) => -2.0,
                    Set{S}([:y, :z]) => -2.0,
                    Set{S}([:x, :y, :z]) => 3.0,
                )
                @test PBO.data(f) == Φ
            end

            @test PBO.data(F(1.0)) == Dict{Set{S},T}(Set{S}() => 1.0)
            @test PBO.data(one(F)) == Dict{Set{S},T}(Set{S}() => 1.0)
            @test PBO.data(F(2.0)) == Dict{Set{S},T}(Set{S}() => 2.0)

            let f = F([:x, :y, :z, :w, nothing])
                Φ = Dict{Set{S},T}(
                    Set{S}([:x]) => 1.0,
                    Set{S}([:y]) => 1.0,
                    Set{S}([:z]) => 1.0,
                    Set{S}([:w]) => 1.0,
                    Set{S}() => 1.0,
                )
                @test PBO.data(f) == Φ
            end

            let f = F((nothing => 0.5), :x, [:x, :y] => -2.0)
                Φ = Dict{Set{S},T}(
                    Set{S}() => 0.5,
                    Set{S}([:x]) => 1.0,
                    Set{S}([:x, :y]) => -2.0,
                )
                @test PBO.data(f) == Φ
            end

            let f = F(nothing => 0.5, :y, [:x, :y] => 2.0)
                Φ = Dict{Set{S},T}(
                    Set{S}() => 0.5,
                    Set{S}([:y]) => 1.0,
                    Set{S}([:x, :y]) => 2.0,
                )
                @test PBO.data(f) == Φ
            end

            let f = F(nothing, :z => -1.0)
                Φ = Dict{Set{S},T}(Set{S}() => 1.0, Set{S}([:z]) => -1.0)
                @test PBO.data(f) == Φ
            end

            let f = F(S[] => 0.0, Set{S}([:x, :y, :z]) => 3.0)
                Φ = Dict{Set{S},T}(Set{S}([:x, :y, :z]) => 3.0)
                @test PBO.data(f) == Φ
            end
        end
    end

    return nothing
end
