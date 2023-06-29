struct ELCC{M} <: CapacityValuationMethod{M}

    capacity_max::Float64
    capacity_gap::Float64
    p_value::Float64
    loads::Vector{Tuple{Int,Float64}}
    verbose::Bool

    function ELCC{M}(
        capacity_max::Float64, loads::Vector{Pair{Int,Float64}};
        capacity_gap::Float64=5.0, p_value::Float64=0.05, verbose::Bool=false) where M

        @assert capacity_max > 0
        @assert capacity_gap > 0
        @assert 0 < p_value < 1
        @assert sum(x.second for x in loads) ≈ 1.0

        return new{M}(capacity_max, capacity_gap, p_value, Tuple.(loads), verbose)
    end
end

function ELCC{M}(capacity_max::Float64, loads::Float64; kwargs...) where M
    return ELCC{M}(capacity_max, [loads=>1.0]; kwargs...)
end

""
function assess(sys_baseline::S, sys_augmented::S, params::ELCC{M}, settings::Settings, simulationspec::SimulationSpec
    ) where {N, L, T, S <: SystemModel{N,L,T}, M <: ReliabilityMetric}

    P = BaseModule.powerunits["MW"]

    loadskeys = sys_baseline.loads.keys
    loadskeys ≠ sys_augmented.loads.keys && error("Systems provided do not have matching loads")

    shortfall = first(assess(sys_baseline, simulationspec, settings, Shortfall()))
    target_metric = M(shortfall)
    eens_metric = EENS(shortfall)

    capacities = Int[]
    target_metrics = typeof(target_metric)[]
    eens_metrics = EENS[]

    elcc_loads, base_load, sys_variable = copy_load(sys_augmented, params.loads)

    lower_bound = 0
    shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
    lower_bound_metric = M(shortfall)
    eens_lower_bound_metric = EENS(shortfall)
    push!(capacities, lower_bound)
    push!(target_metrics, lower_bound_metric)
    push!(eens_metrics, eens_lower_bound_metric)

    upper_bound = params.capacity_max
    update_load!(sys_variable, elcc_loads, base_load, upper_bound, sys_baseline.baseMVA)
    shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
    upper_bound_metric = M(shortfall)
    eens_upper_bound_metric = EENS(shortfall)
    push!(capacities, upper_bound)
    push!(target_metrics, upper_bound_metric)
    push!(eens_metrics, eens_upper_bound_metric)

    while true

        params.verbose && println(
            "\n$(lower_bound) $P\t< ELCC <\t$(upper_bound) $P\n",
            "$(lower_bound_metric)\t< $(target_metric) <\t$(upper_bound_metric)")

        midpoint = div(lower_bound + upper_bound, 2)
        capacity_gap = upper_bound - lower_bound

        # Stopping conditions
        stop = stopping_conditions(params, capacity_gap, lower_bound_metric, upper_bound_metric)
        stop && break

        # Evaluate metric at midpoint
        update_load!(sys_variable, elcc_loads, base_load, midpoint, sys_baseline.baseMVA)
        shortfall = first(assess(sys_variable, simulationspec, settings, Shortfall()))
        midpoint_metric = M(shortfall)
        eens_midpoint_metric = EENS(shortfall)
        push!(capacities, midpoint)
        push!(target_metrics, midpoint_metric)
        push!(eens_metrics, eens_midpoint_metric)

        # Tighten capacity bounds
        if val(midpoint_metric) < val(target_metric)
            lower_bound = midpoint
            lower_bound_metric = midpoint_metric
        else # midpoint_metric <= target_metric
            upper_bound = midpoint
            upper_bound_metric = midpoint_metric
        end
    end

    return CapacityCreditResult{typeof(params), typeof(target_metric), P}(
        target_metric, eens_metric, Float64(lower_bound), 
        Float64(upper_bound), Float64.(capacities), target_metrics, eens_metrics)
end

"Apply stopping conditions"
function stopping_conditions(
    params::ELCC{M}, capacity_gap::Float64, lower_bound_metric::M, upper_bound_metric::M
    ) where {M <: ReliabilityMetric}

    P = BaseModule.powerunits["MW"]
    stopping_conditions = false

    ## Return the bounds if they are within solution tolerance of each other
    if capacity_gap <= params.capacity_gap
        params.verbose && @info "Capacity bound gap within tolerance, stopping bisection."
        stopping_conditions = true
    end

    # If the null hypothesis upper_bound_metric !>= lower_bound_metric
    # cannot be rejected, terminate and return the loose bounds
    pval = pvalue(lower_bound_metric, upper_bound_metric)
    if pval >= params.p_value
        @warn "Gap between upper and lower bound risk metrics is not " *
            "statistically significant (p_value=$pval), stopping bisection. " *
            "The gap between capacity bounds is $(capacity_gap) $P, " *
            "while the target stopping gap was $(params.capacity_gap) $P."
        stopping_conditions = true
    end

    return stopping_conditions
end

""
function copy_load(sys::SystemModel{N,L,T}, load_shares::Vector{Tuple{Int,Float64}}) where {N,L,T}

    load_allocations = allocate_loads(sys.loads.keys, load_shares)

    new_loads = Loads{N,L,T}(
        sys.loads.keys, sys.loads.buses, copy(sys.loads.pd), sys.loads.qd, 
        sys.loads.pf, sys.loads.cost, sys.loads.status)

    return load_allocations, sys.loads.pd, SystemModel(
        new_loads, sys.generators, sys.storages, sys.buses,
        sys.branches, sys.commonbranches, sys.shunts, sys.ref_buses,
        sys.arcs_from, sys.arcs_to, sys.arcs, sys.buspairs, sys.baseMVA, sys.timestamps)
end

""
function update_load!(
    sys::SystemModel, load_shares::Vector{Tuple{Int,Float64}}, 
    load_base::Matrix{Float32}, load_increase::Float64, baseMVA::Float64)

    for (r, share) in load_shares
        sys.loads.pd[r, :] .= load_base[r, :] .+ share*load_increase/baseMVA
    end
end

""
function allocate_loads(load_keys::Vector{Int}, load_shares::Vector{Tuple{Int,Float64}})

    load_allocations = similar(load_shares, Tuple{Int,Float64})

    for (i, (name, share)) in enumerate(load_shares)
        r = findfirst(isequal(name), load_keys)
        isnothing(r) && error("$name is not a region name in the provided systems")
        load_allocations[i] = (r, share)
    end
    return sort!(load_allocations)
end

""
function pvalue(lower::T, upper::T) where {T<:ReliabilityMetric}

    vl = val(lower)
    sl = stderror(lower)

    vu = val(upper)
    su = stderror(upper)

    if iszero(sl) && iszero(su)
        result = Float64(vl ≈ vu)
    else
        # single-sided z-test with null hypothesis that (vu - vl) not > 0
        z = (vu - vl) / sqrt(su^2 + sl^2)
        result = ccdf(Normal(), z)
    end
    return result
end