# Compute the risk measure for any choquet capacity function ξ
import Optim: optimize, Brent, BFGS
using RiskMeasures

function expectile(values, p, α)
  if abs(α - 0.5) <= 1e-10
    return values' * p
  end

  xmin, xmax = extrema(values)
  # the function is minimized
  f(x) = α * (max.(values .- x, 0) .^ 2)' * p + (1 - α) * (max.(values .- x, 0) .^ 2)' * p
  sol = optimize(f, xmin, xmax, Brent())
  sol.converged || error("Failed to find optimal x (unknown reason).")
  isfinite(sol.minimum) || error("Overflow, computed an invalid solution. Check α.")
  x = float(sol.minimizer)
  return x
end

# Input:
# x: vector of rewards
# p: vector of probabilities
# c: choquet capacity function takes a vector of rewards ⊂ powerset({1…n}) and returns a scalar
function risk(x, pmf, c, alpha)
  indices = sortperm(x)
  ξ = zeros(length(x))
  for i in 1:length(x)
    ξ[indices[i]] = c(indices[1:i], pmf, alpha) - c(indices[1:i-1], pmf, alpha)
  end
  return sum(ξ .* x)
end

# Example
x = [1, 20, 30, 10]
p = [0.1, 0.4, 0.3, 0.2]
c = function (S, pmf, alpha)
  one_tilde = zeros(length(pmf))
  for i in S
    one_tilde[i] = 1
  end
  return -expectile(-one_tilde, pmf, alpha)
end
choq_risk = risk(x, p, c, 0.5)
expectile_risk = expectile(x, p, 0.5)
# @show choq_risk
# @show expectile_risk
# @show abs(choq_risk - expectile_risk)
# @show c([], p, 0.5)
# @show c([1], p, 0.5)
# @show c([1, 2, 3, 4], p, 0.5)
# plot difference across different values of α
alphas = 0.0:0.1:1.0
choq_risks = [risk(x, p, c, alpha) for alpha in alphas]
expectile_risks = [EVaR_e(x, p, alpha).value for alpha in alphas]
using Plots
plot(alphas, choq_risks, label="Choquet", lw=2)
plot!(alphas, expectile_risks, label="expectile", lw=2)
plot!(alphas, abs.(choq_risks .- expectile_risks), label="Difference", lw=2)
xlabel!("α")
savefig("choquet_vs_evar.pdf")

