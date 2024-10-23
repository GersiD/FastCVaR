# Compute the risk measure for any choquet capacity function ξ
using RiskMeasures
using RobustMDPs
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
  return -worstcase_l1(-one_tilde, pmf, alpha)[2]
end
# c = function (S, pmf, alpha) # sorry palash
#   if isempty(S)
#     return 0
#   end
#   return min(1 / (1 - alpha) * sum(pmf[i] for i in S), 1)
# end
choq_risk = risk(x, p, c, 0.5)
evar_risk = worstcase_l1(x, p, 0.5)[2]
@show choq_risk
@show evar_risk
@show abs(choq_risk - evar_risk)
@show c([], p, 0.5)
@show c([1], p, 0.5)
@show c([1, 2, 3, 4], p, 0.5)
# plot difference across different values of α
alphas = 0.0:0.1:1.0
choq_risks = [risk(x, p, c, alpha) for alpha in alphas]
evar_risks = [EVaR_e(x, p, alpha).value for alpha in alphas]
using Plots
plot(alphas, choq_risks, label="Choquet", lw=2)
plot!(alphas, evar_risks, label="worstcase_l1", lw=2)
plot!(alphas, abs.(choq_risks .- evar_risks), label="Difference", lw=2)
xlabel!("α")
savefig("choquet_vs_evar.pdf")
