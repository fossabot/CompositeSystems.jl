@reexport module CompositeAdequacy

    using ..BaseModule
    using ..OPF

    import Base: -, getindex, merge!, finalize
    import Dates: Dates, DateTime, Period
    import Decimals: Decimal, decimal
    import OnlineStatsBase: EqualWeight, fit!, Mean, value, Variance
    import OnlineStats: Series
    import Printf: @sprintf
    import Random: AbstractRNG, rand, seed!
    import Random123: Philox4x
    import StatsBase: mean, std, stderror
    import TimeZones: ZonedDateTime
    import XLSX: rename!, addsheet!, openxlsx
    import Distributions: ccdf, Normal
    import Base: minimum, maximum, extrema
    import Distributed: Distributed, @distributed, RemoteChannel
    import Gurobi: Env, GRBsetintparam
    import Requires: @require
    import JuMP

    function __init__()
        @info "If you have Gurobi installed and want to use it, make sure to `using Gurobi` in order to enable it."
        @require Gurobi = "2e9cd046-0924-5485-92f1-d5272153d98b" include("gurobi_setup.jl")
    end

    export
        # CompositeAdequacy submoduleexport
        assess, SimulationSpec,
        
        # Metrics
        ReliabilityMetric, EDLC, EENS, SI, ELCC, ETC, MeanEstimate, val, stderror,

        # Simulation specification
        SequentialMCS, accumulator,

        # Result specifications
        Shortfall, ShortfallSamples,
        GeneratorAvailability, StorageAvailability, 
        BranchAvailability, ShuntAvailability,
        Utilization, UtilizationSamples,

        #utils
        print_results, copy_load, update_load!, 
        resultremotechannel, finalize,

        # Convenience re-exports
        ZonedDateTime
    #
    include("statistics.jl")
    include("types.jl")
    include("results/results.jl")
    include("results/CapacityValueResult.jl")
    include("results/ELCC.jl")
    include("results/ETC.jl")
    include("simulations/simulations.jl")
    include("utils.jl")
end