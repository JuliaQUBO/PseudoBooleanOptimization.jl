function test_operators()
    @testset "Operators" verbose = true begin
        @testset "$op" for (op::Function, data) in Assets.PBF_OPERATOR_LIST
            for (x, y) in data
                if y isa Type{<:Exception}
                    @test_throws y op(x...)
                else
                    @test op(x...) == y
                end
            end
        end
    end

    return nothing
end

function test_evaluation()
    @testset "Evaluation" verbose = true begin
        @testset "$tag" for (tag::String, data) in Assets.PBF_EVALUATION_LIST
            for ((f, x), y) in data
                @test f(x) == y
            end
        end
    end
end
