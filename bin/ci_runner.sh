#!/usr/bin/env bash 

NAME=${0##*/}
    
function usage {
cat <<EOF
Usage: $NAME project_name test_type
  project_name: the project managed by CI.
  test_type: functional or stress or longevity or performance.
EOF
    exit 1
}

function parse_argument {
    PROJECT=$1
    TEST_TYPE=$2

    [[ -z "$PROJECT" || -z "$TEST_TYPE" ]] && usage
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
    local opt=""

    case $TEST_TYPE in
    functional)
        opt="-f"
        ;;
        
    stress)
        opt="-s"
        ;;
    
    longevity)
        opt="-l"
        ;;
    
    performance)
        opt="-p"
        ;;
    *)
        usage
    esac

    $MOON_BSHAUTO_BIN/driver.sh $opt $PROJECT $(eval echo \$$PROJECT_$TEST_TYPE)
}

function main {
    parse_argument $@
    config
    run
}

PROJECT=""
TEST_TYPE=""
main $@
