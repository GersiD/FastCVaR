include("../loop_cvar.jl")
using Test

@testset "Loopy tests" begin
  x1::Vector{Float64} = Float64[1, 2, 3]
  p1 = [1 / 3, 1 / 3, 1 / 3]
  @test qql!(x1, p1, 0.5) ≈ 2
  @test VaR_e(x1, p1, 0.5)[1] ≈ 2

  x1 = Float64[3, 2, 1]
  @test qql!(x1, p1, 0.5) ≈ 2
  @test VaR_e(x1, p1, 0.5)[1] ≈ 2

  x2 = Float64[10, 2, 4, 7, 8]
  p2 = [0.1, 0.1, 0.3, 0.3, 0.2]
  @test qql!(x2, p2, 0.5) ≈ 7
  @test VaR_e(x2, p2, 0.5)[1] ≈ 7

  x3 = Float64[4, 5, 1, 2, -1, -2]
  p3 = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0]

  @test qql!(x3, p3, 0.0) ≈ -1.0
  @test VaR_e(x3, p3, 1 - 0.0)[1] ≈ -1.0
  @test qql!(x3, p3, 1) ≈ Inf
  @test VaR_e(x3, p3, 1 - 1)[1] ≈ Inf
  @test qql!(x3, p3, 0.99) ≈ 5.0
  @test VaR_e(x3, p3, 1 - 0.99)[1] ≈ 5.0
  @test qql!(x3, p3, 0.5) ≈ 1.0
  @test VaR_e(x3, p3, 0.5)[1] ≈ 1.0
  @test qql!(x3, p3, 0.4) ≈ 1.0
  @test VaR_e(x3, p3, 0.6)[1] ≈ 1.0
  @test qql!(x3, p3, 0.6) ≈ 2.0
  @test VaR_e(x3, p3, 1 - 0.6)[1] ≈ 2.0

  x4 = [4.0, 5.0, 1.0, 2.0, -1.0]
  p4 = [0.1, 0.2, 0.3, 0.1, 0.3]

  @test qql!(x4, p4, 1) ≈ Inf
  @test VaR_e(x4, p4, 1 - 1)[1] ≈ Inf
  @test qql!(x4, p4, 0.99) ≈ 5.0
  @test VaR_e(x4, p4, 1 - 0.99)[1] ≈ 5.0
  @test qql!(x4, p4, 0) ≈ -1.0
  @test VaR_e(x4, p4, 1 - 0)[1] ≈ -1.0
  @test qql!(x4, p4, 0.5) ≈ 1.0
  @test VaR_e(x4, p4, 1 - 0.5)[1] ≈ 1.0
  @test qql!(x4, p4, 0.4) ≈ 1.0

  x5 = [2.0, 1.0]
  p5 = [0.5, 0.5]
  @test qql!(x5, p5, 0.5) ≈ 2.0
  @test VaR_e(x5, p5, 0.5)[1] ≈ 2.0
  @test qql!(x5, p5, 0.1) ≈ 1.0
  @test VaR_e(x5, p5, 0.9)[1] ≈ 1.0
  @test qql!(x5, p5, 0.9) ≈ 2.0
  @test VaR_e(x5, p5, 0.1)[1] ≈ 2.0
end

@testset "Fast CVaR Tests" begin
  x1 = [4, 5, 1, 2, -1, -2]
  p = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0]

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

  p = [0.1, 0.2, 0.3, 0.1, 0.3]
  x2 = [4.0, 5.0, 1.0, 2.0, -1.0]

  @test CVaR_e(x2, p, 1)[1] ≈ -1.0
  @test qCVaR!(x2, p, 1 - 1) ≈ -1.0
  @test CVaR_e(x2, p, 0)[1] ≈ 1.6
  @test qCVaR!(x2, p, 1 - 0) ≈ 1.6
  @test CVaR_e(x2, p, 0.5)[1] ≈ -0.2
  @test qCVaR!(x2, p, 1 - 0.5) ≈ -0.2
  @test CVaR_e(x2, p, 0.4)[1] ≈ 0
  @test qCVaR!(x2, p, 1 - 0.4) ≈ 0
end

