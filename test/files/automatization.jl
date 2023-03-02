using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using XLSX, Dates
include("solvers.jl")

resultspecs = (Shortfall(), GeneratorAvailability())
settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = false,
    min_generators_off = 0,
    set_string_names_on_creation = false
)

timeseriesfile = "test/data/RTS/Loads_system.xlsx"
rawfile = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile = "test/data/others/Storage/R_RTS_strg.m"
resultspecs = (Shortfall(), GeneratorAvailability())
method = SequentialMCS(samples=2500, seed=100, threaded=true)
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

for bus in 1:1:9
    run_mcs(system, method, settings, resultspecs, bus)
end

function run_mcs(system, method, settings, resultspecs, bus::Int)
    system.storages.buses[1] = bus
    system.storages.charge_rating[1] = 1.00
    system.storages.discharge_rating[1] = 1.00
    system.storages.thermal_rating[1] = 1.00
    for i in 1.0:1.0:4.0
    #for i in 0.5:0.5:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

    system.storages.charge_rating[1] = 1.50
    system.storages.discharge_rating[1] = 1.50
    system.storages.thermal_rating[1] = 1.50
    for i in 1.0:1.0:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

    system.storages.charge_rating[1] = 2.0
    system.storages.discharge_rating[1] = 2.0
    system.storages.thermal_rating[1] = 2.0
    for i in 1.0:1.0:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

    system.storages.charge_rating[1] = 2.5
    system.storages.discharge_rating[1] = 2.5
    system.storages.thermal_rating[1] = 2.5
    for i in 1.0:1.0:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

    system.storages.charge_rating[1] = 3
    system.storages.discharge_rating[1] = 3
    system.storages.thermal_rating[1] = 3
    for i in 1.0:1.0:4.0
        system.storages.energy_rating[1] = i
        shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
        print_results(shortfall)
    end

end
