function test_constructors()
    @testset "⊛ Constructors" verbose = true begin
        test_termdict_constructors()
    end

    return nothing
end

function test_termdict_constructors()
    @testset "∴ TermDict" begin
        let V = Symbol
            T = Float64
            F = PBO.TermDictPBF{V,T}

            @test PBO.data(F()) == Dict{PBO.Term{V},T}()
            @test PBO.data(F(0)) == Dict{PBO.Term{V},T}()
            @test PBO.data(F(0.0)) == Dict{PBO.Term{V},T}()
            @test PBO.data(zero(F)) == Dict{PBO.Term{V},T}()

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
                Φ = Dict{PBO.Term{V},T}(
                    PBO.Term{V}() => 0.5,
                    PBO.Term{V}([:x]) => 1.0,
                    PBO.Term{V}([:y]) => 1.0,
                    PBO.Term{V}([:z]) => 1.0,
                    PBO.Term{V}([:x, :y]) => -2.0,
                    PBO.Term{V}([:x, :z]) => -2.0,
                    PBO.Term{V}([:y, :z]) => -2.0,
                    PBO.Term{V}([:x, :y, :z]) => 3.0,
                )
                @test PBO.data(f) == Φ
            end

            @test PBO.data(F(1.0)) == Dict{PBO.Term{V},T}(PBO.Term{V}() => 1.0)
            @test PBO.data(one(F)) == Dict{PBO.Term{V},T}(PBO.Term{V}() => 1.0)
            @test PBO.data(F(2.0)) == Dict{PBO.Term{V},T}(PBO.Term{V}() => 2.0)

            let f = F([:x, :y, :z, :w, nothing])
                Φ = Dict{PBO.Term{V},T}(
                    PBO.Term{V}([:x]) => 1.0,
                    PBO.Term{V}([:y]) => 1.0,
                    PBO.Term{V}([:z]) => 1.0,
                    PBO.Term{V}([:w]) => 1.0,
                    PBO.Term{V}() => 1.0,
                )
                @test PBO.data(f) == Φ
            end

            let f = F((nothing => 0.5), :x, [:x, :y] => -2.0)
                Φ = Dict{PBO.Term{V},T}(
                    PBO.Term{V}() => 0.5,
                    PBO.Term{V}([:x]) => 1.0,
                    PBO.Term{V}([:x, :y]) => -2.0,
                )
                @test PBO.data(f) == Φ
            end

            let f = F(nothing => 0.5, :y, [:x, :y] => 2.0)
                Φ = Dict{PBO.Term{V},T}(
                    PBO.Term{V}() => 0.5,
                    PBO.Term{V}([:y]) => 1.0,
                    PBO.Term{V}([:x, :y]) => 2.0,
                )
                @test PBO.data(f) == Φ
            end

            let f = F(nothing, :z => -1.0)
                Φ = Dict{PBO.Term{V},T}(PBO.Term{V}() => 1.0, PBO.Term{V}([:z]) => -1.0)
                @test PBO.data(f) == Φ
            end

            let f = F(V[] => 0.0, PBO.Term{V}([:x, :y, :z]) => 3.0)
                Φ = Dict{PBO.Term{V},T}(PBO.Term{V}([:x, :y, :z]) => 3.0)
                @test PBO.data(f) == Φ
            end
        end
    end

    return nothing
end
