#***************************************************** VARIABLES *************************************************************************
""
function update_var_bus_voltage_angle(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    
    va = var(pm, :va, nw)[i]
    if !topology(pm, :buses_available)[i]
        JuMP.set_upper_bound(va, 0)
        JuMP.set_lower_bound(va, 0)
    else
        if JuMP.has_upper_bound(va) && JuMP.has_lower_bound(va) 
            JuMP.delete_upper_bound(va)
            JuMP.delete_lower_bound(va)
        end
    end
end

""
function update_var_gen_power_real(
    pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1, force_pmin=false)

    gen_max = field(system, :generators, :pmax)[i] * topology(pm, :generators_available)[i]
    JuMP.set_upper_bound(var(pm, :pg, nw)[i], gen_max)

    if force_pmin
        gen_min = field(system, :generators, :pmin)[i] * topology(pm, :generators_available)[i]
        JuMP.set_lower_bound(var(pm, :pg, nw)[i], gen_min)
    end
end

""
function update_var_gen_power_imaginary(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    gen_qmax = field(system, :generators, :qmax)[i] * topology(pm, :generators_available)[i]
    JuMP.set_upper_bound(var(pm, :qg, nw)[i], gen_qmax)
    gen_qmin = field(system, :generators, :qmin)[i] * topology(pm, :generators_available)[i]
    JuMP.set_lower_bound(var(pm, :qg, nw)[i], gen_qmin)
end

"Defines load power factor variables to represent curtailed load in objective function"
function update_var_load_power_factor(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    load_avail = topology(pm, :loads_available)[i]
    JuMP.set_upper_bound(var(pm, :z_demand, nw)[i], load_avail)
end

#***************************************************** STORAGE VAR UPDATES *************************************************************************

""
function update_con_storage_state(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    stored_energy = topology(pm, :stored_energy)[i] * topology(pm, :storages_available)[i]
    JuMP.set_normalized_rhs(con(pm, :storage_state, nw)[i], stored_energy)
end

""
function update_var_storage_charge(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    charge_rating = field(system, :storages, :charge_rating)[i] * topology(pm, :storages_available)[i]
    JuMP.set_upper_bound(var(pm, :sc, nw)[i], charge_rating)
end

""
function update_var_storage_discharge(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    discharge_rating = field(system, :storages, :discharge_rating)[i] * topology(pm, :storages_available)[i]
    JuMP.set_upper_bound(var(pm, :sd, nw)[i], discharge_rating)
end

#***************************************************UPDATES CONSTRAINTS ****************************************************************

"Branch - Ohm's Law Constraints"
function update_con_ohms_yt(pm::AbstractPowerModel, system::SystemModel, i::Int; nw::Int=1)
    
    f_bus = field(system, :branches, :f_bus)[i]
    t_bus = field(system, :branches, :t_bus)[i]
    g, b = calc_branch_y(system.branches, i)
    tr, ti = calc_branch_t(system.branches, i)
    tm = field(system, :branches, :tap)[i]
    va_fr  = var(pm, :va, nw)[f_bus]
    va_to  = var(pm, :va, nw)[t_bus]
    g_fr = field(system, :branches, :g_fr)[i]
    b_fr = field(system, :branches, :b_fr)[i]
    g_to = field(system, :branches, :g_to)[i]
    b_to = field(system, :branches, :b_to)[i]

    _update_con_ohms_yt_from(
        pm, i, nw, f_bus, t_bus, g, b, g_fr, b_fr, tr, ti, tm, va_fr, va_to)

    _update_con_ohms_yt_to(
        pm, i, nw, f_bus, t_bus, g, b, g_to, b_to, tr, ti, tm, va_fr, va_to)
end

""
function update_con_thermal_limits(pm::AbstractPowerModel, system::SystemModel, l::Int; nw::Int=1)
    thermal_limit = topology(pm, :branches_available)[l] * field(system, :branches, :rate_a)[l]^2
    JuMP.set_normalized_rhs(con(pm, :thermal_limit_from, nw)[l], thermal_limit)
    JuMP.set_normalized_rhs(con(pm, :thermal_limit_to, nw)[l], thermal_limit)
end

"Branch - Phase Angle Difference Constraints "
function update_con_voltage_angle_difference(pm::AbstractPolarModels, system::SystemModel, l::Int; nw::Int=1)
    
    if !topology(pm, :branches_available)[l]
        vad_min = topology(pm, :delta_bounds)[1]
        vad_max = topology(pm, :delta_bounds)[2]
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, nw)[l], vad_max)
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, nw)[l], vad_min)
    else
        angmin = field(system, :branches, :angmin)[l]
        angmax = field(system, :branches, :angmax)[l]
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_upper, nw)[l], angmax)
        JuMP.set_normalized_rhs(con(pm, :voltage_angle_diff_lower, nw)[l], angmin)
    end
end