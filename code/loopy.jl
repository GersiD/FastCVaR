using RiskMeasures
using Test

function swap!(vals::AbstractVector{Float64}, p::AbstractVector{Float64}, i::Int, j::Int)
  vals[i], vals[j] = vals[j], vals[i]
  p[i], p[j] = p[j], p[i]
end

function partition!(vals::AbstractVector{Float64}, p::AbstractVector{Float64}, f::Int, b::Int)
  pivot = f + Int(ceil((b - f) / 2))
  pivot_val = vals[pivot]
  swap!(vals, p, pivot, b) # move pivot to back
  store_index = f
  for i ∈ range(f, b - 1)
    if vals[i] < pivot_val
      swap!(vals, p, store_index, i)
      store_index += 1
    end
  end
  swap!(vals, p, b, store_index)
  return store_index
end


## Quick Quantile (loopy version)
function qql(vals::AbstractVector{Float64}, p::AbstractVector{Float64}, α::Real)
  f = 1
  b = length(vals)
  while b - f > 1
    ind = partition!(vals, p, f, b)
    le::Vector{Bool} = vals .<= vals[ind]
    tail::Float64 = sum(p[le])
    α <= tail ? b = ind : f = ind # Cut off half of the random variable
  end
  if f == b
    return vals[f]
  else # 2 values TODO: PROBABLY WRONG
    return vals[b]
  end
end





@testset "Loopy tests" begin
  x::Vector{Float64} = Float64[1, 2, 3]
  p = [1 / 3, 1 / 3, 1 / 3]
  @test qql(x, p, 0.5) ≈ 2

  x = Float64[10, 2, 4, 7, 8]
  p = [0.1, 0.1, 0.3, 0.3, 0.2]
  @test qql(x, p, 0.5) ≈ 7

  x = Float64[4, 5, 1, 2, -1, -2]
  p = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0]

  # @test qql(x, p, 1) ≈ -1.0
  @test qql(x, p, 1 - 0.99) ≈ -1.0
  @test qql(x, p, 0.5) ≈ 1.0
  @test qql(x, p, 0.4) ≈ 1.0

  x = [4.0, 5.0, 1.0, 2.0, -1.0]
  p = [0.1, 0.2, 0.3, 0.1, 0.3]

  # @test qql(x, p, 1) ≈ -1.0 # TODO: what do
  @test qql(x, p, 0) ≈ -1.0 # TODO: help
  # @test qql(x, p, 0.0) ≈ Inf
  @test qql(x, p, 0.5) ≈ 1.0
  @test qql(x, p, 0.4) ≈ 1.0
end
