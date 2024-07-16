using RiskMeasures
using Base.Threads

function swap!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, i::Int, j::Int)
  vals[i], vals[j] = vals[j], vals[i]
  p[i], p[j] = p[j], p[i]
end

function partition!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, f::Int, b::Int)
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
function qql!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, α::Real)
  if iszero(α) # minimum
    return essinf_e(vals, p; check_inputs=true)[1]
  elseif isone(α) # maximum (it is unbounded)
    return typemax(eltype(p))
  end
  i = 1
  j = length(vals)
  @inbounds while j - i > 1
    ind = partition!(vals, p, i, j)
    le::Vector{Bool} = vals .<= vals[ind]
    tail::Float64 = sum(p[le])
    α < tail ? j = ind : i = ind # Cut off half of the random variable
  end
  if i == j
    return vals[i]
  else # 2 values TODO: PROBABLY WRONG
    return vals[j]
  end
end

function qCVaR!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, α::Real)
  T = eltype(p)
  # handle special cases
  if iszero(α)
    minval = essinf_e(vals, p; check_inputs=false)
    minpmf = zeros(T, length(p))
    minpmf[minval.index] = one(T)
    return minval.value
  elseif isone(α)
    return vals' * p
  end
  q = qql!(vals, p, α)

  # From here on: α ∈ (0,1)
  value = zero(T)                  # CVaR value
  p_left = one(T)           # probabilities left for allocation
  α̂ = α                      # probabilities to allocate

  @inbounds for (i, _) ∈ enumerate(vals)
    if vals[i] <= q
      # update index's probability and probability left to sum to 1.0
      increment = min(p[i] / α̂, p_left)
      value += increment * vals[i]
      p_left -= increment
      p_left ≤ zero(p_left) && break
    end
  end
  return value
end

# Time to plot
using Plots
using Random
Random.seed!(1234)

magnitude = 6
len = 100
experiments = range(start=10, stop=10^magnitude, length=len)
qcvar_results = Float64[]
cvar_results = Float64[]
int(x) = Int(ceil(x))
@threads for n ∈ experiments
  n = int(n)
  println("Experiment i / $len --- n = $n")
  x = rand(Float64, n)
  p = rand(Float64, n)
  p ./= sum(p)
  α = rand(Float64)
  push!(qcvar_results, @elapsed qCVaR!(x, p, α))
  push!(cvar_results, @elapsed CVaR_e(x, p, α)[1])
end
plot(experiments, qcvar_results, label="qCVaR", xaxis=:log, yaxis=:log, legend=:topleft)
plot!(experiments, cvar_results, label="CVaR", xaxis=:log, yaxis=:log, legend=:topleft)
plot!(title="qCVaR vs CVaR", xlabel="n", ylabel="Time (s)")
savefig("code/res.png")
println("Done!")



