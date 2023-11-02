# Surya Dhulipala, NREL
# Generating PRAS System from a Sienna PowerSystems.jl System using Sienna2PRAS

# Imports
using PowerSystemCaseBuilder
using SIIP2PRAS
using PowerSystems
const PSY = PowerSystems
const PSCB = PowerSystemCaseBuilder

# Building the RTS-GMLC System usinng PSCB
sys_rts_da = PSCB.build_system(PSISystems, "modified_RTS_GMLC_DA_sys");

# Removing the Forecats from the System built
PSY.remove_time_series!(sys_rts_da,PSY.DeterministicSingleTimeSeries)

# Sienna PowerSystems.jl System components don't have outage data fields (Forced Outage Rate & Mean Time to Recover) - 
# so Sienna2PRAS looks for the fields "outage_probability" and "recovery_probability" in the ext of components in the
# System

# Sienna2PRAS
# Using ERCOT Default rates when you don't have any historical FOR, MTTR data specific to your System
# If your System doens't have outage data, set outage_flag to false and ERCOT historical rates for the (fuel, prime_mover) combination
# available will be used, otherwise a default of (0.0, 1.0) for "outage_probability" and "recovery_probability" is assumed
# availability_flag is used to indicate if you want to take Sienna asset avaialability into account

# How to check if your SYstem has these fields?
# first(PSY.get_components(PSY.ThermalGen, sys_rts_da))

# Running Sienna2PRAS
rts_da_pras_sys = SIIP2PRAS.make_pras_system(sys_rts_da,system_model="Zonal",aggregation="Area",outage_flag=false,lump_pv_wind_gens=false,availability_flag=true);

# You can lump PV & Wind Plants in a region if you don't have outage data
rts_da_pras_sys = SIIP2PRAS.make_pras_system(sys_rts_da,system_model="Zonal",aggregation="Area",outage_flag=false,lump_pv_wind_gens=true,availability_flag=true);

# You can also add line outage data

# Adding Line Outages
lines = collect(PSY.get_components((x -> ~in(typeof(x), [PSY.TapTransformer, PSY.Transformer2W,PSY.PhaseShiftingTransformer]) && PSY.get_available(x)),PSY.Branch, sys_rts_da));
regional_lines = filter(x -> (PSY.get_name(PSY.get_area(PSY.get_from_bus(x))) != PSY.get_name(PSY.get_area(PSY.get_to_bus(x)))),lines);

for line in regional_lines
    ext = PSY.get_ext(line)
    ext["outage_probability"] = 0.004629629629629629
    ext["recovery_probability"] = 0.041666666666666664
end

rts_da_pras_sys = SIIP2PRAS.make_pras_system(sys_rts_da,system_model="Zonal",aggregation="Area",outage_flag=false,lump_pv_wind_gens=true,availability_flag=true);

# For instance, if you have system-specific historical outage data, you can do something like this,

# More Imports
# Processing outage data to be able to ingest into PowerSystems.jl System

using CSV
using DataFrames
using Statistics
using Random
using PRAS

##############################################
# Converting FOR and MTTR to λ and μ
##############################################
function outage_to_rate(for_gen::Float64, mttr::Int64)
    
    if (for_gen >1.0)
        for_gen = for_gen/100
    end

    if (mttr != 0)
        μ = 1 / mttr
    else
        μ = 0.0
    end
    λ = (μ * for_gen) / (1 - for_gen)
    #λ = for_gen

    return (λ = λ, μ = μ)
end

function PSY.get_fuel(gen::Union{PSY.HydroDispatch, PSY.RenewableDispatch,PSY.GenericBattery, PSY.RenewableFix})
    return PSY.get_prime_mover(gen)
end

##############################################
# Adding outage_probability and recovery_probability in the ext of components
##############################################
function add_outage_info_to_ext!(gen::Union{<:PSY.Generator,<:PSY.Storage},tup::NamedTuple{(:λ, :μ), Tuple{Float64, Float64}})
    ext = PSY.get_ext(gen)
    ext["outage_probability"] = getfield(tup,:λ)
    ext["recovery_probability"] = getfield(tup,:μ)

    return gen
end

# Analysis of EPA Availability Data
unit_availability_data = CSV.read(joinpath("Data","unit_availability.csv"), DataFrames.DataFrame);


fuel_mapping_dict = 
Dict(
(PSY.PrimeMovers.HY, PSY.PrimeMovers.HY) => "Hydro",
(PSY.PrimeMovers.WT, PSY.PrimeMovers.WT) => "Onshore Wind",
 (PSY.PrimeMovers.PVe, PSY.PrimeMovers.PVe) => "Solar PV",
 (PSY.ThermalFuels.NATURAL_GAS, PSY.PrimeMovers.CT) => "Combustion Turbine",
 (PSY.ThermalFuels.NATURAL_GAS, PSY.PrimeMovers.CC) => "Combined Cycle",
 (PSY.ThermalFuels.COAL, PSY.PrimeMovers.ST) => "Coal Steam",
 (PSY.ThermalFuels.NUCLEAR, PSY.PrimeMovers.ST) => "Nuclear"
)

FOR_dict = Dict()
for plant_type in unique(values(fuel_mapping_dict))
    plant_type_rows = filter(x -> x["Plant Type"] == plant_type, unit_availability_data)

    push!(FOR_dict, plant_type => (mean = (1.0 - Statistics.mean(plant_type_rows[!,"Annual Availability"])), std = Statistics.std(plant_type_rows[!,"Annual Availability"])))
end

generators = collect(PSY.get_components(PSY.Generator, sys_rts_da));

for gen in generators
    forced_outage_rate = FOR_dict[fuel_mapping_dict[(PSY.get_fuel(gen),PSY.get_prime_mover(gen))]]
    mttr = 24

    draw_1 = Random.rand(collect(range(1,5,step = 0.1)))

    f_o_r = (getfield(forced_outage_rate,:mean) + (draw_1*getfield(forced_outage_rate,:std)))

    tup = outage_to_rate(f_o_r,mttr)
    add_outage_info_to_ext!(gen,tup)

end

rts_da_pras_sys = SIIP2PRAS.make_pras_system(sys_rts_da,system_model="Zonal",aggregation="Area",outage_flag=true,lump_pv_wind_gens=false,availability_flag=true);

# Saving the .pras System.
PRAS.savemodel(rts_da_pras_sys,joinpath("Data","rts.pras"), string_length =100, verbose = true, compression_level = 9)