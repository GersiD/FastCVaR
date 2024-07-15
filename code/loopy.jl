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
  if iszero(α) # minimum
    return essinf_e(vals, p; check_inputs=true)[1]
  elseif isone(α) # maximum (it is unbounded)
    return typemax(eltype(p))
  end
  i = 1
  j = length(vals)
  while j - i > 1
    ind = partition!(vals, p, i, j)
    le::Vector{Bool} = vals .<= vals[ind]
    tail::Float64 = sum(p[le])
    α <= tail ? j = ind : i = ind # Cut off half of the random variable
  end
  if i == j
    return vals[i]
  else # 2 values TODO: PROBABLY WRONG
    return vals[j]
  end
end





@testset "Loopy tests" begin
  x1::Vector{Float64} = Float64[1, 2, 3]
  p1 = [1 / 3, 1 / 3, 1 / 3]
  @test qql(x1, p1, 0.5) ≈ 2

  x2 = Float64[10, 2, 4, 7, 8]
  p2 = [0.1, 0.1, 0.3, 0.3, 0.2]
  @test qql(x2, p2, 0.5) ≈ 7

  x3 = Float64[4, 5, 1, 2, -1, -2]
  p3 = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0]

  #@test VaR(x̃, 1) ≈ -1.0
  #@test VaR(x̃, 0.99) ≈ -1.0
  #@test VaR(x̃, 0.) ≈ Inf
  #@test VaR(x̃, 0.5) ≈ 1.0
  # @test VaR_e(x3, p3, 0.6)[1] ≈ 2.0

  @test qql(x3, p3, 1) ≈ Inf
  @test qql(x3, p3, 0.99) ≈ 5.0
  @test qql(x3, p3, 0.5) ≈ 1.0
  @test qql(x3, p3, 0.4) ≈ 1.0

  x4 = [4.0, 5.0, 1.0, 2.0, -1.0]
  p4 = [0.1, 0.2, 0.3, 0.1, 0.3]
  #@test VaR(x̃, 1) ≈ -1.0
  #@test VaR(x̃, 0.99) ≈ -1.0
  #@test VaR(x̃, 0.0) ≈ Inf
  #@test VaR(x̃, 0.5) ≈ 1.0
  #@test VaR(x̃, 0.4) ≈ 2.0

  @test qql(x4, p4, 1) ≈ Inf
  @test qql(x4, p4, 0.99) ≈ 5.0
  @test qql(x4, p4, 0) ≈ -1.0
  # @test qql(x4, p4, 0.0) ≈ Inf
  @test qql(x4, p4, 0.5) ≈ 1.0
  @test qql(x4, p4, 0.4) ≈ 1.0
end
