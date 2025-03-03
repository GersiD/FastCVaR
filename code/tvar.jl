include("./loop_cvar.jl")

"""
    TVaR(x, p, β)

Compute the TVaR of a random variable `x` with probabilities `p` at level `β`.
Mutates `x` and `p` in the process.
"""
function TVaR!(x, p, β)
  0 <= β < 2 || throw(ArgumentError("β must be in [0, 2)"))
  xbar = copy(x)
  pbar = copy(p)
  β == 0 && return pbar' * xbar
  n = length(xbar)
  min_ind = findmin(xbar)[2]
  offset = min((β / 2), 1 - pbar[min_ind]) # allocate to the minimum
  offset < (β / 2) && return xbar[min_ind] # Special case
  _, var_ind = qql!(xbar, pbar, 1 - offset) # complement of offset to target higher numbers
  min_ind = findmin(xbar)[2] # qql mutates xbar and pbar
  pbar[min_ind] += offset
  for i in range(n, var_ind + 1, step=-1) # every element bigger than the quantile
    offset -= pbar[i]
    pbar[i] = 0
  end
  # deal with quantile
  pbar[var_ind] = max(pbar[var_ind] - offset, 0)
  return pbar' * xbar
end
