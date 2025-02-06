include("./loop_cvar.jl")

function TVaR(x, p, β)
  pbar = zeros(length(p))
  0 <= β <= 1 || throw(ArgumentError("β must be in [0, 1]"))
  min_ind = findmin(x)[2]
  offset = min(pbar[min_ind] + (β / 2), 1 - pbar[min_ind])
  _, var_ind = qql!(x, pbar, offset)
  allocated_prob = 0.0
  for i in 1:var_ind
    allocated_prob += pbar[i]
    pbar[i] = 0
  end
  if allocated_prob < offset
    z = clamp(var_ind + 1, 1, length(p))
    pbar[z] = pbar[z] - offset - allocated_prob
  end
  return sum(x .* pbar)
end
