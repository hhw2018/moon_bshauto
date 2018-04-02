#!/usr/bin/bash

function usage {
    local name=${0##*\/}
    echo "Usage: $name -f host_list_file"
    exit 1
}

# Register the framework env vars and lib functions
function config_framework {
    local path=${0%\/*}

    # Get the framework dir list and register them
    export MOON_BSHAUTO_HOME=$(cd $path/../; pwd)
    export MOON_BSHAUTO_BIN=$MOON_BSHAUTO_HOME/bin
    export MOON_BSHAUTO_FW_LIB=$MOON_BSHAUTO_HOME/lib/framework
    export MOON_BSHAUTO_FW_CONF=$MOON_BSHAUTO_HOME/conf/framework
     
    # Register the framework env vars
    local file=""
    for file in $MOON_BSHAUTO_FW_CONF/*; do
        . $file
    done

    # Load the framework libs
    for file in $MOON_BSHAUTO_FW_LIB/*; do
        . $file
    done
}

function parse_arguments {
    case $1 in
        -h)
            shift
            gfile="$@"
            ;;
         *)
            usage
            ;;
    esac

    [[ -z "$gfile" ]]  && usage
}

gfile=""

function main {
    parse_arguments $@
    config_framework

    local host=""
    while read line; do
        echo $host
    done < $gfile
}

main $@
