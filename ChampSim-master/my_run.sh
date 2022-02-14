#!/bin/bash

# Working-
# Place all the required LLC Replacement Policies in "replacement/all_variants/" folder
# The script copies the selected llc_replacement_policy and pastes it in UUT.cc
# champsim_config.json already has UUT chosen as the LLC Replacement Policy
# All the llc_replacement_policy in the list are compiled

# changes required to hawkeye_final and ship++ to make them compatible with the new ChampSim
# #include "../inc/champsim_crc2.h" -> comment out
#
# Add the following
# #include <algorithm>
# #include <iterator>
# #include "cache.h"
# #include "util.h"
#
# Change function interfaces to 
# -> CACHE::initialize_replacement()
# -> CACHE::find_victim(uint32_t cpu, uint64_t instr_id, uint32_t set, const BLOCK* current_set, uint64_t ip, uint64_t full_addr, uint32_t type)
# the second argument is new, add it and for the rest of the arguments use the old names
# -> CACHE::update_replacement_state(uint32_t cpu, uint32_t set, uint32_t way, uint64_t full_addr, uint64_t ip, uint64_t victim_addr, uint32_t type, uint8_t hit)
# -> CACHE::replacement_final_stats()
# For ship++ -> #define MAX_LLC_SETS NUM_CORE*2048
# -> int LLC_SETS = (get_config_number() <= 2) ? 2048 : MAX_LLC_SETS; -> int LLC_SETS = MAX_LLC_SETS;
# -> #define NUM_CORE 1

# All the binaries are run for the traces in allTraces.
# results_raw - accumulates the raw outputs of the runs
# results_mpki - accumulates only the mpki from all traces for a replacement policy
# results_mpki_geo - accumulates the (Geometric and arithmetic) mean mpki of all traces for a replacement policy

# A c program is used for the calculation of the means to avoid loss of precision. The c program uses doubles.
# The program is compiled by the script. No need to do it seperately.

# 8 threads are running in parallel. If a run is killed the last 8 runs must be restarted.

# common commands:
# rm ./bin/*
# rm -r ./results_*
# make clean
# chmod +x my_run.sh

path_allTraces="/datasets/cs240c-wi22-a00-public/data/Assignment2/"

llc_replacement_policy=(
    # "lru"                                     # done - 1 (12:00 noon - 6:00 PM)
    # "hawkeye_final"                           # done - 1
    # "hawkeye_final_OPTGEN_VECTOR_SIZE_32"     # done - 3
    # "hawkeye_final_OPTGEN_VECTOR_SIZE_64"     # done - 2 (7:00 PM - 1:00 AM)
    # "hawkeye_final_OPTGEN_VECTOR_SIZE_256"    # done - 2
    # "hawkeye_final_OPTGEN_VECTOR_SIZE_512"    # done - 3
    # "hawkeye_final_SAMPLER_WAYS_2"            # done - 4 (7:00AM - 9:00 AM)
    # "hawkeye_final_SAMPLER_WAYS_4"            # done - 2
    # "hawkeye_final_SAMPLER_WAYS_16"           # done - 3 (1:00 AM - 6:30 AM)
    ## "hawkeye_final_SAMPLER_WAYS_32"          # Problem - SAMPLER_WAYS cannot be greater than 16
    # "hawkeye_final_netSize_16KB"              # done - 7
    # "hawkeye_final_netSize_64KB"              # done - 7
    # "hawkeye_final_maxRRPV_3"                 # done - 7
    # "hawkeye_final_maxRRPV_5"                 # done - 7
    # "hawkeye_final_maxRRPV_9"                 # done - 8
    # "hawkeye_final_maxRRPV_11"                # done - 9
    # "hawkeye_final_maxRRPV_15"                # done - 9
    # "ship++"                                  # done - 1
    # "ship++_maxSHCTR_5"                       # done - 5 (9:30AM - 7:30 PM)
    # "ship++_maxSHCTR_3"                       # done - 5
    # "ship++_maxSHCTR_9"                       # done - 5
    # "ship++_maxSHCTR_11"                      # done - 5
    # "ship++_SHCT_SIZE_12"                     # done - 6
    # "ship++_SHCT_SIZE_13"                     # done - 5 
    # "ship++_SHCT_SIZE_15"                     # done - 5
    # "ship++_SHCT_SIZE_16"                     # done - 6
    # "ship++_netSize_32KB"                     # done - 7
    # "ship++_netSize_64KB"                     # done - 7
    # "ship++_LEADER_8"                         # done - 10
    # "ship++_LEADER_16"                        # done - 10
    # "ship++_LEADER_32"                        # done - 10
    # "ship++_LEADER_128"                       # done - 10
    # "ship++_LEADER_256"                       # done - 10
    # "ship++_LEADER_512"                       # done - 10
    )

allTraces=(
    "GemsFDTD_109B"
    "GemsFDTD_712B"
    "GemsFDTD_716B"
    "astar_163B"
    "astar_23B"
    "astar_313B"
    "bzip2_183B"
    "bzip2_259B"
    "bzip2_281B"
    "cactusADM_1039B"
    "cactusADM_1495B"
    "cactusADM_734B"
    "calculix_2655B"
    "calculix_2670B"
    "calculix_3812B"
    "gcc_13B"
    "gcc_39B"
    "gcc_56B"
    "lbm_1004B"
    "lbm_564B"
    "lbm_94B"
    "leslie3d_1116B"
    "leslie3d_1186B"
    "leslie3d_94B"
    "libquantum_1210B"
    "libquantum_1735B"
    "libquantum_964B"
    "mcf_158B"
    "mcf_250B"
    "mcf_46B"
    "milc_360B"
    "milc_409B"
    "milc_744B"
    "omnetpp_17B"
    "omnetpp_340B"
    "omnetpp_4B"
    "perlbench_105B"
    "perlbench_135B"
    "perlbench_53B"
    "soplex_205B"
    "soplex_217B"
    "soplex_66B"
    "sphinx3_1339B"
    "sphinx3_2520B"
    "sphinx3_883B"
    "wrf_1212B"
    "wrf_1228B"
    "wrf_1650B"
    "zeusmp_100B"
    "zeusmp_300B"
    "zeusmp_600B")





function compile_all() {
    local -n llc_replacement_policy_array=$1
    
    echo "-----------------------------------"
    echo "-------- Started Compiling --------"
    echo "-----------------------------------"

    for i in ${!llc_replacement_policy_array[@]}; do
        echo "${i} Compiling: ${llc_replacement_policy_array[$i]}"
        cp ./replacement/all_variants/${llc_replacement_policy_array[$i]}.cc ./replacement/UUT/UUT.cc
        ./config.sh champsim_config.json
        make 1> /dev/null
        mv ./bin/champsim ./bin/${llc_replacement_policy_array[$i]}
    done
}

function compile_if() {
    local -n llc_replacement_policy_array=$1
    
    echo "-----------------------------------"
    echo "-------- Started Compiling --------"
    echo "-----------------------------------"

    for i in ${!llc_replacement_policy_array[@]}; do
        if test -f "./bin/${llc_replacement_policy_array[$i]}"; then
            echo "${i} Already Compiled: ${llc_replacement_policy_array[$i]}"
        else
            echo "${i} Compiling: ${llc_replacement_policy_array[$i]}"
            cp ./replacement/all_variants/${llc_replacement_policy_array[$i]}.cc ./replacement/UUT/UUT.cc
            ./config.sh champsim_config.json
            make 1> /dev/null
            mv ./bin/champsim ./bin/${llc_replacement_policy_array[$i]}
        fi
    done
}



# initialize a semaphore with a given number of tokens
open_sem() {
    mkfifo pipe-$$
    exec 3<>pipe-$$
    rm pipe-$$
    local i=$1
    for((;i>0;i--)); do
        printf %s 000 >&3
    done
}

# run the given command asynchronously and pop/push tokens
run_with_lock() {
    local x
    # this read waits until there is something to read
    read -u 3 -n 3 x && ((0==x)) || exit $x
    (
     ( "$@"; )
    # push the return code of the command to the semaphore
    printf '%.3d' $? >&3
    )&
}

function run() {
    local -n trace_list=$1
    local -n binaryName=$2
    local -n threadCount=$3
    local -n pathToTraces=$4

    echo "---------------------------------"
    echo "-------- Started Running --------"
    echo "---------------------------------"

    mkdir -p results_raw

    open_sem $threadCount
    for i in ${!binaryName[@]}; do
        echo "Binary $i: ${binaryName[$i]}"
        for j in ${!trace_list[@]}; do
            echo "Trace ${j}: ${trace_list[$j]}"
            run_with_lock ./bin/${binaryName[$i]} --warmup_instructions 10000000 --simulation_instructions 100000000 ${pathToTraces}${trace_list[$j]}.trace.xz &> results_raw/${binaryName[$i]}-${trace_list[$j]}.txt
        done
        echo " "
    done
    wait
}



function get_IPC() {
    local -n trace_list=$1
    local -n binaryName=$2

    declare -a ipc_array

    mkdir -p results_ipc
    mkdir -p results_ipc_mean
    gcc my_mean.c -o my_mean -lm

    for i in ${!binaryName[@]}; do
        echo "get_IPC - LLC Replacement Policy: ${binaryName[$i]}"
        for j in ${!trace_list[@]}; do
            path=./results_raw/${binaryName[$i]}-${trace_list[$j]}.txt
            lineNum="$(grep -n "CPU 0 cumulative IPC:" $path | head -n 1 | cut -d: -f1)"
            ipc_array[$j]=$(awk -v dataLine="$lineNum" 'NR==dataLine{print $5}' $path)
            echo "Trace No. ${j}: ${trace_list[$j]} - IPC: ${ipc_array[$j]}"
        done
        echo " "

        for j in ${!trace_list[@]}; do
            echo "${ipc_array[$j]}"
        done > ./results_ipc/${binaryName[$i]}.txt
        
        ./my_mean ./results_ipc/${binaryName[$i]}.txt > ./results_ipc_mean/${binaryName[$i]}.txt
    done

    rm my_mean
}


function get_MPKI() {
    local -n trace_list=$1
    local -n binaryName=$2

    declare -a mpki_array

    mkdir -p results_mpki
    mkdir -p results_mpki_mean
    gcc my_mean.c -o my_mean -lm

    for i in ${!binaryName[@]}; do
        echo "get_MPKI - LLC Replacement Policy: ${binaryName[$i]}"
        for j in ${!trace_list[@]}; do
            path=./results_raw/${binaryName[$i]}-${trace_list[$j]}.txt
            lineNum="$(grep -n "MPKI:" $path | head -n 1 | cut -d: -f1)"
            mpki_array[$j]=$(awk -v dataLine="$lineNum" 'NR==dataLine{print $8}' $path)
            echo "Trace No. ${j}: ${trace_list[$j]} - MPKI: ${mpki_array[$j]}"
        done
        echo " "

        for j in ${!trace_list[@]}; do
            echo "${mpki_array[$j]}"
        done > ./results_mpki/${binaryName[$i]}.txt

        ./my_mean ./results_mpki/${binaryName[$i]}.txt > ./results_mpki_mean/${binaryName[$i]}.txt
    done

    rm my_mean
}


function get_MPKI_LLC() {
    local -n trace_list=$1
    local -n binaryName=$2

    declare -a miss_array

    mkdir -p results_LLC_miss
    mkdir -p results_LLC_mpki_mean
    gcc my_mean.c -o my_mean -lm

    for i in ${!binaryName[@]}; do
        echo "get_MPKI_LLC - LLC Replacement Policy: ${binaryName[$i]}"
        for j in ${!trace_list[@]}; do
            path=./results_raw/${binaryName[$i]}-${trace_list[$j]}.txt
            lineNum="$(grep -n "LLC TOTAL     ACCESS:" $path | head -n 1 | cut -d: -f1)"
            miss_array[$j]=$(awk -v dataLine="$lineNum" 'NR==dataLine{print $8}' $path)
            echo "Trace No. ${j}: ${trace_list[$j]} - LLC Misses: ${miss_array[$j]}"
        done
        echo " "

        for j in ${!trace_list[@]}; do
            echo "${miss_array[$j]}"
        done > ./results_LLC_miss/${binaryName[$i]}.txt

        ./my_mean ./results_LLC_miss/${binaryName[$i]}.txt > ./results_LLC_mpki_mean/${binaryName[$i]}.txt 100000.0
    done

    rm my_mean
}



numThreads=8

compile_if llc_replacement_policy
run allTraces llc_replacement_policy numThreads path_allTraces
get_IPC allTraces llc_replacement_policy
get_MPKI_LLC allTraces llc_replacement_policy