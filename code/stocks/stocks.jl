include("../loop_cvar.jl")
include("../tvar.jl")
using Base.Threads
# Time to plot
using Random
using Dates
using DataFrames
using CSV
using RobustMDPs
using ProgressBars
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
  start = time_ns()
  expectation = sum(tmpx .* tmpp)
  expectation_time = (time_ns() - start) * 1e-6
  local δ = abs(slow_cvar_result - fast_cvar_result)
  if δ >= 1e-6
    println("CVaR: $slow_cvar_result, qCVaR: $fast_cvar_result, diff: $δ")
    error("Results are not equal!")
  end
  (slow_cvar_time=slow_time, fast_cvar_time=fast_time, var_time=var_time,
    qvar_time=qvar_time, tvar_time=tvar_time, qtvar_time=qtvar_time, expectation_time=expectation_time)
end

csv_path = "./stocks/spy_data.csv"
df = CSV.File(csv_path) |> DataFrame
println("Data loaded")
println("Number of rows: ", size(df, 1))
window = 10
trials = 5
results = Vector{NamedTuple{(:n, :cvar, :qcvar, :var, :qvar, :tvar, :qtvar, :expectation),Tuple{Int64,Float64,Float64,Float64,Float64,Float64,Float64,Float64}}}()
for i in ProgressBar(range(1, stop=size(df, 1)))
  GC.enable(false)
  # println("Processing row: ", i)
  # Get the data for the current window
  row = df[i, :]
  if ismissing(row[:Mean]) || ismissing(row[:Std])
    # println("Row $i is missing data, skipping")
    continue
  end
  μ = row[:Mean]
  σ = row[:Std]
  # @show row
  lower_return = μ - 4 * σ
  upper_return = μ + 4 * σ
  x = collect(range(lower_return, stop=upper_return, length=Int(1e4)))
  shuffle!(x) #omg need to shuffle it so that its fair
  dist = Normal(μ, σ)
  p = pdf.(dist, x)
  p ./= sum(p)
  α = 0.95
  # Run the experiment 'trials' times to get a better estimate of the time
  run_one_experiment(x, p, α) # burn one for julia
  for j in 1:trials
    # println("Running trial $j")
    # Run the experiment
    c, qc, v, qv, t, qt, e = run_one_experiment(x, p, α)
    # @show c, qc, v, qv, t, qt, e
    # Append the results to the results vector
    push!(results, (n=i,
      cvar=c,
      qcvar=qc,
      var=v,
      qvar=qv,
      tvar=t,
      qtvar=qt,
      expectation=e))
  end
  GC.enable(true)
  x = nothing
  p = nothing
  GC.gc()
end
# Save the DataFrame
results_df = DataFrame(results)
CSV.write("./stocks/stock_matchup.csv", results_df)

# function whole_experiment(risk_measure, fn)
#   runtime = []
#
#   for i in ProgressBar(range(1, stop=size(df, 1)))
#     row = df[i, :]
#     if ismissing(row[:Mean]) || ismissing(row[:Std])
#       # println("Row $i is missing data, skipping")
#       continue
#     end
#     μ = row[:Mean]
#     σ = row[:Std]
#     # @show row
#     lower_return = μ - 4 * σ
#     upper_return = μ + 4 * σ
#     x = collect(range(lower_return, stop=upper_return, length=Int(1e4)))
#     shuffle!(x) #omg need to shuffle it so that its fair
#     dist = Normal(μ, σ)
#     p = pdf.(dist, x)
#     p ./= sum(p)
#     α = 0.95
#     # Run the experiment 'trials' times to get a better estimate of the time
#     for _ in 1:trials
#       # println("Running trial $j")
#       # Run the experiment
#       start = time_ns()
#       fn(x, p, α)
#       # @show c, qc, v, qv, t, qt, e
#       # Append the results to the results vector
#       push!(runtime, (time_ns() - start) * 1e-6)
#     end
#   end
#   println("Risk $risk_measure, meantime: $(mean(runtime))")
# end
# whole_experiment("CVaR", (x, p, α) -> CVaR(x, p, α, check_inputs=false).value)
# whole_experiment("qCVaR", (x, p, α) -> qCVaR!(x, p, α).value)
# whole_experiment("VaR", (x, p, α) -> VaR(x, p, α, check_inputs=false).value)
# whole_experiment("qVaR", (x, p, α) -> qql!(x, p, α).value)
# whole_experiment("TVaR", (x, p, α) -> worstcase_l1(x, p, α))
# whole_experiment("qTVaR", (x, p, α) -> TVaR!(x, p, α))
# whole_experiment("Expectation", (x, p, α) -> sum(x .* p))
