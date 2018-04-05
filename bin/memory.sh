#!/usr/bin/env bash 
NAME=${0##*/}
    
function usage {
cat <<EOF
Usage: 
  $NAME -g total|free|usedperc
  $NAME -f percent | -r
    -g: Get total/free memory size(KB), and used percent(usedperc%). 
    -f: Fill memory up to percent%.
    -r: Release memory filled by -u option.
  
  -g/-r/-f are mutually exclusive options.
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
    . $MOON_BSHAUTO_FW_LIB/memory.bshlib
}

function parse_arguments {
    local opt=""
    local g_opt=0
    local r_opt=0
    local f_opt=0

    while getopts ":g:f:r" opt; do
    case $opt in
        g)
            ((++g_opt))
            case $OPTARG in
            total)
                MEM_CLI="mem_get_total"
                ;;
            free)
                MEM_CLI="mem_get_free"
                ;;
            usedperc)
                MEM_CLI="mem_get_used_perc"
                ;;
            *)
                usage
                ;;
            esac
            ;;

        f)
            ((++f_opt))
            ((OPTARG < 1)) && usage
            MEM_CLI="mem_fill_perc $OPTARG"
            ;;

        r)
            ((++r_opt))
            MEM_CLI="mem_free"
            ;;

         \?)
            usage
            ;;
    esac
    done

    # Check mutually exclusive options.
    ((g_opt + r_opt + f_opt != 1)) && usage
}

MEM_CLI=""
function main {
    parse_arguments $@
    config
    $MEM_CLI
}

main $@
