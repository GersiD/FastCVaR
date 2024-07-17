using RiskMeasures

function swap!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, i::Int, j::Int)
  vals[i], vals[j] = vals[j], vals[i]
  p[i], p[j] = p[j], p[i]
end

function partition!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, f::Int, b::Int)
  pivot = f + Int(ceil((b - f) / 2))
  pivot_val = vals[pivot]
  @inbounds swap!(vals, p, pivot, b) # move pivot to back
  store_index = f
  @inbounds for i ∈ range(f, b - 1)
    if vals[i] < pivot_val
      swap!(vals, p, store_index, i)
      store_index += 1
    end
  end
  @inbounds swap!(vals, p, b, store_index)
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
  @inbounds while j - i >= 1
    ind = partition!(vals, p, i, j) - 1
    tail::Float64 = sum(view(p, 1:ind))
    α < tail ? j = ind : i = ind + 1 # Cut off half of the random variable
  end
  return vals[i]
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

  @inbounds for i ∈ eachindex(vals)
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
