function test_NTR_KZFD()
    @testset "NTR-KZFD" begin
        let
            ω = Set{Symbol}([:x, :y, :z])
            f = PBO.PBF{Symbol,Float64}([ω => -1.0])
            g = PBO.quadratize(f, PBO.Quadratization{PBO.NTR_KZFD}(true))
            
            @test g == PBO.PBF{Symbol,Float64}([
                (:aux_1,)    =>  2.0,
                (:x, :aux_1) => -1.0,
                (:y, :aux_1) => -1.0,
                (:z, :aux_1) => -1.0,
            ])
        end
    end

    return nothing
end

function test_PTR_BG()
    @testset "PTR-BG" begin
        let
            ω = Set{Symbol}([:x, :y, :z])
            f = PBO.PBF{Symbol,Float64}([ω => 1.0])
            g = PBO.quadratize(f, PBO.Quadratization{PBO.PTR_BG}(true))
            
            @test g == PBO.PBF{Symbol,Float64}([
                (:aux_1,)    =>  1.0,
                (:x, :aux_1) =>  1.0,
                (:y, :aux_1) => -1.0,
                (:z, :aux_1) => -1.0,
                (:y, :z)     =>  1.0,
            ])
        end
    end

    return nothing
end

function test_quadratization()
    @testset "Quadratization" begin
        test_NTR_KZFD()
        test_PTR_BG()
    end

    return nothing
end