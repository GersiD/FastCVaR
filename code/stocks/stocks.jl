include("../loop_cvar.jl")
include("../tvar.jl")
using DataFrames
using CSV
using ProgressBars
using Dates
using RobustMDPs
using Distributions

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
  slow_cvar_result = CVaR(tmpx, tmpp, α).value
  slow_time = (time_ns() - start)
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  fast_cvar_result = qCVaR!(tmpx, tmpp, α).value
  fast_time = (time_ns() - start)
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  VaR(tmpx, tmpp, α).value
  var_time = (time_ns() - start)
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  qql!(tmpx, tmpp, α).value
  qvar_time = (time_ns() - start)
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  worstcase_l1(tmpx, tmpp, α)
  tvar_time = (time_ns() - start)
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  start = time_ns()
  TVaR!(tmpx, tmpp, α)
  qtvar_time = (time_ns() - start)
  local δ = abs(slow_cvar_result - fast_cvar_result)
  if δ >= 1e-6
    println("CVaR: $slow_cvar_result, qCVaR: $fast_cvar_result, diff: $δ")
    error("Results are not equal!")
  end
  (cvar=slow_time, qcvar=fast_time, var=var_time,
    qvar=qvar_time, tvar=tvar_time, qtvar=qtvar_time)
end

csv_path = "./stocks/spy_data.csv"
df = CSV.File(csv_path) |> DataFrame
println("Data loaded")
println("Number of rows: ", size(df, 1))
window = 10
trials = 10
results = Vector{NamedTuple{(:n, :cvar, :qcvar, :var, :qvar, :tvar, :qtvar),Tuple{Int64,Float64,Float64,Float64,Float64,Float64,Float64}}}()
for i in range(1, stop=size(df, 1))
  println("Processing row: ", i)
  # Get the data for the current window
  row = df[i, :]
  if ismissing(row[:Mean]) || ismissing(row[:Std])
    println("Row $i is missing data, skipping")
    continue
  end
  μ = row[:Mean]
  σ = row[:Std]
  # @show row
  lower_return = μ - 3 * σ
  upper_return = μ + 3 * σ
  x = collect(lower_return:0.01:upper_return)
  dist = Normal(μ, σ)
  p = pdf.(dist, x)
  p ./= sum(p)
  α = 0.95
  # Run the experiment 'trials' times to get a better estimate of the time
  run_one_experiment(x, p, α) # burn one for julia
  for j in 1:trials
    # println("Running trial $j")
    # Run the experiment
    results_trial = run_one_experiment(x, p, α)
    # Append the results to the results vector
    push!(results, (n=i,
      cvar=results_trial.cvar,
      qcvar=results_trial.qcvar,
      var=results_trial.var,
      qvar=results_trial.qvar,
      tvar=results_trial.tvar,
      qtvar=results_trial.qtvar))
  end
end
# Save the DataFrame
results_df = DataFrame(results)
CSV.write("./plots/stock_matchup.csv", results_df)
