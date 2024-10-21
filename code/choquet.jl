# Compute the risk measure for any choquet capacity function ξ

# Input:
# x: vector of rewards
# p: vector of probabilities
# c: choquet capacity function takes a vector of rewards ⊂ powerset({1…n}) and returns a scalar
function risk(x, p, c)
  indices = sortperm(x)
  ξ = zeros(length(x))
  for i in 1:length(x)
    ξ[i] = c(indices[1:i]) - c(indices[1:i-1])
  end
  return sum(ξ .* x)
end

# Example
x = [1, 2, 3, 4]
p = [0.1, 0.2, 0.3, 0.4]
c = function (x) # TODO: THIS IS WRONG
  return sum(x)
end
ξ = risk(x, p, c)
@show ξ


