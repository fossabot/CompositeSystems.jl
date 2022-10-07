"""
Given a JuMP model and a PowerModels network data structure,
Builds an DC-OPF or AC-OPF (+Min Load Curtailment) formulation of the given data and returns the JuMP model
"""

"Transportation"
function build_method!(pm::AbstractDCPowerModel, system::SystemModel, t::Int, type::Type{Transportation})
 
    var_gen_power(pm, system, t)
    var_branch_power(pm, system, t)
    var_load_curtailment(pm, system, t)
    #var_dcline_power(pm, system)

    # Add Constraints
    # ---------------
    for i in field(system, Buses, :keys)
        constraint_power_balance(pm, system, i, t)
    end

    for i in field(system, Branches, :keys)
        if field(system, Branches, :status)[i] ≠ 0
            constraint_thermal_limit_from(pm, system, i)
            constraint_thermal_limit_to(pm, system, i)
        end
    end

    # for i in field(system, DCLines, :keys)
    #     constraint_dcline_power_losses(pm, i)
    # end

    objective_min_load_curtailment(pm, system)
    return

end

"Load Minimization version of DCOPF"
function build_method!(pm::AbstractDCPowerModel, system::SystemModel, t::Int, type::Type{DCOPF})
    # Add Optimization and State Variables
    var_bus_voltage(pm, system, t)
    var_gen_power(pm, system, t)
    var_branch_power(pm, system, t)
    #variable_storage_power_mi(pm)
    #var_dcline_power(pm)
    var_load_curtailment(pm, system, t)

    # Add Constraints
    # ---------------
    for i in keys(field(system, Topology, :ref_buses))
        constraint_theta_ref(pm, i)
    end

    for i in field(system, Buses, :keys)
        constraint_power_balance(pm, system, i, t)
    end

    #for i in ids(pm, :storage, nw=n)
    #    constraint_storage_complementarity_mi(pm, i, nw=n)
    #    constraint_storage_losses(pm, i, nw=n)
    #    constraint_storage_thermal_limit(pm, i, nw=n)
    #end

    for i in field(system, Branches, :keys)
        if field(system, Branches, :status)[i] ≠ 0
            constraint_ohms_yt_from(pm, system, i)
            #constraint_ohms_yt_to(pm, system, i)
            constraint_voltage_angle_difference(pm, system, i)
            constraint_thermal_limit_from(pm, system, i)
            constraint_thermal_limit_to(pm, system, i)
        end
    end

    # for i in ids(pm, :dcline)
    #     constraint_dcline_power_losses(pm, i)
    # end
    objective_min_load_curtailment(pm, system)
    return

end

""
function objective_min_load_curtailment(pm::AbstractDCPowerModel, system::SystemModel)

    return JuMP.@objective(pm.model, Min,
        sum(field(system, Loads, :cost)[i]*pm.model[:plc][i] for i in field(system, Loads, :keys) if field(system, Loads, :status)[i] ≠ 0)
    )
end

# index representing which side the HVDC line is starting
#from_idx = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])
#lc = JuMP.@expression(pm.model, #sum(gen["cost"][1]*model[:pg][i]^2 + gen["cost"][2]*model[:pg][i] + gen["cost"][3] for (i,gen) in ref[:gen]) +
#sum(dcline["cost"][1]*model[:p_dc][from_idx[i]]^2 + dcline["cost"][2]*model[:p_dc][from_idx[i]] + dcline["cost"][3] for (i,dcline) in ref[:dcline]) +
#sum(ref[:load][i]["cost"]*model[:plc][i] for i in keys(ref[:load]))
#sum(pm.ref[:load][i]["cost"]*pm.model[:plc][i] for i in keys(pm.ref[:load])))
# Objective Function: minimize load curtailment

# ""
# function optimization!(pm::AbstractPowerModel, type::Type)
    
#     #JuMP.set_time_limit_sec(pm.model, 2.0)
#     JuMP.optimize!(pm.model)

#     # if JuMP.termination_status(pm.model) ≠ JuMP.LOCALLY_SOLVED && type == DCOPF
#     #     JuMP.set_time_limit_sec(pm.model, 2.0)
#     #     var_buspair_current_magnitude_sqr(pm)
#     #     var_bus_voltage_magnitude_sqr(pm)
#     #     for i in ids(pm, :branch)
#     #         constraint_voltage_magnitude_diff(pm, i)
#     #     end
#     #     JuMP.optimize!(pm.model)
#     # end
    
#     return

# end