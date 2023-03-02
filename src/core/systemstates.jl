"Definition of States"
abstract type AbstractState end

"SystemStates structure with matrices for Sequential MCS"
struct SystemStates <: AbstractState

    buses::Matrix{Int}
    loads::Matrix{Bool}
    branches::Matrix{Bool}
    commonbranches::Matrix{Bool}
    shunts::Matrix{Bool}
    generators::Matrix{Float32}
    storages::Matrix{Bool}
    generatorstorages::Matrix{Bool}
    se::Matrix{Float64}
    gse::Matrix{Float64}
    plc::Vector{Float64}
    qlc::Vector{Float64}
end

"SystemStates structure with matrices for Sequential MCS"
function SystemStates(system::SystemModel{N}; available::Bool=false) where {N}

    bus_type = field(system, :buses, :bus_type)
    buses = Array{Int, 2}(undef, length(system.buses), N)

    for j in 1:N
        for i in eachindex(system.buses.keys)
            buses[i,j] = bus_type[i]
        end
    end

    loads = Array{Bool, 2}(undef, length(system.loads), N)
    branches = Array{Bool, 2}(undef, length(system.branches), N)
    shunts = Array{Bool, 2}(undef, length(system.shunts), N)
    commonbranches = Array{Bool, 2}(undef, length(system.commonbranches), N)
    generators = Array{Float32, 2}(undef, length(system.generators), N)
    storages = Array{Bool, 2}(undef, length(system.storages), N)
    generatorstorages = Array{Bool, 2}(undef, length(system.generatorstorages), N)

    se = Array{Float64, 2}(undef, length(system.storages), N) #stored energy
    gse = Array{Float64, 2}(undef, length(system.generatorstorages), N) #stored energy
    plc = Array{Float64}(undef, length(system.buses))
    qlc = Array{Float64}(undef, length(system.buses))

    fill!(loads, 1)
    fill!(shunts, 1)
    fill!(se, 0)
    fill!(gse, 0)
    fill!(plc, 0)
    fill!(qlc, 0)


    
    if available==true
        fill!(branches, 1)
        fill!(commonbranches, 1)
        fill!(shunts, 1)
        fill!(generators, 1)
        fill!(storages, 1)
        fill!(generatorstorages, 1)
    end

    return SystemStates(buses, loads, branches, commonbranches, shunts, generators, storages, generatorstorages, se, gse, plc, qlc)
    
end

""
struct NextTransition <: AbstractState

    branches_available::Vector{Bool}
    branches_nexttransition::Vector{Int}
    shunts_available::Vector{Bool}
    shunts_nexttransition::Vector{Int}
    generators_available::Vector{Bool}
    generators_nexttransition::Vector{Int}
    commonbranches_available::Vector{Bool}
    commonbranches_nexttransition::Vector{Int}
    storages_available::Vector{Bool}
    storages_nexttransition::Vector{Int}
    generatorstorages_available::Vector{Bool}
    generatorstorages_nexttransition::Vector{Int}

    function NextTransition(system::SystemModel)

        nbranches = length(system.branches)
        branches_available = Vector{Bool}(undef, nbranches)
        branches_nexttransition= Vector{Int}(undef, nbranches)

        nshunts = length(system.shunts)
        shunts_available = Vector{Bool}(undef, nshunts)
        shunts_nexttransition= Vector{Int}(undef, nshunts)

        ngens = length(system.generators)
        generators_available = Vector{Bool}(undef, ngens)
        generators_nexttransition= Vector{Int}(undef, ngens)

        ncommonbranches = length(system.commonbranches)
        commonbranches_available = Vector{Bool}(undef, ncommonbranches)
        commonbranches_nexttransition= Vector{Int}(undef, ncommonbranches)

        nstors = length(system.storages)
        storages_available = Vector{Bool}(undef, nstors)
        storages_nexttransition = Vector{Int}(undef, nstors)

        ngenstors = length(system.generatorstorages)
        generatorstorages_available = Vector{Bool}(undef, ngenstors)
        generatorstorages_nexttransition = Vector{Int}(undef, ngenstors)

        return new(
            branches_available, branches_nexttransition,
            shunts_available, shunts_nexttransition,
            generators_available, generators_nexttransition,
            commonbranches_available, commonbranches_nexttransition,
            storages_available, storages_nexttransition,
            generatorstorages_available, generatorstorages_nexttransition
        )
    end
end