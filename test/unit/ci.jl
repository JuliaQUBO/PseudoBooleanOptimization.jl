using TOML

function test_ci_configuration()
    @testset "CI configuration" begin
        repo_root = normpath(joinpath(@__DIR__, "..", ".."))
        workflows = joinpath(repo_root, ".github", "workflows")
        project     = TOML.parsefile(joinpath(repo_root, "Project.toml"))
        ci_config   = read(joinpath(workflows, "ci.yml"), String)
        docs_config = read(joinpath(workflows, "docs.yml"), String)

        julia_compat = project["compat"]["julia"]
        compat_floor = match(r"\d+(?:\.\d+){0,2}", julia_compat)

        @test compat_floor !== nothing
        @test occursin("version: '$(compat_floor.match)'", ci_config)
        @test occursin("version: '1'", ci_config)
        @test occursin("version: '$(compat_floor.match)'", docs_config)
    end

    return nothing
end
