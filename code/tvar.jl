include("./loop_cvar.jl")

function TVaR(x, p, β)
  0 <= β <= 1 || throw(ArgumentError("β must be in [0, 1]"))
  min_ind = findmin(x)[2]
  offset = min(p[min_ind] + (β / 2), 1 - p[min_ind])
  _, var_ind = qql!(x, p, offset)
  allocated_prob = 0
  for i in 1:var_ind
    allocated_prob += p[i]
    p[i] = 0
  end
  if allocated_prob < offset
    z = var_ind + 1
    p[z] = p[z] - offset - allocated_prob
  end
  return sum(x .* p)
end
