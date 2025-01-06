using JuMP
using Gurobi

#
function k_capped(ξ::AbstractVector{Float64}, k::Float64=1.0, m::JuMP.GenericModel{Core.Float64}=Model(Gurobi.Optimizer))
  n = length(ξ)
  set_optimizer_attribute(m, "OutputFlag", 0)
  @variable(m, 0 ≤ x[1:n] ≤ 1)
  @constraint(m, sum(x) ≤ k)
  @objective(m, Min, x' * x - 2ξ' * x) # L2 norm squared
  optimize!(m)
  return value.(x)
end

# Example
ξ = [0.1, 0.2, 0.3, 0.2, 0.2]
k = 1.0
@show ξ
kcap = k_capped(ξ, k)
@show kcap
@show sum(kcap)
