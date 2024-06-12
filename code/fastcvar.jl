using Revise
using RiskMeasures
using Gurobi
using JuMP

# values = [1, 2, 3, 4, 5]
# pmf = [0.1, 0.2, 0.3, 0.2, 0.2]
# @assert pmf |> sum ≈ 1

# Takes vlaues, pmf, and then alpha
# @show CVaR_e(values, pmf, 0.5)
function gurobi_cvar(x::AbstractVector{Float64}, p::AbstractVector{Float32}, α::Float64)
  n::Integer = length(x)
  @assert n == length(p)
  m::JuMP.GenericModel{Core.Float64} = Model(Gurobi.Optimizer)
  set_optimizer_attribute(m, "OutputFlag", 0)
  @variable(m, ξ[1:n] >= 0)
  @constraint(m, sum(ξ) == 1)
  @constraint(m, ξ .<= 1 / (1 - α) * p)
  @objective(m, Min, ξ' * p)
  optimize!(m)
  return objective_value(m)
end

## Quick quantile
function qq(vals::AbstractVector{Float64}, p::AbstractVector{Float32}, α::Float64)
  n::Int64 = length(vals)
  @assert n == length(p)
  n == 1 && return first(vals)

  le::Vector{Bool} = vals .<= vals[rand(1:n)]
  nl::Int64 = sum(le)
  nl == n && return first(vals)

  left_tail::Float64 = sum(p[le])
  if α <= left_tail
    return qq(vals[le], p[le], α)
  else
    return qq(vals[.!le], p[.!le], α - left_tail)
  end
end

function quick_CVaR(vals::AbstractVector{Float64}, p::AbstractVector{Float32}, α::Float64)
  # find the α quantile
  # compute the expectation of the values that are greater than the α quantile
  n::Int64 = length(vals)
  @assert n == length(p)
  n == 1 && return first(vals)
  q::Real = qq(vals, p, α) # α quantile
  ret::Float64 = 0.0
  @inbounds for i in 1:n
    if vals[i] >= q
      ret += vals[i] * p[i]
    end
  end
  return ret
end

# Now we plot the runtime of quick_CVaR vs CVaR_e
using Plots
using Random

α::Float64 = 0.95
n = 2:1000:2000000
qcvar::Vector{Float64} = zeros(Float64, length(n))
cvar::Vector{Float64} = zeros(Float64, length(n))
gurobi::Vector{Float64} = zeros(Float64, length(n))
# println("Running the simulation gurobi")
# Threads.@threads for i in 1:length(n)
#   p = rand(Float32, n[i])
#   p = p ./ sum(p)
#   gurobi[i] = @elapsed gurobi_cvar(rand(n[i]), p, α)
# end
println("Running the simulation quick_CVaR")
@inbounds Threads.@threads for i in 1:length(n)
  p = rand(Float32, n[i])
  p = p ./ sum(p)
  cur_time = time()
  quick_CVaR(rand(n[i]), p, α)
  qcvar[i] = time() - cur_time
end
println("Running the simulation CVaR_e")
@inbounds Threads.@threads for i in 1:length(n)
  p = rand(Float32, n[i])
  p = p ./ sum(p)
  cur_time = time()
  CVaR_e(rand(n[i]), p, α)
  cvar[i] = time() - cur_time
end

plot(n, qcvar, label="quick_CVaR", xlabel="n", ylabel="runtime", title="Runtime of quick_CVaR vs CVaR_e")
plot!(n, cvar, label="CVaR_e")
plot!(n, gurobi, label="gurobi")
savefig("runtime.png")

