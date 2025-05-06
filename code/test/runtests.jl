include("../loop_cvar.jl")
include("../tvar.jl")
include("../gurobi.jl") # for worstcase_l1_gurobi
using Test
using RobustMDPs
# using RobustMDPs

@testset "Loopy tests" begin
  x1::Vector{Float64} = Float64[1, 2, 3]
  p1 = [1 / 3, 1 / 3, 1 / 3]
  @test qql!(x1, p1, 0.5).value ≈ 2
  @test VaR(x1, p1, 0.5).value ≈ 2

  x1 = Float64[3, 2, 1]
  @test qql!(x1, p1, 0.5).value ≈ 2
  @test VaR(x1, p1, 0.5).value ≈ 2
  x1 = [2.0, 1.0, 3.0]
  p1 = [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0]
  @test VaR(x1, p1, 0.5).value ≈ 2.0
  @test qql!(x1, p1, 0.5).value ≈ 2.0

  x2 = Float64[10, 2, 4, 7, 8]
  p2 = [0.1, 0.1, 0.3, 0.3, 0.2]
  @test qql!(x2, p2, 0.5).value ≈ 7
  @test VaR(x2, p2, 0.5).value ≈ 7

  x3 = Float64[4, 5, 1, 2, -1, -2]
  p3 = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0]

  @test qql!(x3, p3, 0.0).value ≈ -1.0
  @test VaR(x3, p3, 0.0).value ≈ -1.0
  @test qql!(x3, p3, 1).value ≈ Inf
  @test VaR(x3, p3, 1).value ≈ Inf
  @test qql!(x3, p3, 0.99).value ≈ 5.0
  @test VaR(x3, p3, 0.99).value ≈ 5.0
  @test qql!(x3, p3, 0.5).value ≈ 1.0
  @test VaR(x3, p3, 0.5).value ≈ 1.0
  @test qql!(x3, p3, 0.4).value ≈ 1.0
  @test VaR(x3, p3, 0.4).value ≈ 1.0
  @test qql!(x3, p3, 0.6).value ≈ 1.0
  @test VaR(x3, p3, 0.6).value ≈ 1.0

  x4 = [4.0, 5.0, 1.0, 2.0, -1.0]
  p4 = [0.1, 0.2, 0.3, 0.1, 0.3]

  @test qql!(x4, p4, 1).value ≈ Inf
  @test VaR(x4, p4, 1).value ≈ Inf
  @test qql!(x4, p4, 0.99).value ≈ 5.0
  @test VaR(x4, p4, 0.99).value ≈ 5.0
  @test qql!(x4, p4, 0).value ≈ -1.0
  @test VaR(x4, p4, 0).value ≈ -1.0
  @test qql!(x4, p4, 0.5).value ≈ 1.0
  @test VaR(x4, p4, 0.5).value ≈ 1.0
  @test qql!(x4, p4, 0.4).value ≈ 1.0

  x5 = [2.0, 1.0]
  p5 = [0.5, 0.5]
  @test qql!(x5, p5, 0.5).value ≈ 1.0
  @test VaR(x5, p5, 0.5).value ≈ 2.0
  @test qql!(x5, p5, 0.9).value ≈ 2.0
  @test VaR(x5, p5, 0.9).value ≈ 2.0
  @test qql!(x5, p5, 0.3).value ≈ 1.0
  @test VaR(x5, p5, 0.3).value ≈ 1.0

  x5 = [1.0, 2.0]
  p5 = [0.5, 0.5]
  @test qql!(x5, p5, 0.5).value ≈ 1.0
  @test VaR(x5, p5, 0.5).value ≈ 2.0
  @test qql!(x5, p5, 0.1).value ≈ 1.0
  @test VaR(x5, p5, 0.1).value ≈ 1.0
  @test qql!(x5, p5, 0.9).value ≈ 2.0
  @test VaR(x5, p5, 0.9).value ≈ 2.0

  x1 = [1, 2, 3]
  p1 = [0.5, 0.2, 0.3]
  @test qql!(x1, p1, 0.4).value ≈ 1
  @test qql!(x1, p1, 0.4).index ≈ 1
  @test VaR(x1, p1, 0.4).value ≈ 1
  @test VaR(x1, p1, 0.4).index ≈ 1

  # x1 = [1, 1, 1] # TODO: The world is not yet read for something this controversial
  # p1 = [0.0, 1.0, 0.0]
  # @test qql!(x1, p1, 0.5).value ≈ 1
  # @test VaR(x1, p1, 0.5).value ≈ 1
  # @test qql!(x1, p1, 0.5).index == 2
  # @test VaR(x1, p1, 0.5).index == 2
end

@testset "Fast CVaR Tests" begin
  x1 = [4, 5, 1, 2, -1, -2]
  p = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0]

  @test CVaR(x1, p, 0).value ≈ -1.0
  @test qCVaR!(x1, p, 0).value ≈ -1.0
  @test CVaR(x1, p, 0.01).value ≈ -1.0
  @test qCVaR!(x1, p, 0.01).value ≈ -1.0
  @test CVaR(x1, p, 1.0).value ≈ 1.6
  @test qCVaR!(x1, p, 1.0).value ≈ 1.6
  @test CVaR(x1, p, 0.5).value ≈ -0.2
  @test qCVaR!(x1, p, 0.5).value ≈ -0.2
  @test CVaR(x1, p, 0.6).value ≈ 0.0
  @test qCVaR!(x1, p, 0.6).value ≈ 0.0

  p = [0.1, 0.2, 0.3, 0.1, 0.3]
  x2 = [4.0, 5.0, 1.0, 2.0, -1.0]

  @test CVaR(x2, p, 0).value ≈ -1.0
  @test qCVaR!(x2, p, 0).value ≈ -1.0
  @test CVaR(x2, p, 1).value ≈ 1.6
  @test qCVaR!(x2, p, 1).value ≈ 1.6
  @test CVaR(x2, p, 0.5).value ≈ -0.2
  @test qCVaR!(x2, p, 0.5).value ≈ -0.2
  @test CVaR(x2, p, 0.6).value ≈ 0
  @test qCVaR!(x2, p, 0.6).value ≈ 0
end

@testset "Duplicates" begin
  x1 = [1, 2, 2, 3]
  p = [1 / 4, 1 / 4, 1 / 4, 1 / 4]
  @test qql!(x1, p, 0.5).value ≈ 2
  @test VaR(x1, p, 0.5).value ≈ 2
  x1 = [3, 2, 2, 1]
  p = [1 / 4, 1 / 4, 1 / 4, 1 / 4]
  @test qql!(x1, p, 0.5).value ≈ 2
  @test VaR(x1, p, 0.5).value ≈ 2
  x1 = [1, 2, 2, 1]
  p = [1 / 4, 1 / 4, 1 / 4, 1 / 4]
  @test qql!(x1, p, 0.5).value ≈ 1
  @test VaR(x1, p, 0.5).value ≈ 2
  x1 = [1, 1, 1, 1]
  p = [1 / 4, 1 / 4, 1 / 4, 1 / 4]
  @test qql!(x1, p, 0.5).value ≈ 1
  @test VaR(x1, p, 0.5).value ≈ 1
  x1 = [1]
  p = [1.0]
  @test qql!(x1, p, 0.5).value ≈ 1
  @test VaR(x1, p, 0.5).value ≈ 1

  x1 = [4, 5, 1, 1, 2, -1, -2]
  p = [0.1, 0.2, 0.2, 0.1, 0.1, 0.3, 0.0]

  @test CVaR(x1, p, 0.0).value ≈ -1.0
  @test qCVaR!(x1, p, 0.0).value ≈ -1.0
  @test CVaR(x1, p, 0.01).value ≈ -1.0
  @test qCVaR!(x1, p, 0.01).value ≈ -1.0
  @test CVaR(x1, p, 1).value ≈ 1.6
  @test qCVaR!(x1, p, 1).value ≈ 1.6
  @test CVaR(x1, p, 0.5).value ≈ -0.2
  @test qCVaR!(x1, p, 0.5).value ≈ -0.2
  @test CVaR(x1, p, 0.6).value ≈ 0.0
  @test qCVaR!(x1, p, 0.6).value ≈ 0.0
end

@testset "qql behaves reasonably when mutating" begin
  x1 = [1, 2, 3]
  p1 = [1 / 3, 1 / 3, 1 / 3]
  qql!(x1, p1, 0.5)
  @test x1 ≈ [1, 2, 3]
  @test p1 ≈ [1 / 3, 1 / 3, 1 / 3]
  x1 = [3, 2, 1]
  p1 = [0.99, 0.01, 0.0]
  qql!(x1, p1, 0.5)
  @test x1 ≈ [1, 2, 3]
  @test p1 ≈ [0.0, 0.01, 0.99]
end

@testset "TVaR" begin
  x1 = [1, 2, 3]
  p1 = [0.5, 0.2, 0.3]
  for β in range(0.0, 1.99, step=0.2)
    @test worstcase_l1(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
    @test worstcase_l1_gurobi(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
  end
  x1 = [3, 2, 1]
  p1 = [0.3, 0.2, 0.5]
  for β in range(0.0, 1.99, step=0.2)
    @test worstcase_l1(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
    @test worstcase_l1_gurobi(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
  end
  x1 = [1, 2, 3]
  p1 = [0.0, 1.0, 0.0]
  for β in range(0.0, 1.99, step=0.2)
    @test worstcase_l1(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
    @test worstcase_l1_gurobi(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
  end
  x1 = [-2.0, -1.0, 1.0, 2.0, 4.0, 5.0]
  p1 = [0.0, 0.3, 0.3, 0.1, 0.1, 0.2]
  pstar = [0.4, 0.3, 0.3, 0.0, 0.0, 0.0] # solution for β = 0.8
  for β in range(0.0, 1.99, step=0.2)
    @test worstcase_l1(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
    @test worstcase_l1_gurobi(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
  end
  x1 = [5.0, 4.0, 2.0, 1.0, -1.0, -2.0]
  p1 = [0.2, 0.1, 0.1, 0.3, 0.3, 0.0]
  for β in range(0.0, 1.99, step=0.2)
    @test worstcase_l1(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
    @test worstcase_l1_gurobi(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
  end
  # x1 = [-1.0, -1.0, -1.0] # TODO: Maybe one day
  # p1 = [0.0, 1.0, 0.0]
  # β = 0.2
  # @test worstcase_l1(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
  # @test worstcase_l1_gurobi(copy(x1), copy(p1), β)[2] ≈ TVaR!(copy(x1), copy(p1), β)
end

@testset "CVaR<EVaR<TVaR" begin
  x1 = [5.0, 4.0, 2.0, 1.0, -1.0, -2.0]
  p1 = [0.2, 0.1, 0.1, 0.3, 0.3, 0.0]
  cvar = CVaR(x1, p1, 0.5).value
  qcvar = qCVaR!(x1, p1, 0.5).value
  tvar = TVaR!(x1, p1, sqrt(-2log(2) * log(0.5)))
  evar = EVaR(x1, p1, 0.5).value
  @test cvar >= evar >= tvar
  @test qcvar >= evar >= tvar
  for _ in range(1, 10)
    x = randn(10)
    p = rand(Float64, 10)
    p /= sum(p)
    α = 0.5
    cvar = CVaR(x, p, α).value
    qcvar = qCVaR!(x, p, α).value
    tvar = TVaR!(x, p, sqrt(-2log(2) * log(α)))
    evar = EVaR(x, p, α).value
    @test cvar >= evar >= tvar
    @test qcvar >= evar >= tvar
  end
end


# @testset "Sanity Check Robust MDPs" begin
#   x = randn(5)
#   probs = rand(5)
#   probs = probs / sum(probs)
#   α = clamp(randn(Float64), 0, 2)
#   (α < 0.0) && (α *= -1.0)
#   @test worstcase_l1_weighted_gurobi(x, probs, α, ones(5))[2] ≈ worstcase_l1_gurobi(x, probs, α)[2]
#   @test worstcase_l1_gurobi(x, probs, α)[2] ≈ worstcase_l1(x, probs, α)[2]
#   @test worstcase_l1_weighted_gurobi(x, probs, α, ones(5))[2] ≈ worstcase_l1_w(x, probs, ones(5), α)[2]
#   w = abs.(rand(5))
#   w = w / sum(w)
#   @test worstcase_l1_weighted_gurobi(x, probs, α, w)[2] ≈ worstcase_l1_w(x, probs, w, α)[2] # TODO: write the real unit test use HIghs
# end
