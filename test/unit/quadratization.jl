struct UnsupportedQuadratizationAuxiliaries <: PBO.QuadratizationMethod end

function test_quadratization_auxiliary_completion()
    @testset "Auxiliary assignments" begin
        let V = Int, T = Float64, F = PBO.TermDictPBF{V,T}
            for (f, x, quad) in (
                (
                    F((1, 2, 3) => -2.0),
                    Dict{V,Int}(1 => 1, 2 => 1, 3 => 1),
                    PBO.Quadratization(PBO.NTR_KZFD()),
                ),
                (
                    F((1, 2, 3, 4) => 2.0),
                    Dict{V,Int}(1 => 1, 2 => 0, 3 => 1, 4 => 1),
                    PBO.Quadratization(PBO.PTR_BG()),
                ),
                (
                    F((1, 2, 3) => 2.0),
                    Dict{V,Int}(1 => 1, 2 => 1, 3 => 1),
                    PBO.Quadratization(PBO.NTR_KZFD(); sign = -1),
                ),
                (
                    F((1, 2, 3, 4) => -2.0),
                    Dict{V,Int}(1 => 1, 2 => 0, 3 => 1, 4 => 1),
                    PBO.Quadratization(PBO.PTR_BG(); sign = -1),
                ),
                (
                    F((3, 1, 2, 4) => 2.0),
                    Dict{V,Int}(1 => 0, 2 => 1, 3 => 1, 4 => 0),
                    PBO.Quadratization(PBO.DEFAULT(); stable = true),
                ),
                (
                    F((1, 2, 3, 4, 5) => -2.0),
                    Dict{V,Int}(1 => 1, 2 => 0, 3 => 1, 4 => 1, 5 => 0),
                    PBO.Quadratization(PBO.DEFAULT(); sign = -1),
                ),
            )
                original_f = copy(f)
                original_x = copy(x)

                PBO._quadratize_with_solution!(f, x, quad)

                @test f == PBO.quadratize(original_f, quad)
                @test Set(keys(x)) == Set(PBO.variables(f))
                @test all(v -> v in (0, 1), values(x))

                y = f(x)
                original_y = original_f(original_x)

                @test PBO.isconstant(y)
                @test PBO.isconstant(original_y)
                @test y[nothing] ≈ original_y[nothing]
            end

            err = try
                PBO._quadratize_with_solution!(
                    F((1, 2, 3) => 2.0),
                    Dict{V,Int}(1 => 1, 2 => 0, 3 => 1),
                    PBO.Quadratization(UnsupportedQuadratizationAuxiliaries()),
                )

                nothing
            catch err
                err
            end

            @test err isa ArgumentError
            @test occursin("Unsupported quadratization method", sprint(showerror, err))
        end
    end

    return nothing
end

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

                let f = F([:x, :y, :z] => 1.0)
                    q = PBO.quadratize(
                        f,
                        PBO.Quadratization(PBO.NTR_KZFD(); stable = true, sign = -1),
                    )

                    @test q == F([
                        :aux_1       => -2.0,
                        (:x, :aux_1) => 1.0,
                        (:y, :aux_1) => 1.0,
                        (:z, :aux_1) => 1.0,
                    ])
                end

                @test_throws AssertionError PBO.quadratize(
                    F([:x, :y, :z] => -1.0),
                    PBO.Quadratization(PBO.NTR_KZFD(); stable = true, sign = -1),
                )
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

                let f = F([:x, :y, :z] => -1.0)
                    q = PBO.quadratize(
                        f,
                        PBO.Quadratization(PBO.PTR_BG(); stable = true, sign = -1),
                    )

                    @test q == F([
                        :aux_1       => -1.0,
                        (:x, :aux_1) => -1.0,
                        (:y, :aux_1) => 1.0,
                        (:z, :aux_1) => 1.0,
                        (:y, :z)     => -1.0,
                    ])
                end

                @test_throws AssertionError PBO.quadratize(
                    F([:x, :y, :z] => 1.0),
                    PBO.Quadratization(PBO.PTR_BG(); stable = true, sign = -1),
                )
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
        @test_throws ArgumentError PBO.Quadratization(PBO.DEFAULT(); sign = 0)

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

        @testset "∴ TermDict/Symbol/Maximization" begin
            let V = Symbol, T = Float64, F = PBO.TermDictPBF{V,T}
                let f = F([:x, :y, :z] => 1.0)
                    q = PBO.quadratize(
                        f,
                        PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = -1),
                    )

                    @test q == F([
                        :aux_1       => -2.0,
                        (:x, :aux_1) => 1.0,
                        (:y, :aux_1) => 1.0,
                        (:z, :aux_1) => 1.0,
                    ])

                    for x in 0:1, y in 0:1, z in 0:1
                        ξ = Dict(:x => x, :y => y, :z => z)
                        @test maximum(
                            convert(T, q(merge(ξ, Dict(:aux_1 => s)))) for s in 0:1
                        ) == convert(T, f(ξ))
                    end
                end

                let f = F([:x, :y, :z] => -1.0)
                    q = PBO.quadratize(
                        f,
                        PBO.Quadratization(PBO.DEFAULT(); stable = true, sign = -1),
                    )

                    @test q == F([
                        :aux_1       => -1.0,
                        (:x, :aux_1) => -1.0,
                        (:y, :aux_1) => 1.0,
                        (:z, :aux_1) => 1.0,
                        (:y, :z)     => -1.0,
                    ])

                    for x in 0:1, y in 0:1, z in 0:1
                        ξ = Dict(:x => x, :y => y, :z => z)
                        @test maximum(
                            convert(T, q(merge(ξ, Dict(:aux_1 => s)))) for s in 0:1
                        ) == convert(T, f(ξ))
                    end
                end
            end
        end
    end

    return nothing
end

function test_quadratization()
    @testset "⊛ Quadratization" begin
        test_quadratization_auxiliary_completion()
        test_NTR_KZFD()
        test_PTR_BG()
        test_DEFAULT()
    end

    return nothing
end
