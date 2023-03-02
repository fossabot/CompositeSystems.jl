@reexport module BaseModule
    import XLSX
    import Dates: Dates, @dateformat_str, AbstractDateTime, DateTime, Time, 
        Period, Hour, Day, Year, Date, hour, now, format
    import TimeZones: TimeZone, ZonedDateTime
    import StatsBase: mean, std, stderror
    import LinearAlgebra
    import Memento
    import SparseArrays: SparseMatrixCSC, sparse, nonzeros
    import InfrastructureModels
    import PowerModels
    const _IM = InfrastructureModels
    const _PM = PowerModels

    export
        # System assets
        AbstractAssets, Buses, Loads, Branches, Shunts, Generators, 
        Storages, GeneratorStorages, CommonBranches,

        # Units
        Period, Hour, Day, Year,
        PowerUnit, kW, MW, GW,
        EnergyUnit, kWh, MWh, GWh,

        unitsymbol, conversionfactor, powertoenergy, energytopower,

        # Main data structure
        SystemModel, SystemStates, NextTransition, static_parameters,

        #utils
        assetgrouplist, makeidxlist, field, build_network, 
        calc_buspair_parameters, check_availability
    #

    # Create our module level logger (this will get precompiled)
    const _LOGGER = Memento.getlogger(@__MODULE__)
    __init__() = Memento.register(_LOGGER)

    "Suppresses information and warning messages output by PowerModels, for fine grained control use the Memento package"
    function silence()
        Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session. 
        Use the Memento package for more fine-grained control of logging.")
        Memento.setlevel!(Memento.getlogger(_IM), "error")
        Memento.setlevel!(Memento.getlogger(PowerModels), "error")
        Memento.setlevel!(Memento.getlogger(BaseModule), "error")
    end
 
    include("SystemModel/units.jl")
    include("SystemModel/assets.jl")
    include("SystemModel/utils.jl")
    include("SystemModel.jl")
    include("utils.jl")
    include("load.jl")
    include("systemstates.jl")

end