using CompositeSystems, CompositeSystems.OPF, CompositeSystems.BaseModule
using CompositeSystems.OPF
using CompositeSystems.CompositeAdequacy
import PowerModels, Ipopt, Juniper, BenchmarkTools, JuMP
import JuMP: termination_status
import PowerModels
import BenchmarkTools: @btime
using XLSX, Dates
include("solvers.jl")

settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = false
)

timeseriesfile = "test/data/RTS/Loads_system.xlsx"
rawfile = "test/data/others/Storage/RTS_strg.m"
Base_reliabilityfile = "test/data/others/Storage/R_RTS_strg.m"
resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
method = SequentialMCS(samples=2000, seed=100, threaded=true)
system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

function run_mcs(system, method, settings, resultspecs, bus::Int)
    hour = Dates.format(Dates.now(),"HH_MM_SS")
    current_dir = pwd()
    new_dir = mkdir("new_job_"*hour)
    cd(new_dir)
    for j in 0.75:0.25:2.0
        system.storages.buses[1] = bus
        system.storages.charge_rating[1] = j
        system.storages.discharge_rating[1] = j
        system.storages.thermal_rating[1] = j
        for i in 0.25:0.25:3.0
            system.storages.energy_rating[1] = i
            shortfall, _ = CompositeSystems.assess(system, method, settings, resultspecs...)
            CompositeAdequacy.print_results(system, shortfall)
            println("Bus: $(bus) power_rating: $(j), energy_rating: $(i)")
        end
    end
    cd(current_dir)
end

run_mcs(system, method, settings, resultspecs, 7)

#bus 6, power_rating=1.0