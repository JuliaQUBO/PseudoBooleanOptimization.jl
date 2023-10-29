function test_NTR_KZFD()
    @testset "→ NTR-KZFD" begin
        @testset "∴ TermDict/Symbol" begin
            let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}

                let f = F([:x, :y, :z] => -1.0)
                    q = PBO.quadratize(f, PBO.Quadratization(PBO.NTR_KZFD(); stable = true))

                    @test q == F([
                        :aux_1       => 2.0,
                        (:x, :aux_1) => -1.0,
                        (:y, :aux_1) => -1.0,
                        (:z, :aux_1) => -1.0,
                    ])
                end

                let g = F([:x, :y, :z, :w] => -2.0)
                    q = PBO.quadratize(g, PBO.Quadratization(PBO.NTR_KZFD(); stable = true))

                    @test q == F([
                        :aux_1       => 6.0,
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
        @testset "∴ TermDict/Symbol" begin
            let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}

                f = F([[:x, :y, :z] => 1.0])
                q = PBO.quadratize(f, PBO.Quadratization(PBO.PTR_BG(); stable = true))

                @test q == F([
                    :aux_1       => 1.0,
                    (:x, :aux_1) => 1.0,
                    (:y, :aux_1) => -1.0,
                    (:z, :aux_1) => -1.0,
                    (:y, :z)     => 1.0,
                ])

                let g = F([:x, :y, :z, :w] => 2.0)
                    q = PBO.quadratize(g, PBO.Quadratization(PBO.PTR_BG(); stable = true))

                    @test q == F([
                        :aux_1 => 4.0,
                        :aux_2 => 2.0,
                        (:w, :aux_1) => 2.0,
                        (:x, :aux_1) => -2.0,
                        (:y, :aux_1) => -2.0,
                        (:z, :aux_1) => -2.0,
                        (:x, :aux_2) => 2.0,
                        (:y, :aux_2) => -2.0,
                        (:z, :aux_2) => -2.0,
                        (:y, :z) => 2.0,
                    ])
                end
            end

            @testset "∴ TermDict/Integer" begin
                let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
                    f = F(
                        (1, 2, 3)    => 18,
                        (1, 2, 4)    => 40,
                        (1, 3, 4)    => 20,
                        (2, 3, 4)    => 20,
                        (1, 2, 3, 4) => 8,
                    )

                    g = F(
                        -1      => 18,
                        -2      => 40,
                        -3      => 20,
                        -4      => 20,
                        -5      => 16,
                        -6      => 8,
                        (2, 3)  => 18,
                        (2, 4)  => 40,
                        (3, 4)  => 48,
                        (1, -1) => 18,
                        (2, -1) => -18,
                        (3, -1) => -18,
                        (1, -2) => 40,
                        (2, -2) => -40,
                        (4, -2) => -40,
                        (1, -3) => 20,
                        (3, -3) => -20,
                        (4, -3) => -20,
                        (2, -4) => 20,
                        (3, -4) => -20,
                        (4, -4) => -20,
                        (1, -5) => 8,
                        (2, -5) => -8,
                        (3, -5) => -8,
                        (4, -5) => -8,
                        (2, -6) => 8,
                        (3, -6) => -8,
                        (4, -6) => -8,
                    )

                    q = PBO.quadratize(f, PBO.Quadratization(PBO.PTR_BG(); stable = true))

                    @test g == q
                end
            end
        end
    end

    return nothing
end

function test_DEFAULT()
    @testset "→ DEFAULT" begin
        @testset "∴ TermDict/Integer" begin
            let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
                let f = F(
                        () => 49,
                        1  => -40,
                        2  => -40,
                        3  => -24,
                        4  => -40,
                        (1, 2) => 32,
                        (1, 3) => 15,
                        (1, 4) => 40,
                        (2, 3) => 15,
                        (2, 4) => 40,
                        (3, 4) => 16,
                        (1, 2, 3) => 18,
                        (1, 2, 4) => 40,
                        (1, 3, 4) => 20,
                        (2, 3, 4) => 20,
                        (1, 2, 3, 4) => 8,
                    )

                    g = F(
                        ()      => 49,
                        1       => -40,
                        2       => -40,
                        3       => -24,
                        4       => -40,
                        -1      => 18,
                        -2      => 40,
                        -3      => 20,
                        -4      => 20,
                        -5      => 16,
                        -6      => 8,
                        (1, 2)  => 32,
                        (1, 3)  => 15,
                        (1, 4)  => 40,
                        (2, 3)  => 33,
                        (2, 4)  => 80,
                        (3, 4)  => 64,
                        (1, -1) => 18,
                        (2, -1) => -18,
                        (3, -1) => -18,
                        (1, -2) => 40,
                        (2, -2) => -40,
                        (4, -2) => -40,
                        (1, -3) => 20,
                        (3, -3) => -20,
                        (4, -3) => -20,
                        (2, -4) => 20,
                        (3, -4) => -20,
                        (4, -4) => -20,
                        (1, -5) => 8,
                        (2, -5) => -8,
                        (3, -5) => -8,
                        (4, -5) => -8,
                        (2, -6) => 8,
                        (3, -6) => -8,
                        (4, -6) => -8,
                    )

                    q = PBO.quadratize(f, PBO.Quadratization(PBO.DEFAULT(); stable = true))

                    @test q == g
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
        test_DEFAULT()
    end

    return nothing
end