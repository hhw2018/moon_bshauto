#!/usr/bin/env bash

function usage {
    local name=${0##*\/}

cat <<EOF
Usage: driver.sh -f|-s|-p|-l proj [-d dir1 [-d dir2 ...]] [tc [tc...]]
  -f: Perform functional testing under tests/functional.
  -s: Perform stress testing under tests/stress.
  -p: Perform performance testing under tests/performance.
  -l: Perform longevity testing under tests/longevity.
proj: The project name managed by git.
  -d: Test case directory name.
  tc: Test case name, which is global unique.

Usage: $name -t "tool_script arglist"
  -t: The tool name and its arguments.
EOF
    exit 1
}

# Register the framework env vars and lib functions
function config_framework {
    local path=${0%\/*}

    # Get the framework dir list and register them
    export MOON_BSHAUTO_HOME=$(cd $path/../; pwd)
    export MOON_BSHAUTO_BIN=$MOON_BSHAUTO_HOME/bin
    export MOON_BSHAUTO_FW_LIB=$MOON_BSHAUTO_HOME/lib/framework
    export MOON_BSHAUTO_USER_LIB=$MOON_BSHAUTO_HOME/lib/user
    export MOON_BSHAUTO_FW_CONF=$MOON_BSHAUTO_HOME/conf/framework
    export MOON_BSHAUTO_USER_CONF=$MOON_BSHAUTO_HOME/conf/user

    if [[ "$g_type" == "tools" ]]; then
        export MOON_BSHAUTO_TOOLS=$MOON_BSHAUTO_HOME/tools
        export MOON_BSHAUTO_LOG=$MOON_BSHAUTO_HOME/log/tools
    else
        export MOON_BSHAUTO_TESTS=$MOON_BSHAUTO_HOME/tests/$g_project/$g_type
        export MOON_BSHAUTO_LOG=$MOON_BSHAUTO_HOME/log/tests/$g_project/$g_type
    fi
     
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

# Register the log dir env vars
# User should register user-defined env vars and lib functions
function config_user {
    local now=$(get_date)
    #local now=$(date +%Y-%m-%d-%H:%M:%S)
    export MOON_BSHAUTO_LOG_PATH=$MOON_BSHAUTO_LOG/$now.$$
    export MOON_BSHAUTO_LOG_FILE=$MOON_BSHAUTO_LOG_PATH/log.$$
    mkdir -p $MOON_BSHAUTO_LOG_PATH
}

function parse_arguments {
    local dir_list=""
    local file_list=""
    local opt_cnt=0
    local opt=$1
    local g_project=$2
    shift 2

    [[ -z "$g_project" ]] && usage

    case $opt in
        -l)
            ((++opt_cnt))
            g_type="longevity" 
            ;;
        -s)
            ((++opt_cnt))
            g_type="stress" 
            ;;
        -p)
            ((++opt_cnt))
            g_type="performance" 
            ;;
        -f)
            ((++opt_cnt))
            g_type="functional" 
            ;;
        -t)
            ((++opt_cnt))
            g_type="tools"
            g_file_list="$*"
            shift $#
            ;;
         *)
            usage
            ;;
    esac

    ((opt_cnt != 1)) && usage

    if [[ "$g_type" == "tools" ]]; then 
        [[ -z "$g_file_list" ]]  && usage || return
    fi

    while (($# > 0)); do
        local arg=$1
        shift

        case $arg in
            -d)
                [[ -z "$1" ]] && usage || dir_list="$1|$dir_list"
                shift
                ;;
             *)
                file_list="$arg $file_list"
                ;;
        esac
    done

    g_file_list="${file_list% }"
    g_dir_list="${dir_list%|}"
}

# Generate the tc list to be run
function get_tc2run {
    if [[ -z "$g_dir_list" && -z "$g_file_list" ]]; then
        cp -rp $MOON_BSHAUTO_LOG_PATH/tc.all $MOON_BSHAUTO_LOG_PATH/tc.run
        return
    fi

    [[ -n "$g_dir_list" ]] \
        && egrep -w "${g_dir_list}" $MOON_BSHAUTO_LOG_PATH/tc.all > $MOON_BSHAUTO_LOG_PATH/tc.run

    local file=""
    local dir=""

    for file in $g_file_list; do
        is_str_existed "$file" $MOON_BSHAUTO_LOG_PATH/tc.run && continue

        dir=$(egrep -w "$file" $MOON_BSHAUTO_LOG_PATH/tc.all)
        [[ -z "$dir" ]] && continue

        dir=${dir%:*}
        is_str_existed "$dir" $MOON_BSHAUTO_LOG_PATH/tc.run \
            && sed -i "/^$dir:/s/^$dir:.*/& $file/" $MOON_BSHAUTO_LOG_PATH/tc.run \
            || echo "$dir: $file" >> $MOON_BSHAUTO_LOG_PATH/tc.run
    done

}

# Generate the tc list including all tc in tests
function get_all_tc {
    local dir=""
    for dir in $(ls $MOON_BSHAUTO_TESTS); do
        echo "$dir: $(ls $MOON_BSHAUTO_TESTS/$dir | egrep -vw 'bshlib|config|setup|cleanup' | xargs)"
    done > $MOON_BSHAUTO_LOG_PATH/tc.all
}

# Perform testing 
function perform_testing {
    get_all_tc 
    get_tc2run
    
    if [[ ! -s "$MOON_BSHAUTO_LOG_PATH/tc.run" ]]; then 
        log_msg "NO TC FOUND."
        exit 0
    fi

    local line=""
    while read line; do
        local dir=${line%:*} 
        local tcs=${line#*:}
        local config=$MOON_BSHAUTO_TESTS/$dir/config
        local setup=$MOON_BSHAUTO_TESTS/$dir/setup
        local cleanup=$MOON_BSHAUTO_TESTS/$dir/cleanup
       
# Perform tests in a specific dir in a newly forked child process,
# which can prevent namespace conflict, esp. env vars. So env vars defined in
# local config file can only be used by the process itself and its children.
(
        export MOON_BSHAUTO_TC_DIR=$MOON_BSHAUTO_TESTS/$dir

        # Perform testing against a testing dir
        log_msg "TEST PATH BEGIN: $MOON_BSHAUTO_TC_DIR"
        # Register local env vars
        [[ -f $config ]] && . $config
        
        # Prepare the testing env
        ([[ -f $setup ]]  && . $setup)

        # Setup failure: clean the current and continue the next
        if (( $? != 0)); then 
            ([[ -f $cleanup ]] && . $cleanup)
            exit 0
        fi

        # Perform the tc one by one in a child process,
        #   1. use env vars defined in both 
        #      framework(grandfather) and local config file(parent), 
        #   2. call functions defined in both framework(grandfather)
        #      and local bshlib(process itself). 
        for tc in $tcs; do
            log_msg "TEST CASE: $MOON_BSHAUTO_TESTS/$dir/$tc"
            (. $MOON_BSHAUTO_TESTS/$dir/$tc)

            # A failure? Stop testing when MOON_BSHAUTO_STOP is set."
            if (($? != 0 && MOON_BSHAUTO_STOP != 0)); then
                log_msg "TEST STOP: Stop testing when MOON_BSHAUTO_STOP is set."
                ([[ -f $cleanup ]] && . $cleanup)
                exit 1
            fi
        done

        # Clean the current testing env 
        ([[ -f $cleanup ]] && . $cleanup)
        log_msg "TEST PATH END: $MOON_BSHAUTO_TC_DIR"
)

        if (($? != 0 && MOON_BSHAUTO_STOP != 0)); then
            exit 1
        fi
    done < $MOON_BSHAUTO_LOG_PATH/tc.run
}

function use_tool {
    local cml="$MOON_BSHAUTO_TOOLS/$g_file_list"
    (. $cml)
}

g_type=""
g_dir_list=""
g_file_list=""
g_project=""

function main {
    parse_arguments $@
    config_framework
    config_user

    [[ "$g_type" != "tools" ]] && perform_testing || use_tool
}

main $@
