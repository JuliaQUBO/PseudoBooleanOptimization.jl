include("interface.jl")

function integration_tests(; _run_foreign_tests::Bool = false)
    @testset "□ Integration Tests" verbose = false begin
        test_interface()
        test_foreign(; _run_foreign_tests)
    end

    return nothing
end

function test_foreign(; _run_foreign_tests::Bool = false)
    @testset "☉ Foreign packages" verbose = false begin
        _run_foreign_tests || return nothing

        run_foreign_pkg_tests("QUBOTools")
    end

    return nothing
end
