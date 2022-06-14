include("SystemState.jl")
include("DispatchProblem.jl")
include("utils.jl")

struct SequentialMonteCarlo <: SimulationSpec

    nsamples::Int
    seed::UInt64
    verbose::Bool

    function SequentialMonteCarlo(;
        samples::Int=10_000, seed::Integer=rand(UInt64),
        verbose::Bool=false
    )
        samples <= 0 && throw(DomainError("Sample count must be positive"))
        seed < 0 && throw(DomainError("Random seed must be non-negative"))
        new(samples, UInt64(seed), verbose)
    end

end

function assess(
    system::SystemModel,
    method::SequentialMonteCarlo,
    resultspecs::ResultSpec...
)
    
    #threads = Base.Threads.nthreads()
    threads = 1
    sampleseeds = Channel{Int}(2*threads)
    results = resultchannel(method, resultspecs, threads)
    @async makeseeds(sampleseeds, method.nsamples)  # feed the sampleseeds channel with #N samples.

    assess(system, method, sampleseeds, results, resultspecs...)
    return finalize(results, system)
    
end

"It generates a sequence of seeds from a given number of samples"
function makeseeds(sampleseeds::Channel{Int}, nsamples::Int)

    for s in 1:nsamples
        put!(sampleseeds, s)
    end

    close(sampleseeds)

end

function assess(
    system::SystemModel{N}, method::SequentialMonteCarlo,
    sampleseeds::Channel{Int},
    results::Channel{<:Tuple{Vararg{ResultAccumulator{SequentialMonteCarlo}}}},
    resultspecs::ResultSpec...
) where {R<:ResultSpec, N}

    dispatchproblem = DispatchProblem(system)
    systemstate = SystemState(system)
    recorders = accumulator.(system, method, resultspecs)

    rng = Philox4x((0, 0), 10)

    for s in sampleseeds

        seed!(rng, (method.seed, s))  #using the same seed for entire period.
        initialize!(rng, systemstate, system)

        for t in 1:N

            advance!(rng, systemstate, dispatchproblem, system, t)
            solve!(dispatchproblem, systemstate, system, t)
            foreach(recorder -> record!(
                        recorder, system, systemstate, dispatchproblem, s, t
                    ), recorders)

        end

        foreach(recorder -> reset!(recorder, s), recorders)

    end

    put!(results, recorders)

end

function initialize!(
    rng::AbstractRNG, state::SystemState, system::SystemModel{N}
) where N

        initialize_availability!(
            rng, state.gens_available, state.gens_nexttransition,
            system.generators, N)

        initialize_availability!(
            rng, state.stors_available, state.stors_nexttransition,
            system.storages, N)

        initialize_availability!(
            rng, state.genstors_available, state.genstors_nexttransition,
            system.generatorstorages, N)

        initialize_availability!(
            rng, state.lines_available, state.lines_nexttransition,
            system.lines, N)

        fill!(state.stors_energy, 0)
        fill!(state.genstors_energy, 0)

        return

end

function advance!(
    rng::AbstractRNG,
    state::SystemState,
    dispatchproblem::DispatchProblem,
    system::SystemModel{N}, t::Int) where N

    update_availability!(
        rng, state.gens_available, state.gens_nexttransition,
        system.generators, t, N)

    update_availability!(
        rng, state.stors_available, state.stors_nexttransition,
        system.storages, t, N)

    update_availability!(
        rng, state.genstors_available, state.genstors_nexttransition,
        system.generatorstorages, t, N)

    update_availability!(
        rng, state.lines_available, state.lines_nexttransition,
        system.lines, t, N)

    update_energy!(state.stors_energy, system.storages, t)
    update_energy!(state.genstors_energy, system.generatorstorages, t)

    update_problem!(dispatchproblem, state, system, t)

end

function solve!(
    dispatchproblem::DispatchProblem, state::SystemState,
    system::SystemModel, t::Int
)
    solveflows!(dispatchproblem.fp)
    update_state!(state, dispatchproblem, system, t)
end

include("result_shortfall.jl")
include("result_availability.jl")
