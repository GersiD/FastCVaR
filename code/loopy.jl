include("loop_cvar.jl")
using Base.Threads
# Time to plot
using Plots
using Random
Random.seed!(1234)

start = 5
stop = 100000000
step = 1000000
x = rand(Int64, stop)
p = rand(Float64, stop)
p ./= sum(p)
longest = @elapsed CVaR_e(x, p, 0.5)
print("Longest takes $longest s")
# experiments = range(start=5, stop=10^magnitude, length=len)
experiments = range(start=start, stop=stop, step=step)
len = length(experiments)
qcvar_results = Float64[]
cvar_results = Float64[]
int(x) = Int(ceil(x))
# @threads :dynamic for i ∈ 1:len
for i ∈ 1:len
  n = int(experiments[i])
  println("Experiment $i / $len --- n = $n")
  x = rand(Int64, n)
  p = rand(Float64, n)
  p ./= sum(p)
  α = 0.6
  GC.enable(false)
  push!(qcvar_results, @elapsed qCVaR!(x, p, α))
  push!(cvar_results, @elapsed CVaR_e(x, p, α))
  GC.enable(true)
  x = nothing
  p = nothing
  GC.gc()
end
plot(experiments[5:length(qcvar_results)], qcvar_results[5:end], label="qCVaR", xaxis=:log, yaxis=:log, legend=:topleft)
plot!(experiments[5:length(cvar_results)], cvar_results[5:end], label="CVaR", xaxis=:log, yaxis=:log, legend=:topleft)
plot!(title="qCVaR vs CVaR", xlabel="n", ylabel="Time (s)")
savefig("results/res_log.png")
plot(experiments[5:length(qcvar_results)], qcvar_results[5:end], label="qCVaR", legend=:topleft)
plot!(experiments[5:length(cvar_results)], cvar_results[5:end], label="CVaR", legend=:topleft)
plot!(title="qCVaR vs CVaR", xlabel="n", ylabel="Time (s)")
savefig("results/res_linear.png")
println("Done!")

