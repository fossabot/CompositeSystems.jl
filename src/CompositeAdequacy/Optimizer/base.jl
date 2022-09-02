macro def(name, definition)
    return quote
        macro $(esc(name))()
            esc($(Expr(:quote, definition)))
        end
    end
end

"a macro for adding the standard InfrastructureModels fields to a type definition"
CompositeAdequacy.@def pm_fields begin
    model::Model
    data_load::Dict{String,<:Any}
    solution::Dict{String,<:Any}
    ref::Dict{Symbol,<:Any}
end

"Types of optimization"
abstract type AbstractPowerModel end
abstract type AbstractACPModel <: AbstractPowerModel end
abstract type AbstractDCPModel <: AbstractPowerModel end

mutable struct DCMLPowerModel <: AbstractDCPModel @pm_fields end
mutable struct DCPPowerModel <: AbstractDCPModel @pm_fields end
mutable struct ACMLPowerModel <: AbstractACPModel @pm_fields end
mutable struct ACPPowerModel <: AbstractACPModel @pm_fields end

function InitializeAbstractPowerModel(data::Dict{String, <:Any}, PowerModel::Type{DCPPowerModel}, optimizer)

    #@assert PowerModel <: AbstractDCPModel || PowerModel <: AbstractACPModel
    ref = ref_initialize!(data)
    pm = PowerModel(
        JuMP.direct_model(optimizer[1]),
        data["load"],
        Dict{String,Any}(), # empty solution data
        ref
    )

    return pm
end

function InitializeAbstractPowerModel(data::Dict{String, <:Any}, PowerModel::Type{DCMLPowerModel}, optimizer)

    #@assert PowerModel <: AbstractDCPModel || PowerModel <: AbstractACPModel
    ref = ref_initialize!(data)
    pm = PowerModel(
        JuMP.direct_model(optimizer[2]),
        #JuMP.Model(optimizer[2]),
        data["load"],
        Dict{String,Any}(), # empty solution data
        ref
    )

    return pm
end