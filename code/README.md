# Code for the Project "name"  <!-- TODO: name -->


## Structure
The code is organized into the following directories:
-  archive/ # Code that was just for testing and experimenting with our ideas, not important
-  comonotone-graphs/ # Code to test what risk measures are comonotone, and what their sub-modular functions are
-  cvar/ # Rust code to prove a point, Not important
-  cvar_evar_tvar/ # Code to test and plot CVAR >= EVAR >= TVAR
-  plots/ # Plots for the paper
-  small_cases/ # Small cases to test performance of the algorithms
-  stocks/ # Stock market experiments
-  test/ # Tests for the new methods

## How to run
```bash
julia --project=./ -e 'using Pkg; Pkg.instantiate()'
```

## Notes for the Particular Reader
You will notice alot of shared code between directories, this code does not follow good software development practices, and is not meant to be used as a library. It is just a collection of scripts that we used to test our ideas.

Please use [this libary developed by our team instead](https://github.com/RiskAverseRL/MDPs.jl).
