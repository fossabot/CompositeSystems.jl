"Topology"
struct Topology

    buses_idxs::Vector{UnitRange{Int}}
    loads_idxs::Vector{UnitRange{Int}}
    branches_idxs::Vector{UnitRange{Int}}
    shunts_idxs::Vector{UnitRange{Int}}
    generators_idxs::Vector{UnitRange{Int}}
    storages_idxs::Vector{UnitRange{Int}}
    generatorstorages_idxs::Vector{UnitRange{Int}}

    loads_nodes::Dict{Int, Vector{Int}}
    shunts_nodes::Dict{Int, Vector{Int}}
    generators_nodes::Dict{Int, Vector{Int}}
    storages_nodes::Dict{Int, Vector{Int}}
    generatorstorages_nodes::Dict{Int, Vector{Int}}

    arcs_from::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs_to::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    arcs::Vector{Union{Missing, Tuple{Int, Int, Int}}}
    busarcs::Dict{Int, Vector{Tuple{Int, Int, Int}}}
    buspairs::Dict{Tuple{Int, Int}, Union{Missing, Vector{Float32}}}

    function Topology(system::SystemModel{N}) where {N}

        key_buses = filter(i->field(system, :buses, :bus_type)[i]≠ 4, field(system, :buses, :keys))
        buses_idxs = makeidxlist(key_buses, length(system.buses))

        key_loads = filter(i->field(system, :loads, :status)[i], field(system, :loads, :keys))
        loads_idxs = makeidxlist(key_loads, length(system.loads))
        loads_nodes = Dict((i, Int[]) for i in key_buses)
        bus_asset!(loads_nodes, key_loads, field(system, :loads, :buses))

        key_shunts = filter(i->field(system, :shunts, :status)[i], field(system, :shunts, :keys))
        shunts_idxs = makeidxlist(key_shunts, length(system.shunts))
        shunts_nodes = Dict((i, Int[]) for i in key_buses)
        bus_asset!(shunts_nodes, key_shunts, field(system, :shunts, :buses))

        key_generators = filter(i->field(system, :generators, :status)[i], field(system, :generators, :keys))
        generators_idxs = makeidxlist(key_generators, length(system.generators))
        generators_nodes = Dict((i, Int[]) for i in key_buses)
        bus_asset!(generators_nodes, key_generators, field(system, :generators, :buses))

        key_storages = filter(i->field(system, :storages, :status)[i], field(system, :storages, :keys))
        storages_idxs = makeidxlist(key_storages, length(system.storages))
        storages_nodes = Dict((i, Int[]) for i in key_buses)
        bus_asset!(storages_nodes, key_storages, field(system, :storages, :buses))

        key_generatorstorages = filter(i->field(system, :generatorstorages, :status)[i], field(system, :generatorstorages, :keys))
        generatorstorages_idxs = makeidxlist(key_generatorstorages, length(system.generatorstorages))
        generatorstorages_nodes = Dict((i, Int[]) for i in key_buses)
        bus_asset!(generatorstorages_nodes, key_generatorstorages, field(system, :generatorstorages, :buses))

        key_branches = filter(i->field(system, :branches, :status)[i], field(system, :branches, :keys))
        branches_idxs = makeidxlist(key_branches, length(system.branches))

        arcs_from = deepcopy(system.arcs_from)
        arcs_to = deepcopy(system.arcs_to)
        arcs = [arcs_from; arcs_to]
        buspairs = deepcopy(system.buspairs)

        busarcs = Dict((i, Tuple{Int, Int, Int}[]) for i in eachindex(key_buses))
        bus_asset!(busarcs, arcs)

        return new(
            buses_idxs::Vector{UnitRange{Int}}, loads_idxs::Vector{UnitRange{Int}}, 
            branches_idxs::Vector{UnitRange{Int}}, shunts_idxs::Vector{UnitRange{Int}}, 
            generators_idxs::Vector{UnitRange{Int}}, storages_idxs::Vector{UnitRange{Int}}, 
            generatorstorages_idxs::Vector{UnitRange{Int}}, 
            loads_nodes, shunts_nodes, generators_nodes, storages_nodes, generatorstorages_nodes, 
            arcs_from, arcs_to, arcs, busarcs, buspairs)
    end

end

Base.:(==)(x::T, y::T) where {T <: Topology} =
    x.buses_idxs == y.buses_idxs &&
    x.loads_idxs == y.loads_idxs &&
    x.shunts_idxs == y.shunts_idxs &&
    x.generators_idxs == y.generators_idxs &&
    x.storages_idxs == y.storages_idxs &&
    x.generatorstorages_idxs == y.generatorstorages_idxs &&
    x.loads_nodes == y.loads_nodes &&
    x.shunts_nodes == y.shunts_nodes &&
    x.generators_nodes == y.generators_nodes &&
    x.storages_nodes == y.storages_nodes &&
    x.generatorstorages_nodes == y.generatorstorages_nodes &&
    x.busarcs == y.busarcs &&
    x.arcs_from == y.arcs_from &&
    x.arcs_to == y.arcs_to &&
    x.arcs == y.arcs &&
    x.buspairs == y.buspairs

"a macro for adding the base AbstractPowerModels fields to a type definition"
OPF.@def pm_fields begin
    model::AbstractModel
    topology::Topology
    var::Dict{Symbol, AbstractArray}
    con::Dict{Symbol, AbstractArray}
end

"root of the power formulation type hierarchy"
abstract type AbstractPowerModel end

"Types of optimization"
abstract type AbstractDCPowerModel <: AbstractPowerModel end

abstract type AbstractDCPModel <: AbstractDCPowerModel end
struct DCPPowerModel <: AbstractDCPModel @pm_fields end

abstract type AbstractDCMPPModel <: AbstractDCPModel end
struct DCMPPowerModel <: AbstractDCMPPModel @pm_fields end

abstract type AbstractDCPLLModel <: AbstractDCPModel end
struct DCPLLPowerModel <: AbstractDCPLLModel @pm_fields end

abstract type AbstractNFAModel <: AbstractDCPModel end
struct NFAPowerModel <: AbstractNFAModel @pm_fields end

abstract type AbstractLPACModel <: AbstractPowerModel end
struct LPACCPowerModel <: AbstractLPACModel @pm_fields end

abstract type PM_AbstractDCPModel <: AbstractDCPowerModel end
struct PM_DCPPowerModel <: PM_AbstractDCPModel @pm_fields end

AbstractAPLossLessModels = Union{DCPPowerModel, DCMPPowerModel, AbstractNFAModel}
AbstractPolarModels = Union{AbstractLPACModel, AbstractDCPowerModel}

""
struct Settings

    optimizer::MOI.OptimizerWithAttributes
    modelmode::JuMP.ModelMode
    powermodel::Type

    function Settings(
        optimizer::MOI.OptimizerWithAttributes;
        modelmode::JuMP.ModelMode = JuMP.AUTOMATIC,
        powermodel::Type=OPF.DCPPowerModel
        )
        new(optimizer, modelmode, powermodel)
    end

end

""
function jump_model(modelmode::JuMP.ModelMode, optimizer; string_names = false)

    if modelmode == JuMP.AUTOMATIC
        jump_model = Model(optimizer; add_bridges = false)
    elseif modelmode == JuMP.DIRECT
        @error("Mode not supported")
        jump_model = direct_model(optimizer)
    else
        @warn("Manual Mode not supported")
    end

    if string_names == false
        JuMP.set_string_names_on_creation(jump_model, false)
    end

    JuMP.set_silent(jump_model)

    return jump_model
    
end


"Constructor for an AbstractPowerModel modeling object"
function abstract_model(method::Type{M}, topology::Topology, model::JuMP.Model) where {M<:AbstractPowerModel}

    var = Dict{Symbol, AbstractArray}()
    con = Dict{Symbol, AbstractArray}()
    return M(model, topology, var, con)

end

""
function initialize_pm_containers!(pm::AbstractDCPowerModel, system::SystemModel; timeseries=false)

    if timeseries == true
        @error("Timeseries containers not supported")
        #add_var_container!(pm.var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    else
        add_var_container!(pm.var, :pg, field(system, :generators, :keys))
        add_var_container!(pm.var, :va, field(system, :buses, :keys))
        add_var_container!(pm.var, :plc, field(system, :loads, :keys))
        add_var_container!(pm.var, :c_plc, field(system, :loads, :keys))
        add_var_container!(pm.var, :p, field(pm.topology, :arcs))

        add_con_container!(pm.con, :power_balance_p, field(system, :buses, :keys))
        add_con_container!(pm.con, :ohms_yt_from_p, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_to_p, field(system, :branches, :keys))
        add_con_container!(pm.con, :voltage_angle_diff_upper, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :voltage_angle_diff_lower, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :model_voltage, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :thermal_limit_from, field(system, :branches, :keys))
        add_con_container!(pm.con, :thermal_limit_to, field(system, :branches, :keys))

        add_var_container!(pm.var, :ps, field(system, :storages, :keys))
        add_var_container!(pm.var, :se, field(system, :storages, :keys))
        add_var_container!(pm.var, :sc, field(system, :storages, :keys))
        add_var_container!(pm.var, :sd, field(system, :storages, :keys))
        add_var_container!(pm.var, :sc_on, field(system, :storages, :keys))
        add_var_container!(pm.var, :sd_on, field(system, :storages, :keys))

        add_con_container!(pm.con, :storage_state, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_1, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_2, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_3, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    end

    return

end

""
function initialize_pm_containers!(pm::AbstractLPACModel, system::SystemModel; timeseries=false)

    if timeseries == true
        @error("Timeseries containers not supported")
        #add_var_container!(pm.var, :pg, field(system, :generators, :keys), timesteps = 1:N)
    else
        add_var_container!(pm.var, :pg, field(system, :generators, :keys))
        add_var_container!(pm.var, :qg, field(system, :generators, :keys))
        add_var_container!(pm.var, :va, field(system, :buses, :keys))
        add_var_container!(pm.var, :phi, field(system, :buses, :keys))
        add_var_container!(pm.var, :cs, field(pm.topology, :buspairs))
        add_var_container!(pm.var, :plc, field(system, :loads, :keys))
        add_var_container!(pm.var, :qlc, field(system, :loads, :keys))
        add_var_container!(pm.var, :c_plc, field(system, :loads, :keys))
        add_var_container!(pm.var, :c_qlc, field(system, :loads, :keys))
        add_var_container!(pm.var, :z_demand, field(system, :loads, :keys))
        add_var_container!(pm.var, :p, field(pm.topology, :arcs))
        add_var_container!(pm.var, :q, field(pm.topology, :arcs))

        add_con_container!(pm.con, :power_factor, field(system, :loads, :keys))
        add_con_container!(pm.con, :c_power_factor, field(system, :loads, :keys))
        add_con_container!(pm.con, :power_balance_p, field(system, :buses, :keys))
        add_con_container!(pm.con, :power_balance_q, field(system, :buses, :keys))
        add_con_container!(pm.con, :ohms_yt_from_p, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_to_p, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_from_q, field(system, :branches, :keys))
        add_con_container!(pm.con, :ohms_yt_to_q, field(system, :branches, :keys))
        add_con_container!(pm.con, :voltage_angle_diff_upper, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :voltage_angle_diff_lower, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :model_voltage, keys(field(system, :buspairs)))
        add_con_container!(pm.con, :thermal_limit_from, field(system, :branches, :keys))
        add_con_container!(pm.con, :thermal_limit_to, field(system, :branches, :keys))

        add_var_container!(pm.var, :ps, field(system, :storages, :keys))
        add_var_container!(pm.var, :qs, field(system, :storages, :keys))
        add_var_container!(pm.var, :qsc, field(system, :storages, :keys))
        add_var_container!(pm.var, :se, field(system, :storages, :keys))
        add_var_container!(pm.var, :sc, field(system, :storages, :keys))
        add_var_container!(pm.var, :sd, field(system, :storages, :keys))
        add_var_container!(pm.var, :sc_on, field(system, :storages, :keys))
        add_var_container!(pm.var, :sd_on, field(system, :storages, :keys))

        add_con_container!(pm.con, :storage_state, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_1, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_2, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_complementarity_mi_3, field(system, :storages, :keys))
        add_con_container!(pm.con, :storage_losses, field(system, :storages, :keys))
    end

    return

end

""
function empty_model!(pm::AbstractDCPowerModel)
    JuMP.empty!(pm.model)
    MOIU.reset_optimizer(pm.model)
    return
end

""
function reset_model!(pm::AbstractPowerModel, states::SystemStates, settings::Settings, s)

    if iszero(s%10) && settings.optimizer == Ipopt
        JuMP.set_optimizer(pm.model, deepcopy(settings.optimizer); add_bridges = false)
    elseif iszero(s%30) && settings.optimizer == Gurobi
        JuMP.set_optimizer(pm.model, deepcopy(settings.optimizer); add_bridges = false)
    else
        MOIU.reset_optimizer(pm.model)
    end

    fill!(field(states, :plc), 0.0)
    fill!(field(states, :qlc), 0.0)
    fill!(field(states, :se), 0.0)
    return

end

""
function update_topology!(pm::AbstractPowerModel, system::SystemModel, states::SystemStates, t::Int)

    update_idxs!(filter(i->states.branches[i,t], field(system, :branches, :keys)), topology(pm, :branches_idxs))
    update_idxs!(filter(i->states.buses[i,t] ≠ 4, field(system, :buses, :keys)), topology(pm, :buses_idxs))

    update_idxs!(
        filter(i->states.generators[i,t], field(system, :generators, :keys)), 
        topology(pm, :generators_idxs), topology(pm, :generators_nodes), field(system, :generators, :buses)
    )
    
    update_idxs!(
        filter(i->states.shunts[i,t], field(system, :shunts, :keys)),
        topology(pm, :shunts_idxs), topology(pm, :shunts_nodes), field(system, :shunts, :buses)
    )
    
    if all(view(field(states, :branches),:,t)) == false 
        simplify!(pm, system, states, t)
    end

    update_arcs!(pm, system, states.branches, t)
    
    return

end