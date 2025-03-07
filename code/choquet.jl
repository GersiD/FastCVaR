# Compute the risk measure for any choquet capacity function ξ
import Optim: optimize, Brent, BFGS
using RiskMeasures
using RobustMDPs
using Plots
include("./tvar.jl")
include("./gurobi.jl")

"""
    expectile(values, p, α)

Compute the expectile of a random variable `values` with probabilities `p` at level `α`.
"""
function expectile(values, p, α)
  if abs(α - 0.5) <= 1e-10
    return values' * p
  end

  xmin, xmax = extrema(values)
  # the function is minimized
  f(x) = α * (max.(values .- x, 0) .^ 2)' * p + (1 - α) * (max.(x .- values, 0) .^ 2)' * p
  sol = optimize(f, xmin, xmax, Brent())
  sol.converged || error("Failed to find optimal x (unknown reason).")
  isfinite(sol.minimum) || error("Overflow, computed an invalid solution. Check α.")
  x = float(sol.minimizer)
  return -x
end

fns = Dict(
  # "expectile" => expectile,
  # "Expectation" => function (x, p, α)
  #   return x' * p
  # end,
  # "CVaR" => function (x, p, α)
  #   return CVaR(x, p, α).value
  # end,
  # "EVaR" => function (x, p, α)
  #   return EVaR(x, p, α).value
  # end,
  # "VaR" => function (x, p, α)
  #   return VaR(x, p, α).value
  # end,
  "WorstCaseL1UnWeighted" => function (x, p, α)
    return worstcase_l1(x, p, α)[2]
  end,
  # "WorstCaseL1Weighted" => function (x, p, α)
  #   w = ones(Float64, length(x))
  #   return RobustMDPs.worstcase_l1_w(x, p, w, α)[2]
  # end,
  "TVaR" => function (x, p, α)
    return TVaR!(x, p, α)
  end,
  # "TVaR Gurobi" => function (x, p, α)
  #   return worstcase_l1_gurobi(x, p, α)[2]
  # end,
)
# Choquet capacity functions - for testing purposes
alt_cs = Dict(
  # "WorstCaseL1UnWeighted" => function (S, pmf, β)
  #   length(S) == 0 && return 0
  #   return min((β / 2) + sum(view(pmf, S)), 1)
  # end,
  # "TVaR" => function (S, pmf, β)
  #   length(S) == 0 && return 0
  #   return min((β / 2) + sum(view(pmf, S)), 1)
  # end,
  "CVaR" => function (S, pmf, α) # this is the submodular function for CVaR
    return min((1 / (α)) * sum(view(pmf, S)), 1)
  end,
)
"""
    closure_c(ρ)

Given a submodular function *ρ*, 
  return a *closure* that computes the submodular function c(S) = -ρ(-1_S) where 1_S is the indicator vector of S.
"""
function closure_c(ρ::Function)
  return function (S::AbstractVector{<:Integer}, pmf::AbstractVector{<:Real}, alpha::Float64) # this is the submodular function
    length(S) == 0 && return 0 # By definition c(∅) = 0
    one_tilde = zeros(Float64, length(pmf))
    one_tilde[S] .= 1 # wow, julia thanks for this neat notation
    return -ρ(-one_tilde, pmf, alpha)
  end
end

"""
    choq_risk(x, pmf, c, α)

Compute the risk measure for a given choquet capacity function `c` and random variable `x` with probabilities `pmf` at level `α`.
"""
function choq_risk(x::AbstractVector{<:Real}, pmf::AbstractVector{<:Real}, c::Function, alpha::Float64)
  indices = sortperm(x)
  ξ = zeros(Float64, length(x))
  for i in 1:length(x)
    ci = c(indices[1:i], pmf, alpha)
    c1m1 = c(indices[1:i-1], pmf, alpha)
    @assert 0.0 <= ci <= 1.0
    @assert 0.0 <= c1m1 <= 1.0
    ξ[indices[i]] = ci - c1m1
  end
  return ξ' * x
end
n = 100
x = randn(n)
p = rand(n)
p /= sum(p)
for (name, fn) in fns
  println("Risk for $name: ")
  c = closure_c(fn)
  if name in keys(alt_cs)
    c = alt_cs[name]
  end
  # plot difference across different values of α
  alphas = 0.0:0.01:1.0
  choq_risks = [choq_risk(x, p, c, alpha) for alpha in alphas] # computed using the choquet function
  direct_risks = [fn(x, p, alpha) for alpha in alphas] # computed using the actual function
  plot(alphas, choq_risks, label="Choquet", lw=2)
  plot!(alphas, direct_risks, label="$name", lw=2)
  plot!(alphas, abs.(choq_risks .- direct_risks), label="Difference", lw=2)
  xlabel!("α")
  savefig("./comonotone-graphs/choquet_vs_$name.pdf")
end

