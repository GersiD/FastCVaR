using JuMP, HiGHS, Gurobi

function worstcase_l1_gurobi(x, pbar, ξ)
  m = Model(Gurobi.Optimizer)
  set_optimizer_attribute(m, "log_to_console", false)
  @variable(m, p[1:length(x)] .>= 0)
  @variable(m, t[1:length(x)])
  @constraint(m, p .- pbar <= t)
  @constraint(m, pbar .- p <= t)
  @constraint(m, sum(t) <= ξ)
  @constraint(m, sum(p) == 1)
  @objective(m, Min, p' * x)
  optimize!(m)
  termination_status(m) != MOI.OPTIMAL && throw(error("worstcase_l1_gurobi expected optimal got $(termination_status(m))"))
  return value.(p), value.(p)' * x
end
function worstcase_l1_weighted_gurobi(x, pbar, ξ, w)
  m = Model(HiGHS.Optimizer)
  set_optimizer_attribute(m, "log_to_console", false)
  @variable(m, p[1:length(x)])
  @variable(m, t[1:length(x)])
  @constraint(m, p .- pbar <= t)
  @constraint(m, pbar .- p <= t)
  @constraint(m, w' * t <= ξ)
  @constraint(m, sum(p) == 1)
  @constraint(m, p .>= 0)
  @objective(m, Min, p' * x)
  optimize!(m)
  termination_status(m) != MOI.OPTIMAL && Error("Gurobi failed to find optimal solution")
  return value.(p), value.(p)' * x
end
