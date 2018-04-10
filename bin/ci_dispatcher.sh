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
    . $MOON_BSHAUTO_FW_CONF/expect.cfg
    . $MOON_BSHAUTO_FW_CONF/ci.cfg
    . $MOON_BSHAUTO_FW_LIB/ci.bshlib
}

function run {
    local test_arr=($(egrep -v "[[:space:]]*#" $MOON_BSHAUTO_FW_CONF/ci.cfg | egrep -ow "${PROJECT}_functional|${PROJECT}_stress|${PROJECT}_longevity|${PROJECT}_performance"))
    local host_cnt=${#test_arr[@]}
    
    ((host_cnt < 1)) && echo "No test cases specified for project $PROJECT" && exit 1

    local i=0
    local host=""
    local test_type=""
    for host in $(ci_get_runners $host_cnt); do
        test_type=${test_arr[$i]#${PROJECT}_}
        echo "Start a runner for the $test_type testing on host $host against project $PROJECT."
        rcml_host $host $MOON_BSHAUTO_BIN/ci_runner.sh $PROJECT $test_type
        ((++i))
    done
}

function main {
    parse_argument $@
    config
    run
}

PROJECT=""
main $@
