include("loop_cvar.jl")
using Base.Threads
# Time to plot
using Random
using Dates
Random.seed!(1234)

start = 5
stop = 100000000
step = 1000000
experiments = range(start=start, stop=stop, step=step)
len = length(experiments)
qcvar_results = Float64[len]
cvar_results = Float64[len]
# @threads :dynamic for i ∈ 1:len
for i ∈ 1:len
  n = Int(ceil(experiments[i]))
  println("Experiment $i / $len --- n = $n")
  x = rand(Float64, n) .* 100
  p = rand(Float64, n)
  p ./= sum(p)
  α = 0.6
  GC.enable(false)
  local start = now()
  slow_cvar_result = CVaR(deepcopy(x), p, α).value
  cvar_results[i] = (now() - start).value
  start = now()
  fast_cvar_result = qCVaR!(deepcopy(x), p, α).value
  qcvar_results[i] = (now() - start).value
  local δ = abs(slow_cvar_result - fast_cvar_result)
  if δ >= 1e-6
    println("CVaR: $slow_cvar_result, qCVaR: $fast_cvar_result, diff: $δ")
    error("Results are not equal!")
  end
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
