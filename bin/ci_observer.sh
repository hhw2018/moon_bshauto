#!/usr/bin/env bash 
NAME=${0##*/}
    
function usage {
cat <<EOF
Usage: $NAME
EOF
    exit 1
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

    mkdir -p $MOON_BSHAUTO_CI_HOME
}

function check_update {
    local today="$(date +%Y-%m-%d) 00:00"
    local project=""
    local commit=""

    for project in $MOON_BSHAUTO_CI_PROJECTS; do
        # Clone the project at the first time
        [[ ! -d $MOON_BSHAUTO_CI_HOME/$project ]] \
            && (cd $MOON_BSHAUTO_CI_HOME; git clone $MOON_BSHAUTO_GIT_SERVER/$project.git)

        # Check if there is any commit *TODAY*
        cd $MOON_BSHAUTO_CI_HOME/$project
        git pull
        commit=$(git log --pretty="%H %cd" --since="$today")
        
        # Notify dispatcher to pick up a runner to run tests.
        if [[ -n "$commit" ]]; then
            echo "Today's update for $project."
            echo "$commit"

            rcml_host $MOON_BSHAUTO_CI_DISPATCHER $MOON_BSHAUTO_BIN/ci_dispatcher.sh $project
        else
            echo "No update for project $project."
        fi
    done
}

function main {
    config
    check_update
}

main $@
