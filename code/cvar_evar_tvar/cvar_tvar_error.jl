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
Random.seed!(1234)

function run_one_experiment(x, p, α)
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  cvar = qCVaR!(tmpx, tmpp, α).value
  tmpx = deepcopy(x)
  tmpp = deepcopy(p)
  tvar = TVaR!(tmpx, tmpp, sqrt(-2log(2) * log(α)))
  (diff = abs(cvar - tvar))
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

println("Starting experiments")
# for dist in ["uniform", "sparse"]
for dist in ["uniform"]
  println("Running experiments for $dist")
  p_f = p_gen_func(dist) # returns a function that takes n and returns a probability distribution
  stop = Int(1e5)
  step = Int(1e2)
  start = step
  # Number of trials per experiment
  # One experiment is running the CVaR and qCVaR algorithms and collecting the time taken.
  trials = 1
  experiments = Int.(ceil.(range(start=start, stop=stop, step=step)))
  # need to "multiply" experiments vector by trials
  experiments = hcat(repeat(experiments, 1, trials)'...)[:]
  len = length(experiments)
  diffs = zeros(Float64, len)
  for i ∈ ProgressBar(1:len)
    GC.enable(false)
    n = experiments[i]
    # println("Experiment $i / $len --- n = $n")
    x = rand(Float64, n) .* 100
    p = p_f(n)
    α = 0.95
    d = run_one_experiment(x, p, α)
    diffs[i] = d
    GC.enable(true)
    x = nothing
    p = nothing
    GC.gc()
  end
  # Save the DataFrame
  CSV.write("./cvar_evar_tvar/diffs_qEVaR_bound_$dist.csv",
    DataFrame(n=experiments,
      diff=diffs,
    )
  )
end
