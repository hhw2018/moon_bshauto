#!/usr/bin/bash 
NAME=${0##*/}
    
function usage {
cat <<EOF
Usage: $NAME -f host_file|-h host_list [-d path]
  host_file: file with host ips separated by new-line char.
  host_list: list of host ips separated by space.
  path: work home where the framework will be installed(/var/log by default).
EOF
    exit 1
}

# Register the framework env vars and lib functions
function config {
    local path=${0%\/*}

    export MOON_BSHAUTO_HOME=$(cd $path/../; pwd)
    export MOON_BSHAUTO_FW_LIB=$MOON_BSHAUTO_HOME/lib/framework
    export MOON_BSHAUTO_FW_CONF=$MOON_BSHAUTO_HOME/conf/framework
     
    # Register the framework env vars as well as libs 
    . $MOON_BSHAUTO_FW_LIB/remote.bshlib
    . $MOON_BSHAUTO_FW_CONF/expect.cfg
}

function parse_arguments {
    local f=0
    local h=0

    # The 1st option must be -f or -h
    case $1 in
        -f)
            shift
            f=1
            [[ ! -f "$1" ]] \
                && echo "$NAME: Cannot access $1." \
                && usage
            host_list=$(cat $1)
            [[ -z "$host_list" ]] \
                && echo "$NAME: Empty file." \
                && usage
            shift
            ;;

        -h)
            shift
            h=1
            local cnt=$(egrep -bow '\-d' <<< "$*" | cut -d':' -f1 | head -1)
            local args="$*"
            ((cnt == 0)) && host_list="$*" || host_list="${args:0:$cnt}"
            [[ -z "$host_list" ]] \
                && echo "$NAME: No host is specified." \
                && usage
            cnt=$(echo "$host_list" | wc -w)
            shift $cnt
            ;;

         *)
            usage
            ;;
    esac

    # -d must be the 1st if there are more arguments left.
    if (($# > 0)); then
        case $1 in
            -d)
                shift
                work_home=$1
                [[ ! -d "$work_home" ]] \
                    && echo "$NAME: A work home path needs to be specified." \
                    && usage
                ;;
    
            *)
                echo "error: $1"
                usage
                ;;
        esac
    fi

    (( f + h != 1)) && usage
}

host_list=""
work_home="/var/log"

function main {
    parse_arguments $@
    config

    cd $MOON_BSHAUTO_HOME

    local host=""
    for host in $host_list; do
        echo "Host: $host, deploying..."
        (
        cmd="mkdir -p $work_home/moon_bshauto"
        rcml_host $host $cmd
        assert $? -eq 0

        cd $MOON_BSHAUTO_HOME
        cmd="scp -rp bin lib tests tools conf $MOON_BSHAUTO_EXP_USER@$host:$work_home/moon_bshauto/"
        rcml "$cmd"
        )
        assert $? -eq 0
    done 
}

main $@
