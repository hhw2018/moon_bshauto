#!/usr/bin/env bash 
NAME=${0##*/}
    
function usage {
cat <<EOF
Usage: $NAME project_name
EOF
    exit 1
}

function parse_argument {
    PROJECT=$1
    [[ -z "$PROJECT" ]] && usage
}

# Register the framework env vars and lib functions
function config {
    local path=${0%\/*}

    export MOON_BSHAUTO_HOME=$(cd $path/../; pwd)
    export MOON_BSHAUTO_BIN=$MOON_BSHAUTO_HOME/bin
    export MOON_BSHAUTO_FW_LIB=$MOON_BSHAUTO_HOME/lib/framework
    export MOON_BSHAUTO_FW_CONF=$MOON_BSHAUTO_HOME/conf/framework
     
    # Register the necessary framework env vars as well as libs 
    . $MOON_BSHAUTO_FW_LIB/ci.bshlib
    . $MOON_BSHAUTO_FW_CONF/ci.cfg
}

function pickup_host {
    local ret=""
    local host=""

    for host in $MOON_BSHAUTO_CI_RUNNER; do
        if ! ci_is_runner_working $host; then
            ret=$host
            break
        fi
    done

    # Pick up one if there is not idle runner.
    [[ -z "$ret" ]] && ret=${MOON_BSHAUTO_CI_RUNNER## }

    echo $ret
}

function run {
    local host=$(pickup_host)
    rcli_host $host $MOON_BSHAUTO_BIN/ci_runner.sh $PROJECT
}

function main {
    parse_argument $@
    config
    run
}

PROJECT=""
main $@
