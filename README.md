# Sienna2PRAS-Training
Trainings for Sienna2PRAS

This is the Sienna to PRAS Training Repository! This repository offers a comprehensive set of training exercises to help you become proficient in using Sienna2PRAS for various applications.

**Getting Started**

Before you delve into these exercises, we highly recommend exploring the tutorials available in the [PowerSystems.jl](https://nrel-sienna.github.io/PowerSystems.jl/stable/) and [PRAS.jl](https://nrel.github.io/PRAS/) documentation.

**Software Requirement**
These Training scripts require Julia version 1.6.x and above and PowerSystems.jl at 2.x or higher.
Before running any of the training scripts, to setup the julia env you will have to run the following commands. 
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

**NOTE: Because Sienna2PRAS isn't currently registered, you have to add Sienna2PRAS to env separately using
```julia
Pkg.add("https://github.com/NREL-Sienna/Sienna2PRAS.git")
```

If the environment setup above fails, you can use 

```julia
] activate . 
] add https://github.com/NREL-Sienna/Sienna2PRAS.git,PowerSystemCaseBuilder@1.1.0,PRAS,CSV,DataFrames,PowerSystems,Random,Statistics
```

**Training Exercises**

Here's a structured sequence for your training:

1. **System Generation (`generate_pras_system.jl`):** This outlines generation of a PRAS System from a Sienna System and various nuances of outage data

2. **Asset Status Export (`export_asset_status_data.jl`):** This outlines export of asset status from PRAS runs in various formats.

## Acknowledgments
This code was developed as part of G-PST project. 

The developer is : [Surya Dhulipala](https://github.com/scdhulipala).

Please reach out if you have any questions!