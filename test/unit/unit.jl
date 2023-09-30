include("function.jl")
include("operators.jl")
include("calculus.jl")
include("discretization.jl")
include("quadratization.jl")
include("print.jl")

function test_unit()
    @testset "Pseudo-Boolean Functions" verbose = true begin
        # test_constructors()
        # test_operators()
        # test_evaluation()
        # test_calculus()
        # test_discretization()
        # test_quadratization()
        # test_print()
    end

    return nothing
end
