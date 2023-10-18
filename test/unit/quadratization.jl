function test_NTR_KZFD()
    @testset "→ NTR-KZFD" begin
        @testset "∴ SetDict/Symbol" begin
            let V = Symbol, T = Float64, F = PBO.SetDictPBF{V,T}

                let f = F([:x, :y, :z] => -1.0)
                    q = PBO.quadratize(f, PBO.Quadratization(PBO.NTR_KZFD(); stable = true))
                    
                    @test q == F([
                        :aux_1       =>  2.0,
                        (:x, :aux_1) => -1.0,
                        (:y, :aux_1) => -1.0,
                        (:z, :aux_1) => -1.0,
                    ])
                end

                let g = F([:x, :y, :z, :w] => -2.0)
                    q = PBO.quadratize(g, PBO.Quadratization(PBO.NTR_KZFD(); stable = true))

                    @test q == F([
                        :aux_1       =>  6.0,
                        (:x, :aux_1) => -2.0,
                        (:y, :aux_1) => -2.0,
                        (:z, :aux_1) => -2.0,
                        (:w, :aux_1) => -2.0,
                    ])
                end
            end
        end
    end

    return nothing
end

function test_PTR_BG()
    @testset "→ PTR-BG" begin
        @testset "∴ SetDict/Symbol" begin
            let V = Symbol, T = Float64, F = PBO.SetDictPBF{V,T}

                f = F([[:x, :y, :z] => 1.0])
                q = PBO.quadratize(f, PBO.Quadratization(PBO.PTR_BG(); stable = true))
                
                @test q == F([
                    :aux_1       =>  1.0,
                    (:x, :aux_1) =>  1.0,
                    (:y, :aux_1) => -1.0,
                    (:z, :aux_1) => -1.0,
                    (:y, :z)     =>  1.0,
                ])

                let g = F([:x, :y, :z, :w] => 2.0)
                    q = PBO.quadratize(g, PBO.Quadratization(PBO.PTR_BG(); stable = true))

                    @test q == F([
                        :aux_1       =>  4.0,
                        :aux_2       =>  2.0,

                        (:w, :aux_1) =>  2.0,
                        (:x, :aux_1) => -2.0,
                        (:y, :aux_1) => -2.0,
                        (:z, :aux_1) => -2.0,

                        (:x, :aux_2) =>  2.0,
                        (:y, :aux_2) => -2.0,
                        (:z, :aux_2) => -2.0,

                        (:y, :z)     =>  2.0,
                    ])
                end
            end
        end
    end

    return nothing
end

function test_quadratization()
    @testset "⊛ Quadratization" begin
        test_NTR_KZFD()
        test_PTR_BG()
    end

    return nothing
end