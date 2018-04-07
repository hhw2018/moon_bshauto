#!/usr/bin/env bash 
NAME=${0##*/}
    
function usage {
cat <<EOF
Usage: 
  $NAME -g physical|processor|core
  $NAME -u|-s|-i -p processor_id|all
  $NAME -f percent -p processor_id|all
  $NAME -r
    -u: %user.
    -s: %system.
    -i: %idle.
    -p: Specify a specific CPU processor id, or all processors.
    -g: Get count of physical CPUs/logical processors/cores.
    -f: Fill workload up to percent% CPU utilization. 
    -r: Release CPU workload filled by -f option.
  
  -g/-r/-f/-u-s-i are mutually exclusive options.
EOF
    exit 1
}

# Register the framework env vars and lib functions
function config {
    local path=${0%\/*}

    export MOON_BSHAUTO_HOME=$(cd $path/../; pwd)
    export MOON_BSHAUTO_BIN=$MOON_BSHAUTO_HOME/bin
    export MOON_BSHAUTO_FW_LIB=$MOON_BSHAUTO_HOME/lib/framework
     
    # Register the necessary framework env vars as well as libs 
    . $MOON_BSHAUTO_FW_LIB/cpu.bshlib
}

function parse_arguments {
    local opt=""
    local g_opt=0
    local r_opt=0
    local f_opt=0
    local u_opt=0
    local s_opt=0
    local i_opt=0
    local p_opt=0

    while getopts ":g:f:p:rusi" opt; do
    case $opt in
        p)
            ((++p_opt))
            CPU_ID=$(sed -nr '/^([0-9]+|all)$/p' <<< "$OPTARG")
            [[ -z "$CPU_ID" ]] && usage
            ;;

        i)
            ((++i_opt))
            PERC_OBJ="idle|$PERC_OBJ"
            CPU_CLI="cpu_get_util_perc"
            ;;

        u)
            ((++u_opt))
            PERC_OBJ="user|$PERC_OBJ"
            CPU_CLI="cpu_get_util_perc"
            ;;

        s)
            ((++s_opt))
            PERC_OBJ="system|$PERC_OBJ"
            CPU_CLI="cpu_get_util_perc"
            ;;

        g)
            ((++g_opt))
            case $OPTARG in
            physical)
                CPU_CLI="cpu_count_physical"
                ;;
            processor)
                CPU_CLI="cpu_count_processor"
                ;;
            core)
                CPU_CLI="cpu_count_core"
                ;;
            *)
                usage
                ;;
            esac
            ;;

        f)
            ((++f_opt))
            ((OPTARG < 1)) && usage
            CPU_CLI="cpu_fill_perc $OPTARG"
            ;;

        r)
            ((++r_opt))
            CPU_CLI="cpu_free"
            ;;

         \?)
            usage
            ;;
    esac
    done

    # Check mutually exclusive options.
    local sum=0
    ((sum = g_opt + r_opt + f_opt + u_opt + i_opt + s_opt))
    ((sum < 1 || sum > 3)) && usage

    if ((g_opt + r_opt + f_opt == 1)); then 
        ((u_opt + i_opt + s_opt != 0)) && usage
    elif ((g_opt + r_opt + f_opt == 0)); then 
        ((sum = u_opt + i_opt + s_opt))
        ((sum > 3 || sum < 1)) && usage
    else 
        usage
    fi

    # -p must be combined with -f/-u/-i/-s
    if ((p_opt == 0)); then
        ((g_opt + r_opt != 1)) && usage
    else
        ((f_opt + u_opt + i_opt + s_opt < 1)) && usage
    fi
}

CPU_CLI=""
CPU_ID=""
PERC_OBJ=""
function main {
    parse_arguments $@
    config
    
    if [[ -n "$PERC_OBJ" ]]; then
        local out=$($CPU_CLI $CPU_ID)
        egrep "${PERC_OBJ%|}" <<< "$out"
    else
        $CPU_CLI $CPU_ID
    fi
}

main $@
