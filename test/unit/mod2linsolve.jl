function test_mod2linsolve()
    @testset "Mod-2 linear solving" verbose = true begin
        test_mod2_elimination_regression()
        test_mod2_solution_counts()
    end

    return nothing
end

function test_mod2_elimination_regression()
    @testset "Elimination updates rows and right-hand side" begin
        A0 = [1 1; 1 0]
        b0 = [1, 0]

        A = copy(A0)
        b = copy(b0)

        PBO._mod2_elimination!(A, b)

        @test A == [1 1; 0 1]
        @test b == [1, 1]

        x = PBO._mod2_solution(A, b)

        @test PBO._mod2_numsolutions!(copy(A0), copy(b0)) == 1
        @test x == [0, 1]
        @test mod.(A0 * x, 2) == b0
    end

    return nothing
end

function test_mod2_solution_counts()
    @testset "Solutions and solution counts" begin
        let A = [1 1], b = [1]
            x = PBO._mod2_solution!(copy(A), copy(b))

            @test PBO._mod2_numsolutions!(copy(A), copy(b)) == 2
            @test mod.(A * x, 2) == b
        end

        let A = [1 0; 1 0], b = [0, 1]
            @test PBO._mod2_numsolutions!(copy(A), copy(b)) == 0
            @test isnothing(PBO._mod2_solution!(copy(A), copy(b)))
        end
    end

    return nothing
end
