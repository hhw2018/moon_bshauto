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
    #export MOON_BSHAUTO_FW_LIB=$MOON_BSHAUTO_HOME/lib/framework
    export MOON_BSHAUTO_FW_CONF=$MOON_BSHAUTO_HOME/conf/framework
     
    # Register the necessary framework env vars as well as libs 
    #. $MOON_BSHAUTO_FW_LIB/ci.bshlib
    . $MOON_BSHAUTO_FW_CONF/ci.cfg
}

function run {
    $MOON_BSHAUTO_BIN/driver.sh $(eval echo \$${PROJECT}_tc_list)
}

function main {
    parse_argument $@
    config
    run
}

PROJECT=""
main $@
