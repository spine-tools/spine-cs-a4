# Load modules
using JuMP
using SpineModel
using Cbc

# Custon constraints required for case study A4
function add_constraints(m::Model)

    # Cyclic storage bounds on the first solve
    @fetch stor_state = m.ext[:variables]
    cons = m.ext[:constraints][:stor_cyclic] = Dict()
    filtered_storage__commodity = filter(stor_c -> stor_c.storage in SpineModel.indices(cyclic), storage__commodity())
    stor_start = [first(stor_state_indices(storage=stor, commodity=c)) for (stor, c) in filtered_storage__commodity]
    stor_end = [last(stor_state_indices(storage=stor, commodity=c)) for (stor, c) in filtered_storage__commodity]
    for (stor, c, t_first) in stor_start
        for (stor, c, t_last) in stor_end
            (stor, c, t_first, t_last) in keys(cons) && continue
            cons[stor, c, t_first, t_last] = @constraint(
                m,
                stor_state[stor, c, t_first]
                ==
                stor_state[stor, c, t_last]
            )
        end
    end

    # THIS ISN'T NECESSARY FOR THE BUILDING MODEL!
    # Input-output conversion with online consumption
    @fetch flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:conversion] = Dict()
    for (u, c1, c2) in SpineModel.indices(idle_heat_rate)
        for t in SpineModel.t_lowest_resolution(map(x -> x.t, flow_indices(unit=u, commodity=[c1, c2])))
            cons[u, c1, c2, t] = @constraint(
                m,
                + reduce(
                    +,
                    flow[u_, n, c1_, d, t_] * SpineModel.duration(t_)
                    for (u_, n, c1_, d, t_) in flow_indices(
                        unit=u, commodity=c1, direction=direction(:from_node), t=t_in_t(t_long=t)
                    );
                    init=0
                )
                ==
                + variable_heat_rate(unit=u, commodity1=c1, commodity2=c2, t=t)
                * reduce(
                    +,
                    flow[u_, n, c2_, d, t_] * SpineModel.duration(t_)
                    for (u_, n, c2_, d, t_) in flow_indices(
                        unit=u, commodity=c2, direction=direction(:to_node), t=t_in_t(t_long=t)
                    );
                    init=0
                )
                + idle_heat_rate(unit=u, commodity1=c1, commodity2=c2, t=t)
                #* unit_capacity(unit=u, commodity=c2, direction=direction(:to_node))
                * reduce(
                    +,
                    units_on[u_, t_] * SpineModel.duration(t_)
                    for (u_, t_) in units_on_indices(unit=u, t=t_in_t(t_long=t));
                    init=0
                )
            )
        end
    end

end

function update_constraints(m::Model)

    # Remove cyclic storage bounds from subsequent solves
    cons = pop!(m.ext[:constraints], :stor_cyclic, nothing)
    cons === nothing && return
    delete.(m, values(cons))

    # Update input-output convetrsion equation
    @fetch flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:conversion]
    for (u, c1, c2) in SpineModel.indices(idle_heat_rate)
        for t in SpineModel.t_lowest_resolution(map(x -> x.t, flow_indices(unit=u, commodity=[c1, c2])))
            # Update idle heat rates
            set_normalized_coefficient(
                cons[u, c1, c2, t],
                units_on[u,t],
                (
                    - idle_heat_rate(unit=u, commodity1=c1, commodity2=c2, t=t)
                    #* unit_capacity(unit=u, commodity=c2, direction=direction(:to_node))
                    * SpineModel.duration(t)
                )
            )
            # Update variable heat rates
            for (u_, n, c2_, d, t_) in flow_indices(unit=u, commodity=c2, direction=direction(:to_node), t=t_in_t(t_long=t))
                set_normalized_coefficient(
                    cons[u_, c1, c2_, t_],
                    flow[u_, n, c2_, d, t_],
                    - variable_heat_rate(unit=u_, commodity1=c1, commodity2=c2_, t=t) * SpineModel.duration(t_)
                )
            end
        end
    end

end

# Catch an error if no db_url is provided
try
    ARGS[1]
catch e
    if isa(e, BoundsError)
        println("!!! Database url required as a command line argument !!!")
    end
end

# Run the model from the chosen database
m = run_spinemodel(
    ARGS[1]; 
    with_optimizer=optimizer_with_attributes(Cbc.Optimizer, "logLevel"=>1, "allowableGap"=>0, "ratioGap"=>0),
    add_constraints=m->add_constraints(m),
    update_constraints=m->update_constraints(m),
)