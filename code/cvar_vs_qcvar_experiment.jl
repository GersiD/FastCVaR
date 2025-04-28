include("loop_cvar.jl")
include("tvar.jl")
using Base.Threads
# Time to plot
using Random
using Dates
using DataFrames
using CSV
using RobustMDPs
using ProgressBars
Random.seed!(1234)

"""
  run_one_experiment(n::Int, x, p, α)

  Run one experiment with n samples and random variable *x* with probability distribution 
  *p* and risk level *α* and return the results.

Returns:
  NTuple{2, Float64}:
    slow_cvar_result: The CVaR time taken result.
    fast_cvar_result: The qCVaR time taken result.
"""
function run_one_experiment(x, p, α)
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  local start = time_ns()
  slow_cvar_result = CVaR(tmpx, tmpp, α, check_inputs=false).value
  slow_time = (time_ns() - start) * 1e-6
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  fast_cvar_result = qCVaR!(tmpx, tmpp, α).value
  fast_time = (time_ns() - start) * 1e-6
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  VaR(tmpx, tmpp, α, check_inputs=false).value
  var_time = (time_ns() - start) * 1e-6
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  qql!(tmpx, tmpp, α).value
  qvar_time = (time_ns() - start) * 1e-6
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  worstcase_l1(tmpx, tmpp, α)
  tvar_time = (time_ns() - start) * 1e-6
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  TVaR!(tmpx, tmpp, α)
  qtvar_time = (time_ns() - start) * 1e-6
  local δ = abs(slow_cvar_result - fast_cvar_result)
  if δ >= 1e-6
    println("CVaR: $slow_cvar_result, qCVaR: $fast_cvar_result, diff: $δ")
    error("Results are not equal!")
  end
  (slow_cvar_time=slow_time, fast_cvar_time=fast_time, var_time=var_time,
    qvar_time=qvar_time, tvar_time=tvar_time, qtvar_time=qtvar_time)
end

function p_gen_func(dist)
  if dist == "uniform"
    return n -> fill(1 / n, n)
  elseif dist == "sparse"
    return n -> begin
      p = zeros(Float64, n)
      inds = unique(rand(1:n, Int(ceil(log(n)))))
      p[inds] .= 1 / length(inds)
      p
    end
  else
    error("Unknown distribution")
  end
end

# @threads :dynamic for i ∈ 1:len
# TODO: add var and tvar speedup
# TODO: Other domain? 
#   -- nested risk?
#   -- SA robust?
#   -- Portfolio optimization?
#   -- What case would fast cvar matter
#   -- different distributions for p
#     -- uniform
#     -- sparse = pick log(n) random indices and set to 1 normalize
# -- 6 plots for each of the tvar cvar var
println("Starting experiments")
# for dist in ["uniform", "sparse"]
for dist in ["uniform"]
  println("Running experiments for $dist")
  p_f = p_gen_func(dist) # returns a function that takes n and returns a probability distribution
  stop = 10000000 # 10 million
  step = 1000000 # 100 thousand
  start = step
  # Number of trials per experiment
  # One experiment is running the CVaR and qCVaR algorithms and collecting the time taken.
  trials = 10
  experiments = Int.(ceil.(range(start=start, stop=stop, step=step)))
  # need to "multiply" experiments vector by trials
  experiments = hcat(repeat(experiments, 1, trials)'...)[:]
  len = length(experiments)
  qcvar_results = zeros(Float64, len)
  cvar_results = zeros(Float64, len)
  var_results = zeros(Float64, len)
  qvar_results = zeros(Float64, len)
  tvar_results = zeros(Float64, len)
  qtvar_results = zeros(Float64, len)
  for i ∈ ProgressBar(1:len)
    GC.enable(false)
    n = experiments[i]
    # println("Experiment $i / $len --- n = $n")
    x = rand(Float64, n) .* 100
    p = p_f(n)
    α = 0.6
    c, qc, v, qv, t, qt = run_one_experiment(x, p, α)
    cvar_results[i] = c
    qcvar_results[i] = qc
    var_results[i] = v
    qvar_results[i] = qv
    tvar_results[i] = t
    qtvar_results[i] = qt
    GC.enable(true)
    x = nothing
    p = nothing
    GC.gc()
  end
  # Save the DataFrame
  CSV.write("./plots/cvar_vs_qcvar_$dist.csv",
    DataFrame(n=experiments,
      cvar=cvar_results,
      qcvar=qcvar_results,
      var=var_results,
      qvar=qvar_results,
      tvar=tvar_results,
      qtvar=qtvar_results
    )
  )
end
