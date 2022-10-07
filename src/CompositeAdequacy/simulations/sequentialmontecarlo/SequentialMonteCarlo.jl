include("SystemState.jl")
include("utils.jl")

struct SequentialMonteCarlo <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool
    threaded::Bool

    function SequentialMonteCarlo(;
        samples::Int=1_000, seed::Int=rand(UInt64),
        verbose::Bool=false, threaded::Bool=true
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))
        new(samples, UInt64(seed), verbose, threaded)
    end

end

function assess(
    system::SystemModel{N},
    method::SequentialMonteCarlo,
    resultspecs::ResultSpec...
) where {N}

    nl_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-3, "acceptable_tol"=>1e-2, "constr_viol_tol"=>0.01, "acceptable_tol"=>0.1, "print_level"=>0)
    optimizer = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver, "atol"=>1e-2, "log_levels"=>[])


    threads = Base.Threads.nthreads()
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    
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
) where {N}

    pm = PowerFlowProblem(AbstractDCPowerModel, JuMP.direct_model(optimizer), Topology(system))
    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    for s in sampleseeds
        println("s=$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system) #creates the up/down sequence for each device.

        for t in 1:N
            println("t=$(t)")
            if field(systemstate, :condition)[t] ≠ true
                update!(pm.topology, systemstate, system, t)
                solve!(pm, systemstate, system, t)
                foreach(recorder -> record!(recorder, system, s, t), recorders)
                empty_model!(pm)
            end
        end

        foreach(recorder -> reset!(recorder, s), recorders)
    end

    put!(results, recorders)

end

""
function initialize!(rng::AbstractRNG, state::SystemState, system::SystemModel{N}) where N

    initialize_availability!(rng, field(state, :branches), field(system, :branches), N)
    initialize_availability!(rng, field(state, :generators), field(system, :generators), N)
    initialize_availability!(rng, field(state, :storages), field(system, :storages), N)
    initialize_availability!(rng, field(state, :generatorstorages), field(system, :generatorstorages), N)
    
    for t in 1:N
        if all([field(state, :branches)[:,t]; field(state, :generators)[:,t]; field(state, :storages)[:,t]; field(state, :generatorstorages)[:,t]]) ≠ true
            field(state, :condition)[t] = 0 
        end
    end

    return

end

""
function solve!(pm::AbstractPowerModel, state::SystemState, system::SystemModel, t::Int)

    #all(field(state, :branches_available)[:,t]) == true ? type = Transportation : type = DCOPF
    type = Transportation
    #build_method!(pm, system, t, type)
    var_bus_voltage(pm, system, t)
    var_gen_power(pm, system, t)
    #var_branch_power(pm, system, t)
    #var_load_curtailment(pm, system, t)
    #JuMP.optimize!(pm.model)
    #build_result!(pm, system, t)
end

""
function update!(topology::Topology, state::SystemState, system::SystemModel, t::Int)

    #update_states!(system, state, t)
    field(topology, :plc)[:] = fill!(field(topology, :plc), 0.0)

    if field(state, :condition)[t] ≠ true
        
        nbuses = length(system.buses)
        
        update_asset_idxs!(
            field(system, :loads), field(topology, :loads_idxs), field(topology, :bus_loads_idxs), 
            field(state, :loads)[:,t], nbuses)

        update_asset_idxs!(
            field(system, :shunts), field(topology, :shunts_idxs), field(topology, :bus_shunts_idxs), 
            field(state, :shunts)[:,t], nbuses)

        update_asset_idxs!(
            field(system, :generators), field(topology, :generators_idxs), field(topology, :bus_generators_idxs), 
            field(state, :generators)[:,t], nbuses)

        update_asset_idxs!(
            field(system, :storages), field(topology, :storages_idxs), field(topology, :bus_storages_idxs), 
            field(state, :storages)[:,t], nbuses)

        update_asset_idxs!(
            field(system, :generatorstorages), field(topology, :generatorstorages_idxs), 
            field(topology, :bus_generatorstorages_idxs), field(state, :generatorstorages)[:,t], nbuses)

        update_branch_idxs!(
            topology, field(system, :branches), field(system, :buses), field(topology, :branches_idxs), 
            field(topology, :buses_idxs), field(state, :branches)[:,t], field(system, :arcs))

    end

    return

end

""
function empty_model!(pm::AbstractPowerModel)

    if JuMP.isempty(pm.model)==false JuMP.empty!(pm.model) end
    empty!(pm.sol)
    println("done")
    return
end

#update_energy!(state.stors_energy, system.storages, t)
#update_energy!(state.genstors_energy, system.generatorstorages, t)

#include("result_report.jl")
include("result_shortfall.jl")
