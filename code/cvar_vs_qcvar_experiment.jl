include("loop_cvar.jl")
using Base.Threads
# Time to plot
using Random
using Dates
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
  local start = now()
  slow_cvar_result = CVaR(deepcopy(x), p, α).value
  slow_time = (now() - start).value
  start = now()
  fast_cvar_result = qCVaR!(deepcopy(x), p, α).value
  fast_time = (now() - start).value
  local δ = abs(slow_cvar_result - fast_cvar_result)
  if δ >= 1e-6
    println("CVaR: $slow_cvar_result, qCVaR: $fast_cvar_result, diff: $δ")
    error("Results are not equal!")
  end
  (slow_cvar_time=slow_time, fast_cvar_time=fast_time)
end

stop = 100000000
step = 1000000
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
# @threads :dynamic for i ∈ 1:len
for i ∈ 1:len
  GC.enable(false)
  n = experiments[i]
  println("Experiment $i / $len --- n = $n")
  x = rand(Float64, n) .* 100
  p = rand(Float64, n)
  p ./= sum(p)
  α = 0.6
  s, f = run_one_experiment(x, p, α)
  qcvar_results[i] = f
  cvar_results[i] = s
  GC.enable(true)
  x = nothing
  p = nothing
  GC.gc()
end
# Create a DataFrame
using DataFrames
df = DataFrame(n=experiments, cvar=cvar_results, qcvar=qcvar_results)
# Save the DataFrame
using CSV
CSV.write("./plots/cvar_vs_qcvar.csv", df)
