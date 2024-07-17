include("loop_cvar.jl")
using Base.Threads
# Time to plot
using Plots
using Random
Random.seed!(1234)

magnitude = 10
len = 1000
# experiments = range(start=5, stop=10^magnitude, length=len)
experiments = range(start=1000, stop=1000000, step=1000)
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
  α = rand(Float64)
  push!(qcvar_results, @elapsed qCVaR!(x, p, α))
  push!(cvar_results, @elapsed CVaR_e(x, p, α))
  x = nothing
  p = nothing
end
plot(experiments[5:length(qcvar_results)], qcvar_results[5:end], label="qCVaR", xaxis=:log, yaxis=:log, legend=:topleft)
plot!(experiments[5:length(cvar_results)], cvar_results[5:end], label="CVaR", xaxis=:log, yaxis=:log, legend=:topleft)
plot!(title="qCVaR vs CVaR", xlabel="n", ylabel="Time (s)")
savefig("code/res.png")
println("Done!")

