using Plots
using LinearAlgebra

pgfplotsx()


x = [-1, 3, 5, 5.1, 5.3, 5,8, 6.1, 7]
k = 3

ξ(λ) = clamp.(x .+ 0.5 *λ, 0,1)  # the optimal dual solution

f(λ) = norm(x - ξ(λ))^2 - λ * (sum(ξ(λ)) - k) # the optimal objective

plot(f, xlim = [-15, 15])
