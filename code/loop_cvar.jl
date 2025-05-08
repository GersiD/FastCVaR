using RiskMeasures

function swap!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, i::Int, j::Int)
  i == j && return # NOTE: Yes the speedup is worth it just from this one line 4ns faster
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
  partition!(x, 2, 1, 4) # (2, 4)
"""
function partition!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, f::Int, b::Int)
  pivot_ind = f + Int(ceil((b - f) / 2))
  pivot_val = vals[pivot_ind]
  lt = f
  eq = f
  gt = b
  # @show lt, eq, gt
  @inbounds while eq <= gt
    if vals[eq] < pivot_val
      @inbounds swap!(vals, p, eq, lt)
      lt += 1
      eq += 1
    elseif vals[eq] > pivot_val
      @inbounds swap!(vals, p, eq, gt)
      gt -= 1
    else # vals[eq] == pivot_val
      eq += 1
    end
    # @show lt, eq, gt
  end
  @assert vals[gt] == pivot_val
  return (lt=lt, gt=gt - 1)
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
  @inbounds while j - i >= 1
    ind, gt = partition!(vals, p, i, j)
    tail::Float64 = sum(view(p, i:gt))
    α < tail ? begin
      j = gt
    end : begin
      i = gt + 1
      α -= tail
    end # Cut off half of the random variable
  end
  return (value=vals[i], index=i)
end

function qCVaR!(vals::AbstractVector{<:Real}, p::AbstractVector{<:Real}, α::Real)
  T = eltype(p)
  # handle special cases
  if iszero(α)
    minval = essinf(vals, p; check_inputs=false)
    minpmf = zeros(T, length(p))
    minpmf[minval.index] = one(T)
    return (value=minval.value, pmf=minpmf)
  elseif isone(α)
    return (value=vals' * p, pmf=Vector(p))
  end
  q, qind = qql!(vals, p, α)

  # From here on: α ∈ (0,1)
  value = zero(T)           # CVaR value
  pc = zeros(T, length(p))  # this is the new distribution
  p_left = one(T)           # probabilities left for allocation
  α̂ = α                    # probabilities to allocate

  @inbounds for i ∈ 1:qind
    # if vals[i] <= q # all elements up to qind are less than or equal to q by def of partition
    # update index's probability and probability left to sum to 1.0
    increment = min(p[i] / α̂, p_left)
    pc[i] = increment
    value += increment * vals[i]
    p_left -= increment
    p_left ≤ zero(p_left) && break
    # end
  end
  return (value=value, pmf=pc)
end
