#!/usr/bin/env bash
# Version:
# - 1.0.0 (2016-08-16)
# Repository:
# - https://github.com/JonasHavers/docker-compose-wait/
# Description:
# - Connects and waits for all exposed TCP ports of a Docker Compose multi-container application to become accessible.
# Requirements:
# - docker, docker-compose, awk, nc
# Tested with different versions of docker and netcat on OS X and Linux.

# Executables
DOCKER="docker"
COMPOSE="docker-compose"
NETCAT="nc"
CMDNAME="$(basename $0)"

# Defaults
QUIET=0
FILE="docker-compose.yml"
RETRY=5
WAIT=1

echo_info() { if [[ $QUIET -ne 1 ]]; then echo "[INFO] $@"; fi }
echo_warn() { if [[ $QUIET -ne 1 ]]; then echo "[WARN] $@"; fi }
echo_error() { if [[ $QUIET -ne 1 ]]; then echo "[ERROR] $@" 1>&2; fi; exit 1; }
usage() {
    cat << USAGE >&2
Usage:
    $CMDNAME [-q] [-f file] [-r retries] [-w wait_in_secs]

Options:
    -q | --quiet                    Do not output any debug messages
    -f FILE | --file=FILE           Path to Compose file (current: $FILE)
    -r RETRY | --retry=RETRY        Retry RETRY times for each container to expose its port (current: $RETRY)
    -w WAIT | --wait=WAIT           Wait WAIT seconds after each connection attempt (current: $WAIT)
    -h | --help                     Print this usage info

USAGE
    if [[ ! -z "$@" ]]; then
        cat << INFO >&2
Info:
    $@

INFO
    fi
    exit 1
}
check_file_exists() {
    if [ ! -f $FILE ]; then
        usage "Compose file '$FILE' not found"
    fi
}
wait_for_containers() {
    containers=$($COMPOSE -f $FILE ps -q)
    if [[ -z "$containers" ]]; then
        echo_error "No containers found. Did you execute 'docker-compose up [-d]' before?"
    fi
    for container in $containers; do
        exit_code=$(docker inspect --format="{{.State.ExitCode}}" $container)
        if [[ $exit_code -ne 0 ]]; then
            echo_warn "Container ${container:0:7} exited with exit code $exit_code"
        fi
        for host_port in $($DOCKER port $container | awk -F' ' '{ print $3 }'); do
            # Continue if no port is exposed
            if [[ -z "$host_port" ]]; then continue; fi
            # Extract host from host:port combo
            host=$(echo $host_port | awk -F':' '{ print $1 }')
            # Replace non-routable with local address
            if [[ "$host" = "0.0.0.0" ]]; then host="127.0.0.1"; fi
            # Extract port from host:port combo
            port=$(echo $host_port | awk -F':' '{ print $2 }')
            if [[ $QUIET -ne 1 ]]; then
                echo_info "Trying to connect to container ${container:0:7} at $host:$port"
            fi
            connection_retry=$RETRY
            until $NETCAT -d -z $host $port > /dev/null 2>&1; do
                if [[ $connection_retry -le 0 ]]; then
                    break
                fi
                if [[ $QUIET -ne 1 ]]; then
                    echo -n "."
                fi
                sleep $WAIT
                connection_retry=$((connection_retry-1))
                if [[ $connection_retry -eq 0 ]]; then
                    echo
                fi
            done
            if [[ $connection_retry -le 0 ]]; then
                echo_error "Failed to connect to container ${container:0:7} at $host:$port after $RETRY retries"
            else
                echo_info "Connected to container ${container:0:7} at $host:$port"
            fi
        done
    done
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -q|--quiet)
        QUIET=1
        shift 1
        ;;
        -f)
        FILE="$2"
        if [[ $FILE == "" ]]; then break; fi
        shift 2
        ;;
        --file=*)
        FILE="${1#*=}"
        shift 1
        ;;
        -w)
        WAIT="$2"
        if [[ $WAIT == "" ]]; then break; elif [[ "$WAIT" -lt 0 ]]; then WAIT=0; fi
        shift 2
        ;;
        --wait=*)
        WAIT="${1#*=}"
        if [[ "$WAIT" -lt 0 ]]; then WAIT=0; fi
        shift 1
        ;;
        -r)
        RETRY="$2"
        if [[ $RETRY == "" ]]; then break; elif [[ "$RETRY" -lt 0 ]]; then RETRY=0; fi
        shift 2
        ;;
        --retry=*)
        RETRY="${1#*=}"
        if [[ "$RETRY" -lt 0 ]]; then RETRY=0; fi
        shift 1
        ;;
        -h | --help)
        usage
        ;;
        *)
        usage "Unknown option: $1"
        ;;
    esac
done

check_file_exists
wait_for_containers
