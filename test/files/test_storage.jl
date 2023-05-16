@testset "RBTS system, sequential outages, storage at bus 6" begin
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    rawfile = "test/data/others/Storage/RBTS_strg.m"
    reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
    settings = CompositeSystems.Settings(
        juniper_optimizer_1;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = false
    )
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
    for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
    
    system.storages.buses[1] = 6
    system.storages.charge_rating[1] = 0.25
    system.storages.discharge_rating[1] = 0.25
    system.storages.thermal_rating[1] = 0.25
    system.storages.energy_rating[1] = 2
    pm = OPF.abstract_model(system, settings)
    componentstates = OPF.ComponentStates(system, available=true)
    OPF.build_problem!(pm, system, 1)
    OPF.field(system, :storages, :energy)[1] = 0.0
    
    t=1
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=1, No outages" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(system.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
    end
    
    t=2
    OPF.update!(pm, system, componentstates, settings, t)  
    @testset "t=2, No outages" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(componentstates.stored_energy[t], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
    end
    
    t=3
    componentstates.stored_energy[t-1] = OPF.field(system, :storages, :energy_rating)[1] #stored_energy(t-1) = 2.0
    componentstates.generators[3,t] = 0
    componentstates.generators[7,t] = 0
    componentstates.generators[8,t] = 0
    componentstates.generators[9,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=3, G3, G7, G8 and G9 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.1; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.1; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 2.0 - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end
    
    t=4
    componentstates.branches[5,t] = 0
    componentstates.branches[8,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=4, L5 and L8 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.15; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0.15; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.75 - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end
    
    t=5
    componentstates.branches[3,t] = 0
    componentstates.branches[4,t] = 0
    componentstates.branches[8,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)  
    
    @testset "t=5, L3, L4 and L8 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.15; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.15; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.15; atol = 1e-4)
    end
    
    t=6
    componentstates.branches[2,t] = 0
    componentstates.branches[7,t] = 0
    componentstates.generators[1,t] = 0
    componentstates.generators[2,t] = 0
    componentstates.generators[3,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 
    
    @testset "L2 and L7 on outage, generation reduced" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.49; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.49; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15 - 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.25; atol = 1e-4)
    end

    t=7
    componentstates.branches[2,t] = 0
    componentstates.generators[1,t] = 0
    componentstates.generators[2,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L2 on outage, generation reduced" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15 - 0.25 - 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end

    t=8
    componentstates.branches[1,t] = 0
    componentstates.branches[6,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L1 and L6 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.23; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15 - 0.25 - 0.25 - 0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.23; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[2]["from"], 0.71; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[7]["from"], 0.71; atol = 1e-4)
    end

    t=9
    componentstates.branches[4,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L4 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.5 - 0.15 - 0.25 - 0.25 - 0.23 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

end

@testset "RBTS system, sequential outages, storage at bus 2" begin
    timeseriesfile = "test/data/RBTS/Loads_system.xlsx"
    rawfile = "test/data/others/Storage/RBTS_strg.m"
    reliabilityfile = "test/data/others/Storage/R_RBTS_strg.m"
    settings = CompositeSystems.Settings(
        juniper_optimizer_1;
        jump_modelmode = JuMP.AUTOMATIC,
        powermodel_formulation = OPF.DCPPowerModel,
        select_largest_splitnetwork = false,
        deactivate_isolated_bus_gens_stors = false
    )
    system = BaseModule.SystemModel(rawfile, reliabilityfile, timeseriesfile)
    for t in 1:8736 system.loads.pd[:,t] = [0.2; 0.85; 0.4; 0.2; 0.2] end
    
    system.storages.buses[1] = 2
    system.storages.charge_rating[1] = 0.25
    system.storages.discharge_rating[1] = 0.25
    system.storages.thermal_rating[1] = 0.25
    system.storages.energy_rating[1] = 2
    pm = OPF.abstract_model(system, settings)
    componentstates = OPF.ComponentStates(system, available=true)
    OPF.build_problem!(pm, system, 1)
    OPF.field(system, :storages, :energy)[1] = 0.0
    
    t=1
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=1, No outages" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(system.storages.charge_rating[1], 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
    end
    
    t=2
    OPF.update!(pm, system, componentstates, settings, t)  
    @testset "t=2, No outages" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4) 
        @test isapprox(componentstates.stored_energy[t], 0.5; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.00; atol = 1e-4)
    end
    
    t=3
    componentstates.stored_energy[t-1] = 1.0 #stored_energy(t-1) = 2.0
    componentstates.generators[3,t] = 0
    componentstates.generators[7,t] = 0
    componentstates.generators[8,t] = 0
    componentstates.generators[9,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=3, G3, G7, G8 and G9 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.1; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.1; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 - system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end
    
    t=4
    componentstates.branches[5,t] = 0
    componentstates.branches[8,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)
    
    @testset "t=4, L5 and L8 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.40; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4) #without storage it should be 0.35
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0.20; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0.20; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 0.75 + system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end
    
    t=5
    componentstates.branches[3,t] = 0
    componentstates.branches[4,t] = 0
    componentstates.branches[8,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "t=5, L3, L4 and L8 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.15; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.15; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
    end

    t=6
    componentstates.branches[2,t] = 0
    componentstates.branches[7,t] = 0
    componentstates.generators[1,t] = 0
    componentstates.generators[2,t] = 0
    componentstates.generators[3,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L2 and L7 on outage, generation reduced" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.74; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.74; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[3]["from"], 0.71; atol = 1e-4)
    end

    t=7
    componentstates.branches[2,t] = 0
    componentstates.generators[1,t] = 0
    componentstates.generators[2,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L2 on outage, generation reduced" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) - 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
    end

    t=8
    componentstates.branches[1,t] = 0
    componentstates.branches[6,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L1 and L6 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.23; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0.23; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[2]["from"], 0.71; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :p, :), system.branches)[7]["from"], 0.71; atol = 1e-4)
    end

    t=9
    componentstates.branches[4,t] = 0
    OPF.update!(pm, system, componentstates, settings, t) 

    @testset "L1 and L6 on outage" begin
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :pg, :)))), 1.85 - sum(componentstates.p_curtailed[:]) + 0.25; atol = 1e-4)
        @test isapprox(componentstates.stored_energy[t], 1.0 + 0.25 + 0.25 + 0.25; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], system.storages.charge_rating[1]; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

end

@testset "RTS system, sequential outages, storage at bus 8" begin
    
    settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = true
    )

    timeseriesfile = "test/data/RTS/Loads_system.xlsx"
    rawfile = "test/data/others/Storage/RTS_strg.m"
    Base_reliabilityfile = "test/data/others/Storage/R_RTS_strg.m"
    resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())

    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

    system.branches.rate_a[11] = system.branches.rate_a[11]*0.75
    system.branches.rate_a[12] = system.branches.rate_a[12]*0.75
    system.branches.rate_a[13] = system.branches.rate_a[13]*0.75

    data = OPF.build_network(rawfile, symbol=false)
    load_pd = Dict{Int, Float64}()
    for (k,v) in data["load"]
        load_pd[parse(Int,k)] = v["pd"]
        system.loads.qd[parse(Int,k)] = v["qd"]
    end

    for t in 1:8736
        for i in system.loads.keys
            system.loads.pd[i,t] = load_pd[i]
        end
    end

    system.storages.buses[1] = 8
    system.storages.charge_rating[1] = 0.75
    system.storages.discharge_rating[1] = 0.75
    system.storages.thermal_rating[1] = 0.75
    system.storages.energy_rating[1] = 1.50
    pm = OPF.abstract_model(system, settings)
    componentstates = OPF.ComponentStates(system, available=true)
    OPF.build_problem!(pm, system, 1)
    OPF.field(system, :storages, :energy)[1] = 0.0

    t=1
    OPF.update!(pm, system, componentstates, settings, t)
    @testset "No outages" begin
        @test isapprox(OPF.check_availability(componentstates.storages, t, t-1), false; atol = 1e-4)
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

    t=2
    componentstates.storages[1,t] = 0
    componentstates.branches[29,t] = 0
    componentstates.branches[36,t] = 0
    componentstates.branches[37,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "Outages on storage device and lines L29, L36, L37" begin
        @test isapprox(OPF.check_availability(componentstates.storages, t, t-1), false; atol = 1e-4)
        @test isapprox(sum(componentstates.p_curtailed[:]), 3.09; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 1.81; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 1.28; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

    t=3
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "No outages" begin
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

    t=4
    componentstates.branches[5,t] = 0
    componentstates.branches[11,t] = 0
    componentstates.branches[12,t] = 0
    componentstates.branches[13,t] = 0
    componentstates.branches[15,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "Outages on L5, L11, L12, L13, L15" begin
        @test isapprox(sum(componentstates.p_curtailed[:]), 2.210; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 1.25; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0.96; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.75; atol = 1e-4)
    end

    t=5
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "No outages" begin
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

    t=6
    componentstates.storages[1,t] = 0
    componentstates.branches[5,t] = 0
    componentstates.branches[11,t] = 0
    componentstates.branches[12,t] = 0
    componentstates.branches[13,t] = 0
    componentstates.branches[15,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "Outages on L5, L11, L12, L13, L15" begin
        @test isapprox(sum(componentstates.p_curtailed[:]), 2.210+0.75; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 1.25; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0.96+0.75; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end
end

@testset "RTS system, sequential outages, storage at bus 9" begin

    settings = CompositeSystems.Settings(
    gurobi_optimizer_3,
    jump_modelmode = JuMP.AUTOMATIC,
    powermodel_formulation = OPF.DCMPPowerModel,
    select_largest_splitnetwork = false,
    deactivate_isolated_bus_gens_stors = true,
    min_generators_off = 0,
    set_string_names_on_creation = true
    )

    timeseriesfile = "test/data/RTS/Loads_system.xlsx"
    rawfile = "test/data/others/Storage/RTS_strg.m"
    Base_reliabilityfile = "test/data/others/Storage/R_RTS_strg.m"
    resultspecs = (CompositeAdequacy.Shortfall(), CompositeAdequacy.Utilization())
    system = BaseModule.SystemModel(rawfile, Base_reliabilityfile, timeseriesfile)

    data = OPF.build_network(rawfile, symbol=false)
    load_pd = Dict{Int, Float64}()
    for (k,v) in data["load"]
        load_pd[parse(Int,k)] = v["pd"]
        system.loads.qd[parse(Int,k)] = v["qd"]
    end

    for t in 1:8736
        for i in system.loads.keys
            system.loads.pd[i,t] = load_pd[i]
        end
    end

    system.storages.buses[1] = 9
    system.storages.charge_rating[1] = 0.75
    system.storages.discharge_rating[1] = 0.75
    system.storages.thermal_rating[1] = 0.75
    system.storages.energy_rating[1] = 1.50
    system.branches.rate_a[7] = system.branches.rate_a[7]*0.50
    system.branches.rate_a[14] = system.branches.rate_a[14]*0.50
    system.branches.rate_a[15] = system.branches.rate_a[15]*0.50
    system.branches.rate_a[16] = system.branches.rate_a[16]*0.50
    system.branches.rate_a[17] = system.branches.rate_a[17]*0.50


    pm = OPF.abstract_model(system, settings)
    componentstates = OPF.ComponentStates(system, available=true)
    OPF.build_problem!(pm, system, 1)
    OPF.field(system, :storages, :energy)[1] = 0.0

    t=1
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "No outages" begin
        #@test isapprox(check_availability(componentstates.storages, t, t-1), false; atol = 1e-4)
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

    t=2
    componentstates.storages[1,t] = 0
    componentstates.branches[15,t] = 0.0
    componentstates.branches[16,t] = 0.0
    componentstates.branches[17,t] = 0.0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "Outages on T15, T16, L17" begin
        @test isapprox(sum(componentstates.p_curtailed[:]), 1.38; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 1.38; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

    t=3
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "No outages" begin
        #@test isapprox(check_availability(componentstates.storages, t, t-1), false; atol = 1e-4)
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

    t=4
    componentstates.branches[15,t] = 0.0
    componentstates.branches[16,t] = 0.0
    componentstates.branches[17,t] = 0.0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "Outages on T15, T16, L17" begin
        @test isapprox(sum(componentstates.p_curtailed[:]), 0.63; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0.63; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], -0.75; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.75; atol = 1e-4)
    end


    t=5
    componentstates.storages[1,t] = 0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "No outages" begin
        #@test isapprox(check_availability(componentstates.storages, t, t-1), false; atol = 1e-4)
        @test isapprox(sum(componentstates.p_curtailed[:]), 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test isapprox(sum(values(OPF.build_sol_values(OPF.var(pm, :z_shunt, :)))), 1; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end

    t=6
    componentstates.storages[1,t] = 0
    componentstates.branches[15,t] = 0.0
    componentstates.branches[16,t] = 0.0
    componentstates.branches[17,t] = 0.0
    OPF.update!(pm, system, componentstates, settings, t)

    @testset "Outages on T15, T16, L17" begin
        @test isapprox(sum(componentstates.p_curtailed[:]), 1.38; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[1], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[2], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[3], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[4], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[5], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[6], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[7], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[8], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[9], 1.38; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[10], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[11], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[12], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[13], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[14], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[15], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[16], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[17], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[18], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[19], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[20], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[21], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[22], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[23], 0; atol = 1e-4)
        @test isapprox(componentstates.p_curtailed[24], 0; atol = 1e-4)
        @test JuMP.termination_status(pm.model) ≠ JuMP.NUMERICAL_ERROR
        @test JuMP.termination_status(pm.model) ≠ JuMP.INFEASIBLE

        @test isapprox(componentstates.stored_energy[t], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :ps, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sc, 1))[1], 0.0; atol = 1e-4)
        @test isapprox(OPF.build_sol_values(OPF.var(pm, :sd, 1))[1], 0.0; atol = 1e-4)
    end
end