# Compute the risk measure for any choquet capacity function ξ
import Optim: optimize, Brent, BFGS
using RiskMeasures
using RobustMDPs
using Plots

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

fns = Dict("expectile" => expectile,
  "CVaR" => function (x, p, α)
    return CVaR_e(x, p, α).value
  end,
  "EVaR" => function (x, p, α)
    return EVaR_e(x, p, α).value
  end,
  "VaR" => function (x, p, α)
    return VaR_e(x, p, α).value
  end,
  "WorstCaseL1UnWeighted" => function (x, p, α)
    return worstcase_l1(x, p, α)[2]
  end,
  "WorstCaseL1Weighted" => function (x, p, α)
    w = ones(Float64, length(x))
    return RobustMDPs.worstcase_l1_w(x, p, w, α)[2]
  end
)
function closure_c(fn)
  return function (S, pmf, alpha)
    one_tilde = zeros(length(pmf))
    for i in S
      one_tilde[i] = -1
    end
    return -fn(one_tilde, pmf, alpha)
  end
end
# Input:
# x: vector of rewards
# p: vector of probabilities
# c: choquet capacity function takes a vector of rewards ⊂ powerset({1…n}) and returns a scalar
return function choq_risk(x, pmf, c, alpha)
  indices = sortperm(x)
  ξ = zeros(length(x))
  for i in 1:length(x)
    ξ[indices[i]] = c(indices[1:i], pmf, alpha) - c(indices[1:i-1], pmf, alpha)
  end
  return sum(ξ .* x)
end
n = 100
for (name, fn) in fns
  println("Risk for $name: ")
  x = randn(n)
  p = rand(n)
  p /= sum(p)
  c = closure_c(fn)
  # plot difference across different values of α
  alphas = 0.0:0.01:1.0
  choq_risks = [choq_risk(x, p, c, alpha) for alpha in alphas]
  expectile_risks = [fn(x, p, alpha) for alpha in alphas]
  plot(alphas, choq_risks, label="Choquet", lw=2)
  plot!(alphas, expectile_risks, label="$name", lw=2)
  plot!(alphas, abs.(choq_risks .- expectile_risks), label="Difference", lw=2)
  xlabel!("α")
  savefig("./comonotone-graphs/choquet_vs_$name.pdf")
end

