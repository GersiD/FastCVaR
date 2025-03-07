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
  @inbounds for i in range(n, var_ind + 1, step=-1) # every element bigger than the quantile
    offset -= pbar[i]
    pbar[i] = 0
  end
  for i in range(var_ind, 1, step=-1)
    @assert xbar[i] ≈ xbar[var_ind] # for debugging
    if offset <= pbar[i]
      @inbounds pbar[i] -= offset
      break
    end
    @inbounds offset -= pbar[i]
    @inbounds pbar[i] = 0
  end
  return pbar' * xbar
end
