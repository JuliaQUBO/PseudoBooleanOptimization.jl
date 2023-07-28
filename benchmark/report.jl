using BenchmarkTools

function get_results(data_path)
    main_results_path = joinpath(data_path, "results-main.json")
    dev_results_path  = joinpath(data_path, "results-dev.json")

    main_results = first(BenchmarkTools.load(main_results_path))
    dev_results  = first(BenchmarkTools.load(dev_results_path))

    return get_results(main_results, dev_results)
end

function get_results(main_results, dev_results)
    results = Dict{String,Any}()

    for (key, val) in dev_results
        if val isa BenchmarkTools.BenchmarkGroup
            results[key] = get_results(main_results[key], val)
        elseif val isa BenchmarkTools.Trial
            results[key] = (main_results[key], val)
        end
    end

    return results
end

function status_emoji(status::Symbol)
    if status == :regression
        return "❌"
    elseif status == :improvement
        return "🎉"
    elseif status == :invariant
        return "🟰"
    else
        return "❔"
    end
end

function compare_results(results; keypath = "")
    report = []

    for (key, val) in results
        if val isa Dict
            append!(report, compare_results(val; keypath = "$keypath/$key"))
        elseif val isa Tuple
            main_trial, dev_trial = val

            case_id = "$keypath/$key"

            main_μ = BenchmarkTools.mean(main_trial)
            main_m = BenchmarkTools.median(main_trial)
            main_σ = BenchmarkTools.std(main_trial)

            dev_μ = BenchmarkTools.mean(dev_trial)
            dev_m = BenchmarkTools.median(dev_trial)
            dev_σ = BenchmarkTools.std(dev_trial)

            cmp_m = BenchmarkTools.judge(dev_m, main_m)

            status = status_emoji(BenchmarkTools.time(cmp_m))


            push!(
                report,
                "| `$case_id` | $(BenchmarkTools.prettytime(BenchmarkTools.time(main_μ))) ($(BenchmarkTools.prettytime(BenchmarkTools.time(main_m)))) ± $(BenchmarkTools.prettytime(BenchmarkTools.time(main_σ))) | $(BenchmarkTools.prettytime(BenchmarkTools.time(dev_μ))) ($(BenchmarkTools.prettytime(BenchmarkTools.time(dev_m)))) ± $(BenchmarkTools.prettytime(BenchmarkTools.time(dev_σ))) | $(status) |"
            )
        end
    end

    return report
end

function write_report(report, data_path)
    report_path = joinpath(data_path, "REPORT.md")

    open(report_path, "w") do io
        println(io, "# Performance Report - `main` vs. `dev`")
        println(io)
        println(io, "| case | `main` | `dev` | status |")
        println(io, "| :--- | :----: | :---: | :----: |")

        for entry in report
            println(io, entry)
        end
    end

    return nothing
end

function main()
    data_path = joinpath(@__DIR__, "data")

    results = get_results(data_path)

    report = compare_results(results)

    write_report(report, data_path)

    return nothing
end

if "--run" ∈ ARGS
    main()
end
