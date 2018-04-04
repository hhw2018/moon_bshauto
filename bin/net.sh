#!/usr/bin/env bash 
NAME=${0##*/}
    
function usage {
cat <<EOF
Usage: $NAME -b|-r nic
  -b: Break down the networking connection.
  -r: Recover the networking connection.
  nic: NIC device name.
  
  -b, -r are mutually exclusive options.
EOF
    exit 1
}

# Register the framework env vars and lib functions
function config {
    local path=${0%\/*}

    export MOON_BSHAUTO_HOME=$(cd $path/../; pwd)
    export MOON_BSHAUTO_FW_LIB=$MOON_BSHAUTO_HOME/lib/framework
     
    # Register the necessary framework env vars as well as libs 
    . $MOON_BSHAUTO_FW_LIB/net.bshlib
}

function parse_arguments {
    local opt=""
    local nic_device=""
    local b_opt=0
    local r_opt=0

    while getopts ":b:r:" opt; do
    case $opt in
        b)
            ((++b_opt))
            nic_device=$OPTARG
            NET_CLI="net_break_by_ipt $nic_device"
            ;;

        r)
            ((++r_opt))
            nic_device=$OPTARG
            NET_CLI="net_recover_by_ipt $nic_device"
            ;;

         \?)
            usage
            ;;
    esac
    done

    # Check mutually exclusive options.
    ((b_opt + r_opt != 1)) && usage
}

NET_CLI=""
function main {
    parse_arguments $@
    config
    $NET_CLI
}

main $@
