# Database URLs
if isempty(ARGS)
    @warn "!!! No database urls provided as command line arguments, proceeding with default urls !!!"
    db_url_building = "sqlite:///C:\\DATA\\Spine\\toolbox\\projects\\spinea4testing\\building_data\\Building_Data.sqlite"
    db_url_combined ="sqlite:///C:\\DATA\\Spine\\toolbox\\projects\\spinea4testing\\combined_data_1\\Combined_Data.sqlite"
else
    if length(ARGS) != 2
        error("!!! Provide only database urls both for the baseline consumption database as well as the target database !!!")
    else
        db_url_building = ARGS[1]
        db_url_combined = ARGS[2]
    end
end

# Load necessary modules
using SpineInterface
using Dates

# Open building database
println("... Loading building model results ...")
using_spinedb(db_url_building)
println("... Done ...")

# Determine relevant indeces
r = first(SpineInterface.report())
dummy_names = [Symbol(75, "FI_Dummy"), Symbol(74, "FI_Dummy")]
units = filter(x->x.name in dummy_names, SpineInterface.unit())
und = filter(x->x.unit in units, SpineInterface.unit__node__direction())
nodes = unique(map(x->x.node, und))
uncd = []
for (u,n,d) in und
    c = first(filter(x->x.node==n, SpineInterface.node__commodity())).commodity
    append!(uncd, [(unit=u, node=n, commodity=c, direction=d)])
end

# Extract the baseline electricity consumption
baseline_electricity_demand = Dict()
for (u,n,c,d) in uncd
    baseline_electricity_demand[(node=n,)] = SpineInterface.flow(report=r, unit=u, node=n, commodity=c, direction=d)
end

# Open combined database
println("... Loading combined database ...")
using_spinedb(db_url_combined)
println("... Done ...")

# Repeat baseline electricity consumption until it's length matches power system data
println("... Repeating baseline electricity consumption to match power system data ...")
for n in nodes
    ind = baseline_electricity_demand[(node=n,)].indexes
    val = baseline_electricity_demand[(node=n,)].values
    ign = baseline_electricity_demand[(node=n,)].ignore_year
    rep = baseline_electricity_demand[(node=n,)].repeat
    while length(ind) < length(SpineInterface.demand(node=n).indexes)
        append!(ind, ind + Hour(length(ind)))
        append!(val, val)
    end
    # Cut out any unnecessary tail
    new_ind = filter(x->x in SpineInterface.demand(node=n).indexes, ind)
    new_val_indexes = findall(x->x in new_ind, ind)
    new_val = val[new_val_indexes]
    # Create the new extended TimeSeries
    baseline_electricity_demand[(node=n,)] = TimeSeries(
        new_ind,
        new_val,
        ign,
        rep
    )
end
println("... Done ...")

# Calculate the new electricity demand
println("... Calculating new electricity demand ...")
new_electricity_demand = Dict{NamedTuple,TimeSeries}()
for (u,n,c,d) in uncd
    ind = SpineInterface.demand(node=n).indexes
    if ind != baseline_electricity_demand[(node=n,)].indexes
        println("Indexes don't match!")
        break
    end
    val = SpineInterface.demand(node=n).values - baseline_electricity_demand[(node=n,)].values
    new_electricity_demand[(node=n,)] = TimeSeries(
        ind, 
        val, 
        SpineInterface.demand(node=n).ignore_year, 
        SpineInterface.demand(node=n).repeat
        )
end
println("... Done ...")

# Overwrite the old demand in the combined database with the new demand
pars = Dict(Symbol("demand") => new_electricity_demand)
println("... Rewriting demand ...")
write_parameters(pars, db_url_combined)
println("... Done ...")