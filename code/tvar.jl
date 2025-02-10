include("./loop_cvar.jl")

function TVaR(x, p, β)
  n = length(x)
  pbar = copy(p)
  0 <= β <= 1 || throw(ArgumentError("β must be in [0, 1]"))
  min_ind = findmin(x)[2]
  offset = min((β / 2), 1 - pbar[min_ind]) # allocate to the minimum
  _, var_ind = qql!(x, pbar, offset)
  pbar[min_ind] += offset
  sum = offset
  for i in range(n, var_ind + 1, step=-1) # every element bigger than the quantilej
    increment = pbar[i]
    pbar[i] = 0
    sum -= increment
  end
  # deal with quantile
  pbar[var_ind] = max(pbar[var_ind] - sum, 0)
  return pbar' * x
end
