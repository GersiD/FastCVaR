#!/bin/bash

# ensure our cwd ends with /code
if [ "${PWD##*/}" != "code" ]; then
  echo "Please run this script from the code directory"
  exit 1
fi

# ensure ./plots/cvar_vs_qcvar.csv does not exist if it does, delete it
echo "Removing ./plots/cvar_vs_qcvar.csv if it exists"
if [ -f ./plots/cvar_vs_qcvar.csv ]; then
  rm -i ./plots/cvar_vs_qcvar.csv
fi
# ensure no png or pdf files exist in the plots directory
echo "Removing all png and pdf files in the plots directory"
rm ./plots/*.png
rm ./plots/*.pdf

# run the experiment to get the csv in the plots directory
echo "Running the experiments"
julia -t 32 --project=. ./cvar_vs_qcvar_experiment.jl
if [ $? -ne 0 ]; then
  echo "Experiment failed"
  exit 1
fi

# run the plotter to generate the plot
echo "Generating the plot"
source ./plots/venv/bin/activate
python ./plots/plot.py
if [ $? -ne 0 ]; then
  echo "Plotting failed"
  exit 1
fi

echo "Done"
