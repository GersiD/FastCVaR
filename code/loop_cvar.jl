using RiskMeasures

function swap!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, i::Int, j::Int)
  i == j && return # TODO: Test speedup I am curious
  vals[i], vals[j] = vals[j], vals[i]
  p[i], p[j] = p[j], p[i]
end

"""
Function to partition the values in `vals` according to the pivot value `pivot_val`.
Returns:
  A tuple (lt::Int, gt::Int) where `lt` is the index of the start of the eq partition
  and `gt` is the index of the start of the right partition, the difference between the two 
  contain values equal to the pivot.
  x = [1,2,2,3]
  prtition!(x, 2, 1, 4) # (2, 4)
"""
function partition!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, f::Int, b::Int)
  pivot_ind = f + Int(ceil((b - f) / 2))
  pivot_val = vals[pivot_ind]
  lt = f
  eq = f
  gt = b
  # @show lt, eq, gt
  while eq <= gt
    if vals[eq] < pivot_val
      swap!(vals, p, eq, lt)
      lt += 1
      eq += 1
    elseif vals[eq] > pivot_val
      swap!(vals, p, eq, gt)
      gt -= 1
    else # vals[eq] == pivot_val
      eq += 1
    end
    # @show lt, eq, gt
  end
  return (lt=lt - 1, gt=gt)
end


## Quick Quantile (loopy version)
function qql!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, α::Real)
  if iszero(α) # minimum
    return essinf(vals, p; check_inputs=true)
  elseif isone(α) # maximum (it is unbounded)
    return (value=typemax(eltype(p)), index=length(vals))
  end
  i = 1
  j = length(vals)
  gt = 1
  # @show i, j
  @inbounds while j - i >= 1
    lt, gt = partition!(vals, p, i, j)
    ind = lt
    tail::Float64 = sum(view(p, 1:ind))
    α <= tail ? j = ind : i = ind + (gt - lt) # Cut off half of the random variable
  end
  return (value=vals[i], index=gt)
end

function qCVaR!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, α::Real)
  T = eltype(p)
  # handle special cases
  if iszero(α)
    minval = essinf(vals, p; check_inputs=false)
    minpmf = zeros(T, length(p))
    minpmf[minval.index] = one(T)
    return minval.value
  elseif isone(α)
    return vals' * p
  end
  q, qind = qql!(vals, p, α)

  # From here on: α ∈ (0,1)
  value = zero(T)           # CVaR value
  p_left = one(T)           # probabilities left for allocation
  α̂ = α                    # probabilities to allocate

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
