include("utils.jl")

"""
This code snippet is using multi-threading and distributed computing to parallelize 
the assess function by running multiple instances of it simultaneously on different threads
and machines. The Threads.@spawn macro is used to create new threads, each of which will execute 
the assess function using a different seed from the sampleseeds channel. The results of each 
thread are stored in the results channel, and the function finalize is called on the results
after all threads have finished executing.
"""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    resultspecs::ResultSpec...
) where {N}
    #Number of workers excluding the master process
    nworkers = max(method.include_master ? Distributed.nprocs() : Distributed.nprocs() - 1, 1)
    nthreads = method.threaded ? Base.Threads.nthreads() : 1

    # Use RemoteChannel for distributed computing or Channel otherwise.
    results = nworkers > 1 ? 
        resultremotechannel(method, resultspecs, nworkers) : 
        resultchannel(method, resultspecs, nworkers)

    # Compute on worker processes
    if nworkers > 1
        method.include_master ? 
            compute_with_master_included(system, method, settings, nworkers, nthreads, results, resultspecs...) :
            compute_without_master_included(system, method, settings, nworkers, nthreads, results, resultspecs...)
    else
        # In case there is only one worker, just run the master process
        master_result = assess(system, method, settings, 1, nthreads, 1, resultspecs...)
        put!(results, master_result)
    end

    return finalize!(results, system, nworkers)
end

""
function compute_with_master_included(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings, 
    nworkers::Int, 
    nthreads::Int, 
    results::Distributed.RemoteChannel{R}, 
    resultspecs::ResultSpec...) where {N, R <: Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}}}

    method.verbose && @info("CompositeSystems will distribute the workload across $(nworkers) nodes")

    @sync begin
        @async begin
            # Compute on the master process/worker
            master_result = assess(system, method, settings, nworkers, nthreads, 1, resultspecs...)
            put!(results, master_result)
        end

        for k in 2:nworkers
            @async begin
                result = fetch(Distributed.pmap(
                    i -> assess(system, method, settings, nworkers, nthreads, i, resultspecs...), k))
                put!(results, result)
            end
        end
    end
end

""
function compute_without_master_included(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings, 
    nworkers::Int, 
    nthreads::Int, 
    results::Distributed.RemoteChannel{R}, 
    resultspecs::ResultSpec...) where {N, R <: Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}}}    

    method.verbose && @info("CompositeSystems will distribute the workload across $(nworkers) nodes")

    for k in 1:nworkers
        @async begin
            result = fetch(Distributed.pmap(
                i -> assess(system, method, settings, nworkers, nthreads, i, resultspecs...), k))
            put!(results, result)
        end
    end
end

"""
This code snippet is using multi-threading to parallelize the assess function by running 
multiple instances of it simultaneously on different threads. The Threads.@spawn macro is 
used to create new threads, each of which will execute the assess function using a different 
seed from the sampleseeds channel. The results of each thread are stored in the results channel, 
and the function finalize is called on the results after all threads have finished executing.
"""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    nworkers::Int,
    nthreads::Int,
    worker::Int,
    resultspecs::ResultSpec...
) where {N}

    sampleseeds = Channel{Int}(2*nthreads)
    results = resultchannel(method, resultspecs, nthreads)
    nsamples_per_worker = div(method.nsamples, nworkers)
    start_index = (worker - 1) * nsamples_per_worker + 1
    end_index = min(worker * nsamples_per_worker, method.nsamples)
    Threads.@spawn makeseeds(sampleseeds, start_index, end_index)

    check_optimizer!(settings)
    settings.optimizer_name === "Gurobi" && CompositeAdequacy.init_gurobi_env(nthreads)

    if method.threaded && nthreads > 1
        for _ in 1:nthreads
            Threads.@spawn assess(system, method, settings, sampleseeds, results, resultspecs...)
        end
    else
        assess(system, method, settings, sampleseeds, results, resultspecs...)
    end
    
    outcome = take_Results!(results, nthreads)
    settings.optimizer_name === "Gurobi" && CompositeAdequacy.end_gurobi_env()
    return outcome
end

"""
This assess function is designed to perform a Monte Carlo simulation using the Sequential Monte 
Carlo (SMC) method. The function uses the pm variable to store an abstract model of the system, 
and the StateTransition variables to store the system's states. It also creates several recorders 
using the accumulator function, and an RNG (random number generator) of type Philox4x. The function 
then iterates over the sampleseeds channel, using each seed to initialize the RNG and the system states, 
and performs the Monte Carlo simulation for each sample.
The results of each thread are stored in the results channel using the put! function. 
After all the threads have finished executing, the finalize function is called on the 
results to process the results and return the final result.
"""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    sampleseeds::Channel{Int},
    results::RemoteChannel{R},
    resultspecs::ResultSpec...
) where {N, R<:Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}}}

    pm = settings.optimizer_name === "Gurobi" ? 
        abstract_model(system, settings, CompositeAdequacy.GRB_ENV[]) : 
        abstract_model(system, settings)

    statetransition = StateTransition(system)
    build_problem!(pm, system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, statetransition, pm.topology, system) #creates the up/down sequence for each device.

        for t in 1:N
            update!(rng, statetransition, pm.topology, system, t)
            solve!(pm, system, settings, t)
            foreach(recorder -> record!(recorder, pm.topology, system, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
        method.verbose && @info("Replication #$(s)")
    end

    Base.finalize(JuMP.backend(pm.model).optimizer)
    put!(results, recorders)
end

""
function assess(
    system::SystemModel{N},
    method::SequentialMCS,
    settings::Settings,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMCS}}}},
    resultspecs::ResultSpec...
) where {N}

    pm = settings.optimizer_name === "Gurobi" ? 
        abstract_model(system, settings, CompositeAdequacy.GRB_ENV[]) : abstract_model(system, settings)

    statetransition = StateTransition(system)
    build_problem!(pm, system)
    recorders = accumulator.(system, method, resultspecs)
    rng = Philox4x((0, 0), 10)

    for s in sampleseeds
        method.verbose && @info("Replication #$(s)")
        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, statetransition, pm.topology, system) #creates the up/down sequence for each device.

        for t in 1:N
            #println("t=$(t)")
            update!(rng, statetransition, pm.topology, system, t)
            solve!(pm, system, settings, t)
            foreach(recorder -> record!(recorder, pm.topology, system, s, t), recorders)
        end

        foreach(recorder -> reset!(recorder, s), recorders)
    end

    Base.finalize(JuMP.backend(pm.model).optimizer)
    put!(results, recorders)
    return results
end

"""
The initialize! function creates an initial state of the system by using the Philox4x 
random number generator to randomly determine the availability of different assets 
(buses, branches, interfaces, generators, and storages) for each time step.
"""
function initialize!(rng::AbstractRNG, 
    statetransition::StateTransition, topology::Topology, system::SystemModel{N}) where N

    initialize_availability!(rng, statetransition.branches_available, 
        statetransition.branches_nexttransition, system.branches, N)

    initialize_availability!(rng, statetransition.interfaces_available, 
        statetransition.interfaces_nexttransition, system.interfaces, N) 
    
    initialize_availability!(rng, statetransition.generators_available, 
        statetransition.generators_nexttransition, system.generators, N)

    initialize_availability!(rng, statetransition.storages_available, 
        statetransition.storages_nexttransition, system.storages, N)    

    OPF.update_states!(topology, statetransition)
    return
end

"The function update! updates the system states for a given time step t."
function update!(rng::AbstractRNG, 
    statetransition::StateTransition, topology::Topology, system::SystemModel{N}, t::Int) where N
    
    update_availability!(rng, statetransition.branches_available, 
        statetransition.branches_nexttransition, system.branches, t, N)
    
    update_availability!(rng, statetransition.interfaces_available, 
        statetransition.interfaces_nexttransition, system.interfaces, t, N)

    update_availability!(rng, statetransition.generators_available, 
        statetransition.generators_nexttransition, system.generators, t, N)

    update_availability!(rng, statetransition.storages_available, 
        statetransition.storages_nexttransition, system.storages, t, N)

    OPF.update_states!(topology, statetransition, t)
    #apply_common_outages!(topology, system.branches, t)
    return
end

include("result_shortfall.jl")
include("result_availability.jl")
include("result_utilization.jl")