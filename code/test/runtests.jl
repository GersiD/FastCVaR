include("../loop_cvar.jl")
using Test
using JuMP, HiGHS
# using RobustMDPs

# TODO: Test cases with 2 elements and 1
#
# @testset "Loopy tests" begin
#   x1::Vector{Float64} = Float64[1, 2, 3]
#   p1 = [1 / 3, 1 / 3, 1 / 3]
#   @test qql!(x1, p1, 0.5) ≈ 2
#   @test VaR_e(x1, p1, 0.5)[1] ≈ 2
#
#   x1 = Float64[3, 2, 1]
#   @test qql!(x1, p1, 0.5) ≈ 2
#   @test VaR_e(x1, p1, 0.5)[1] ≈ 2
#
#   x2 = Float64[10, 2, 4, 7, 8]
#   p2 = [0.1, 0.1, 0.3, 0.3, 0.2]
#   @test qql!(x2, p2, 0.5) ≈ 7
#   @test VaR_e(x2, p2, 0.5)[1] ≈ 7
#
#   x3 = Float64[4, 5, 1, 2, -1, -2]
#   p3 = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0]
#
#   @test qql!(x3, p3, 0.0) ≈ -1.0
#   @test VaR_e(x3, p3, 1 - 0.0)[1] ≈ -1.0
#   @test qql!(x3, p3, 1) ≈ Inf
#   @test VaR_e(x3, p3, 1 - 1)[1] ≈ Inf
#   @test qql!(x3, p3, 0.99) ≈ 5.0
#   @test VaR_e(x3, p3, 1 - 0.99)[1] ≈ 5.0
#   @test qql!(x3, p3, 0.5) ≈ 1.0
#   @test VaR_e(x3, p3, 0.5)[1] ≈ 1.0
#   @test qql!(x3, p3, 0.4) ≈ 1.0
#   @test VaR_e(x3, p3, 0.6)[1] ≈ 1.0
#   @test qql!(x3, p3, 0.6) ≈ 2.0
#   @test VaR_e(x3, p3, 1 - 0.6)[1] ≈ 2.0
#
#   x4 = [4.0, 5.0, 1.0, 2.0, -1.0]
#   p4 = [0.1, 0.2, 0.3, 0.1, 0.3]
#
#   @test qql!(x4, p4, 1) ≈ Inf
#   @test VaR_e(x4, p4, 1 - 1)[1] ≈ Inf
#   @test qql!(x4, p4, 0.99) ≈ 5.0
#   @test VaR_e(x4, p4, 1 - 0.99)[1] ≈ 5.0
#   @test qql!(x4, p4, 0) ≈ -1.0
#   @test VaR_e(x4, p4, 1 - 0)[1] ≈ -1.0
#   @test qql!(x4, p4, 0.5) ≈ 1.0
#   @test VaR_e(x4, p4, 1 - 0.5)[1] ≈ 1.0
#   @test qql!(x4, p4, 0.4) ≈ 1.0
#
#   x5 = [2.0, 1.0]
#   p5 = [0.5, 0.5]
#   @test qql!(x5, p5, 0.5) ≈ 2.0
#   @test VaR_e(x5, p5, 0.5)[1] ≈ 2.0
#   @test qql!(x5, p5, 0.1) ≈ 1.0
#   @test VaR_e(x5, p5, 0.9)[1] ≈ 1.0
#   @test qql!(x5, p5, 0.9) ≈ 2.0
#   @test VaR_e(x5, p5, 0.1)[1] ≈ 2.0
#
#   x5 = [1.0, 2.0]
#   p5 = [0.5, 0.5]
#   @test qql!(x5, p5, 0.5) ≈ 2.0
#   @test VaR_e(x5, p5, 0.5)[1] ≈ 2.0
#   @test qql!(x5, p5, 0.1) ≈ 1.0
#   @test VaR_e(x5, p5, 0.9)[1] ≈ 1.0
#   @test qql!(x5, p5, 0.9) ≈ 2.0
#   @test VaR_e(x5, p5, 0.1)[1] ≈ 2.0
# end

# @testset "Fast CVaR Tests" begin
#   x1 = [4, 5, 1, 2, -1, -2]
#   p = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0]
#
#   @test CVaR_e(x1, p, 1)[1] ≈ -1.0
#   @test qCVaR!(x1, p, 1 - 1) ≈ -1.0
#   @test CVaR_e(x1, p, 0.99)[1] ≈ -1.0
#   @test qCVaR!(x1, p, 1 - 0.99) ≈ -1.0
#   @test CVaR_e(x1, p, 0.0)[1] ≈ 1.6
#   @test qCVaR!(x1, p, 1 - 0.0) ≈ 1.6
#   @test CVaR_e(x1, p, 0.5)[1] ≈ -0.2
#   @test qCVaR!(x1, p, 1 - 0.5) ≈ -0.2
#   @test CVaR_e(x1, p, 0.4)[1] ≈ 0.0
#   @test qCVaR!(x1, p, 1 - 0.4) ≈ 0.0
#
#   p = [0.1, 0.2, 0.3, 0.1, 0.3]
#   x2 = [4.0, 5.0, 1.0, 2.0, -1.0]
#
#   @test CVaR_e(x2, p, 1)[1] ≈ -1.0
#   @test qCVaR!(x2, p, 1 - 1) ≈ -1.0
#   @test CVaR_e(x2, p, 0)[1] ≈ 1.6
#   @test qCVaR!(x2, p, 1 - 0) ≈ 1.6
#   @test CVaR_e(x2, p, 0.5)[1] ≈ -0.2
#   @test qCVaR!(x2, p, 1 - 0.5) ≈ -0.2
#   @test CVaR_e(x2, p, 0.4)[1] ≈ 0
#   @test qCVaR!(x2, p, 1 - 0.4) ≈ 0
# end

@testset "Duplicates" begin
  x1 = [1, 2, 2, 3]
  p = [1 / 4, 1 / 4, 1 / 4, 1 / 4]
  @test qql!(x1, p, 0.5) ≈ 2
  @test VaR_e(x1, p, 0.5)[1] ≈ 2
  x1 = [3, 2, 2, 1]
  p = [1 / 4, 1 / 4, 1 / 4, 1 / 4]
  @test qql!(x1, p, 0.5) ≈ 2
  @test VaR_e(x1, p, 0.5)[1] ≈ 2
  x1 = [1, 2, 2, 1]
  p = [1 / 4, 1 / 4, 1 / 4, 1 / 4]
  @test qql!(x1, p, 0.5) ≈ 2
  @test VaR_e(x1, p, 0.5)[1] ≈ 2

  x1 = [4, 5, 1, 1, 2, -1, -2]
  p = [0.1, 0.2, 0.2, 0.1, 0.1, 0.3, 0.0]

  @test CVaR_e(x1, p, 1)[1] ≈ -1.0
  @test qCVaR!(x1, p, 1 - 1) ≈ -1.0
  @test CVaR_e(x1, p, 0.99)[1] ≈ -1.0
  @test qCVaR!(x1, p, 1 - 0.99) ≈ -1.0
  @test CVaR_e(x1, p, 0.0)[1] ≈ 1.6
  @test qCVaR!(x1, p, 1 - 0.0) ≈ 1.6
  @test CVaR_e(x1, p, 0.5)[1] ≈ -0.2
  @test qCVaR!(x1, p, 1 - 0.5) ≈ -0.2
  @test CVaR_e(x1, p, 0.4)[1] ≈ 0.0
  @test qCVaR!(x1, p, 1 - 0.4) ≈ 0.0
end

# @testset "Sanity Check Robust MDPs" begin
#   x = randn(5)
#   probs = rand(5)
#   probs = probs / sum(probs)
#   α = clamp(randn(Float64), 0, 2)
#   (α < 0.0) && (α *= -1.0)
#   function worstcase_l1_gurobi(x, pbar, ξ)
#     m = Model(HiGHS.Optimizer)
#     set_optimizer_attribute(m, "log_to_console", false)
#     @variable(m, p[1:length(x)])
#     @variable(m, t[1:length(x)])
#     @constraint(m, p .- pbar <= t)
#     @constraint(m, pbar .- p <= t)
#     @constraint(m, sum(t) <= ξ)
#     @constraint(m, sum(p) == 1)
#     @constraint(m, p .>= 0)
#     @objective(m, Min, p' * x)
#     optimize!(m)
#     termination_status(m) != MOI.OPTIMAL && Error("Gurobi failed to find optimal solution")
#     return value.(p), value.(p)' * x
#   end
#   function worstcase_l1_weighted_gurobi(x, pbar, ξ, w)
#     m = Model(HiGHS.Optimizer)
#     set_optimizer_attribute(m, "log_to_console", false)
#     @variable(m, p[1:length(x)])
#     @variable(m, t[1:length(x)])
#     @constraint(m, p .- pbar <= t)
#     @constraint(m, pbar .- p <= t)
#     @constraint(m, w' * t <= ξ)
#     @constraint(m, sum(p) == 1)
#     @constraint(m, p .>= 0)
#     @objective(m, Min, p' * x)
#     optimize!(m)
#     termination_status(m) != MOI.OPTIMAL && Error("Gurobi failed to find optimal solution")
#     return value.(p), value.(p)' * x
#   end
#   @test worstcase_l1_weighted_gurobi(x, probs, α, ones(5))[2] ≈ worstcase_l1_gurobi(x, probs, α)[2]
#   @test worstcase_l1_gurobi(x, probs, α)[2] ≈ worstcase_l1(x, probs, α)[2]
#   @test worstcase_l1_weighted_gurobi(x, probs, α, ones(5))[2] ≈ worstcase_l1_w(x, probs, ones(5), α)[2]
#   w = abs.(rand(5))
#   w = w / sum(w)
#   @test worstcase_l1_weighted_gurobi(x, probs, α, w)[2] ≈ worstcase_l1_w(x, probs, w, α)[2] # TODO: write the real unit test use HIghs
# end
#
