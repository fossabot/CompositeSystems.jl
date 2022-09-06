include("SystemState.jl")
include("utils.jl")

struct SequentialMonteCarlo <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool

    function SequentialMonteCarlo(;
        samples::Int=1_000, seed::Int=rand(UInt64),
        verbose::Bool=false, threaded::Bool=false
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))
        new(samples, UInt64(seed), verbose, threaded)
    end

end

function assess(
    system::SystemModel,
    method::SequentialMonteCarlo,
    resultspecs::ResultSpec...
)
    add_load_curtailment_info!(system.network)

    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)

    optimizer = [JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0), 
            JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>
            JuMP.optimizer_with_attributes(Ipopt.Optimizer, "print_level"=>0, "tol"=>1e-4, "print_level"=>0), 
            "log_levels"=>[], "allow_almost_solved_integral"=>true, "time_limit"=>3)
    ]

    @spawn makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    if method.threaded
        for _ in 1:threads
            @spawn assess(system, optimizer, method, sampleseeds, results, resultspecs...)
        end
    else
        assess(system, optimizer, method, sampleseeds, results, resultspecs...)
    end

    return finalize(results, system, method.threaded ? threads : 1)
    
end

"It generates a sequence of seeds from a given number of samples"
function makeseeds(sampleseeds::Channel{Int}, nsamples::Int)

    for s in 1:nsamples
        put!(sampleseeds, s)
    end

    close(sampleseeds)

end

function assess(
    system::SystemModel{N}, optimizer, method::SequentialMonteCarlo,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMonteCarlo}}}},
    resultspecs::ResultSpec...
) where {R<:ResultSpec, N}

    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)

    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system) #creates the up/down sequence for each device.
        JuMP.Model(optimizer[1])
        #println("s=$(s)")

        for t in 1:N
            pm = solve!(systemstate, system, create_dict_from_system(system, t), optimizer, t)
            foreach(recorder -> record!(recorder, pm, system, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)

    end

    put!(results, recorders)

end

function initialize!(rng::AbstractRNG, state::SystemState, system::SystemModel{N}) where N

    initialize_availability!(rng, state.gens_available, system.generators, N)
    initialize_availability!(rng, state.stors_available, system.storages, N)
    initialize_availability!(rng, state.genstors_available, system.generatorstorages, N)
    initialize_availability!(rng, state.branches_available, system.branches, N)
    update_condition!(state, N)

    return

end

function solve!(state::SystemState, system::SystemModel, data::Dict{String,Any}, optimizer, t::Int)

    model_type = apply_contingencies!(data, state, system, t)
    pm = SolveModel(data, model_type, optimizer)
    println("t=$(t), success_state?=$(state.condition[t]), model_type=$(model_type), load_curt=$(sum([pm.solution["solution"]["load_curtailment"][i]["pl"] for i in keys(pm.solution["solution"]["load_curtailment"])]))")
    pm.model = nothing
    return pm
    
end

#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)
include("result_shortfall.jl")
include("result_flow.jl")
