"Shortfall"
mutable struct SMCShortfallAccumulator <: ResultAccumulator{SequentialMCS,Shortfall}

    # Cross-simulation LOL period count mean/variances
    periodsdropped_total::MeanVariance
    periodsdropped_bus::Vector{MeanVariance}
    periodsdropped_period::Vector{MeanVariance}
    periodsdropped_busperiod::Matrix{MeanVariance}

    # Running LOL period counts for current simulation
    periodsdropped_total_currentsim::Int
    periodsdropped_bus_currentsim::Vector{Int}

    # Cross-simulation UE mean/variances
    unservedload_total::MeanVariance
    unservedload_bus::Vector{MeanVariance}
    unservedload_period::Vector{MeanVariance}
    unservedload_busperiod::Matrix{MeanVariance}

    # Running UE totals for current simulation
    unservedload_total_currentsim::Float64
    unservedload_bus_currentsim::Vector{Float64}
end

""
function merge!(x::SMCShortfallAccumulator, y::SMCShortfallAccumulator)
    merge!(x.periodsdropped_total, y.periodsdropped_total)
    foreach(merge!, x.periodsdropped_bus, y.periodsdropped_bus)
    foreach(merge!, x.periodsdropped_period, y.periodsdropped_period)
    foreach(merge!, x.periodsdropped_busperiod, y.periodsdropped_busperiod)
    merge!(x.unservedload_total, y.unservedload_total)
    foreach(merge!, x.unservedload_bus, y.unservedload_bus)
    foreach(merge!, x.unservedload_period, y.unservedload_period)
    foreach(merge!, x.unservedload_busperiod, y.unservedload_busperiod)
end

accumulatortype(::SequentialMCS, ::Shortfall) = SMCShortfallAccumulator

""
function accumulator(sys::SystemModel{N}, ::SequentialMCS, ::Shortfall) where {N}

    nbuses = length(sys.buses)
    periodsdropped_total = meanvariance()
    periodsdropped_bus = [meanvariance() for _ in 1:nbuses]
    periodsdropped_period = [meanvariance() for _ in 1:N]
    periodsdropped_busperiod = [meanvariance() for _ in 1:nbuses, _ in 1:N]

    periodsdropped_total_currentsim = 0
    periodsdropped_bus_currentsim = zeros(Int, nbuses)

    unservedload_total = meanvariance()
    unservedload_bus = [meanvariance() for _ in 1:nbuses]
    unservedload_period = [meanvariance() for _ in 1:N]
    unservedload_busperiod = [meanvariance() for _ in 1:nbuses, _ in 1:N]

    unservedload_total_currentsim = 0
    unservedload_bus_currentsim = zeros(Float64, nbuses)

    return SMCShortfallAccumulator(
        periodsdropped_total, periodsdropped_bus,
        periodsdropped_period, periodsdropped_busperiod,
        periodsdropped_total_currentsim, periodsdropped_bus_currentsim,
        unservedload_total, unservedload_bus,
        unservedload_period, unservedload_busperiod,
        unservedload_total_currentsim, unservedload_bus_currentsim
    )

end

""
function record!(acc::SMCShortfallAccumulator, topology::Topology, system::SystemModel, sampleid::Int, t::Int)

    totalshortfall = 0
    isshortfall = false

    for r in 1:length(acc.periodsdropped_bus)
        busshortfall = topology.busshortfall_pd[r]
        isbusshortfall = sum(busshortfall) > 1e-6
        fit!(acc.periodsdropped_busperiod[r,t], isbusshortfall)
        fit!(acc.unservedload_busperiod[r,t], busshortfall)

        if isbusshortfall
            isshortfall = true
            totalshortfall += busshortfall
            acc.periodsdropped_bus_currentsim[r] += 1
            acc.unservedload_bus_currentsim[r] += busshortfall
        end
    end

    if isshortfall
        acc.periodsdropped_total_currentsim += 1
        acc.unservedload_total_currentsim += totalshortfall
    end
    fit!(acc.periodsdropped_period[t], isshortfall)
    fit!(acc.unservedload_period[t], totalshortfall)
    return

end

""
function reset!(acc::SMCShortfallAccumulator, sampleid::Int)

    # Store busal / total sums for current simulation
    fit!(acc.periodsdropped_total, acc.periodsdropped_total_currentsim)
    fit!(acc.unservedload_total, acc.unservedload_total_currentsim)

    for r in eachindex(acc.periodsdropped_bus)
        fit!(acc.periodsdropped_bus[r], acc.periodsdropped_bus_currentsim[r])
        fit!(acc.unservedload_bus[r], acc.unservedload_bus_currentsim[r])
    end

    # Reset for new simulation
    acc.periodsdropped_total_currentsim = 0
    fill!(acc.periodsdropped_bus_currentsim, 0)
    acc.unservedload_total_currentsim = 0
    fill!(acc.unservedload_bus_currentsim, 0)
    return
end

""
function finalize(acc::SMCShortfallAccumulator, system::SystemModel{N,L,T}) where {N,L,T}

    ep_total_mean, ep_total_std = mean_std(acc.periodsdropped_total)
    ep_bus_mean, ep_bus_std = mean_std(acc.periodsdropped_bus)
    ep_period_mean, ep_period_std = mean_std(acc.periodsdropped_period)
    ep_busperiod_mean, ep_busperiod_std = mean_std(acc.periodsdropped_busperiod)

    _, ue_total_std = mean_std(acc.unservedload_total)
    _, ue_bus_std = mean_std(acc.unservedload_bus)
    _, ue_period_std = mean_std(acc.unservedload_period)
    ue_busperiod_mean, ue_busperiod_std = mean_std(acc.unservedload_busperiod)

    nsamples = first(acc.unservedload_total.stats).n
    P = BaseModule.powerunits["MW"]
    E = BaseModule.energyunits["MWh"]
    pu2e = conversionfactor(L,T,P,E,system.baseMVA)

    system_peakload, bus_peakload = peakload(system.loads, system.buses)

    return ShortfallResult{N,L,T,P,E}(
        nsamples, 
        field(system, :buses, :keys), 
        field(system, :timestamps),
        ep_total_mean, 
        ep_total_std, 
        ep_bus_mean, 
        ep_bus_std,
        ep_period_mean, 
        ep_period_std,
        ep_busperiod_mean, 
        ep_busperiod_std,
        system.baseMVA*system_peakload,
        system.baseMVA.*bus_peakload,
        pu2e*ue_busperiod_mean, 
        pu2e*ue_total_std,
        pu2e*ue_bus_std, 
        pu2e*ue_period_std, 
        pu2e*ue_busperiod_std)
end

"ShortfallSamples"
struct SMCShortfallSamplesAccumulator <:ResultAccumulator{SequentialMCS,ShortfallSamples}
    shortfall::Array{Float64,3}
end

function merge!(x::SMCShortfallSamplesAccumulator, y::SMCShortfallSamplesAccumulator)
    x.shortfall .+= y.shortfall
    return
end

accumulatortype(::SequentialMCS, ::ShortfallSamples) = SMCShortfallSamplesAccumulator

""
function accumulator(sys::SystemModel{N}, simspec::SequentialMCS, ::ShortfallSamples) where {N}
    nbuses = length(sys.buses)
    shortfall = zeros(Int, nbuses, N, simspec.nsamples)
    return SMCShortfallSamplesAccumulator(shortfall)
end

""
function record!(
    acc::SMCShortfallSamplesAccumulator, topology::Topology, system::SystemModel, sampleid::Int, t::Int)

    for r in 1:length(system.buses)
        acc.shortfall[r,t,sampleid] = topology.busshortfall_pd[r]
    end
    return

end

reset!(acc::SMCShortfallSamplesAccumulator, sampleid::Int) = nothing

""
function finalize(acc::SMCShortfallSamplesAccumulator, system::SystemModel{N,L,T}) where {N,L,T}
    P = BaseModule.powerunits["MW"]
    E = BaseModule.energyunits["MWh"]
    pu2p = conversionfactor(L,P,system.baseMVA)
    pu2e = conversionfactor(L,T,P,E,system.baseMVA)
    return ShortfallSamplesResult{N,L,T,P,E}(
        field(system, :buses, :keys), field(system, :timestamps), pu2p*acc.shortfall,pu2e*acc.shortfall)
end