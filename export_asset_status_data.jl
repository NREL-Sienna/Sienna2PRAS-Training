# Imports
using PowerSystemCaseBuilder
using SIIP2PRAS
using PRAS
using PowerSystems
const PSY = PowerSystems
const PSCB = PowerSystemCaseBuilder

# Load the PRAS System we generated earlier
rts_da_pras_sys = PRAS.SystemModel(joinpath("Data","rts.pras"));

# Run Monte-Carlo Analysis for "num_runs" samples and export "num_scenarios" of scenarios sorted based on 
# sample unserved energy in CSV format
if (~isdir(joinpath("Data","Asset_Status_Export")))
    mkpath(joinpath("Data","Asset_Status_Export"))
end

generate_csv_outage_profile(rts_da_pras_sys,
                        location = joinpath("Data","Asset_Status_Export"),
                        num_runs=100,num_scenarios=1)

# Run Monte-Carlo Analysis for "num_runs" samples and export "num_scenarios" of scenarios sorted based on 
# sample unserved energy by adding time series data to the corresponding component in Sienna System

# Building the RTS-GMLC System usinng PSCB
sys_rts_da = PSCB.build_system(PSISystems, "modified_RTS_GMLC_DA_sys");

generate_outage_profile(rts_da_pras_sys,sys_rts_da,
                        location = joinpath("Data","Asset_Status_Export"),
                        num_runs=100,num_scenarios=1)

# Check "avaialability" time series is added to the component
sys_with_avail_ts = PSY.System("/Users/sdhulipa/Desktop/OneDrive - NREL/Projects/GridIndia-Demo/sienna2pras/Availability_Data_Export/data/Generated-Outage-Profile-JSON/31f1c903-d8ea-4f34-a71f-6c991a1809f8/19-Aug-23-22-3-14/1.json", 
time_series_read_only = true, runchecks = false);

gen = first(PSY.get_components(PSY.Generator,sys_with_avail_ts))
PSY.get_time_series_values(PSY.SingleTimeSeries, gen,"availability")