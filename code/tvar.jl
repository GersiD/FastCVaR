include("./loop_cvar.jl")

"""
    TVaR(x, p, β)

Compute the TVaR of a random variable `x` with probabilities `p` at level `β`.
Mutates `x` and `p` in the process.
"""
function TVaR!(x, p, β)
  0 <= β <= 2 || throw(ArgumentError("β must be in [0, 2]"))
  β == 0 && return p' * x
  n = length(x)
  xbar = copy(x)
  pbar = copy(p)
  min_ind = findmin(xbar)[2]
  offset = min((β / 2), 1 - pbar[min_ind]) # allocate to the minimum
  _, var_ind = qql!(xbar, pbar, offset)
  min_ind = findmin(xbar)[2] # qql mutates xbar and pbar
  pbar[min_ind] += offset
  for i in range(n, var_ind + 1, step=-1) # every element bigger than the quantile
    offset -= pbar[i]
    pbar[i] = 0
  end
  # deal with quantile
  pbar[var_ind] = max(pbar[var_ind] - offset, 0)
  @assert sum(pbar) ≈ 1.0
  @assert all(pbar .≥ 0)
  return pbar' * xbar
end

