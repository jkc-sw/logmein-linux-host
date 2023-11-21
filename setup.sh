#!/usr/bin/env bash

SCRIPT_ROOT="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

# Env path
pyEnv="$SCRIPT_ROOT/.env"
requirementFile="$SCRIPT_ROOT/requirements.txt"
licenseFile="$SCRIPT_ROOT/license.dat"
pyPath="$pyEnv/bin/python"
cronTag='LOGMEIN-HOST'
cronMarkerStart="# BSTART $cronTag"
cronMarkerEnd="# BEND $cronTag"
runScript="$SCRIPT_ROOT/run.sh"
logDir="$HOME/Downloads"
logFile="$logDir/logmein-host-log.txt"
reverseProxyDir="$SCRIPT_ROOT/reverse-proxy"
export TERM_PORT=23825
stopScript="$SCRIPT_ROOT/stop.sh"

# help
displayHelp() {
    echo "$(dirname "$0") [-d <deployment-code] [-u]"
    echo ""
    echo "Start the logmein-host"
    echo ""
    echo "Options:"
    echo "  -d: Deployment code from logmein central. Do only once"
    echo "  -u: Uninstall the logmein-host from cronjob"
}

# parse command line
deploymentCode=''
uninst=false
while getopts ':hd:u' opt; do
    case "$opt" in
    d)
        deploymentCode="$OPTARG"
        ;;
    r)
        uninst=true
        ;;
    h)
        displayHelp
        exit 0
        ;;
    *)
        echo "Unrecognized option $opt" >&2
        displayHelp
        exit 1
        ;;
    esac
done

# Check conda is available
if ! command -v "conda" &>/dev/null; then
    echo 'ERR: "conda" is not available in the PATH' >&2
    exit 1
fi

# Check yarn is available
if ! command -v "yarn" &>/dev/null; then
    echo 'ERR: "yarn" is not available in the PATH' >&2
    exit 1
fi

# Change directory
cd "$SCRIPT_ROOT"

# Create python environment
eval $(conda shell.bash hook)
if [[ ! -r "$pyPath" ]]; then
    conda create -y -p "$pyEnv" python=3.8
    conda activate "$pyEnv"
    "$pyPath" -m pip install -r "$requirementFile"
else
    conda activate "$pyEnv"
fi

# Install yarn
pushd "$reverseProxyDir" || exit 1
yarn install
popd || exit 1

# Connect to the logmein dashboard if no license file is found
if [[ ! -r "$licenseFile" && -z "$deploymentCode" ]]; then
    echo 'ERR: Please provide -d <deployment-code> to register with logmein' >&2
    exit 1
elif [[ ! -r "$licenseFile" && -n "$deploymentCode" ]]; then
    # Register using the logmein central code
    "$pyPath" "$SCRIPT_ROOT/logmein_host/logmein_host.py" --deployment-code "$deploymentCode"
    # # TODO put the following into a function 'installCronJob'
    # # Create log dir
    # mkdir -p "$logDir"
    # # Remove older cronjob
    # cronContent="$(crontab -l)"
    # removedCronContent="$(echo -n "$cronContent" | sed "/^$cronMarkerStart/,/^$cronMarkerEnd/d")"
    # # Add new cronjob
    # newCronContent="$removedCronContent"
    # newCronContent="$(printf '%s\n%s' "$newCronContent" "$cronMarkerStart")"
    # newCronContent="$(printf '%s\n%s' "$newCronContent" "'$runScript' >> '$logFile' 2>&1")"
    # newCronContent="$(printf '%s\n%s' "$newCronContent" "$cronMarkerEnd")"
    # # Install new cron
    # crontab - <<<"$newCronContent"
elif [[ "$uninst" == 'true' ]]; then
    # Uninstall from cronjob
    cronContent="$(crontab -l)"
    removedCronContent="$(echo -n "$cronContent" | sed "/^$cronMarkerStart/,/^$cronMarkerEnd/d")"
    # Install cleaned cron
    crontab - <<<"$removedCronContent"
fi

# echo 'DEBUG exit'
# exit 0

# Start the app when cronjob hasn't started one
otherInstances="$(ps -aux | grep -v grep | grep "$runScript")"
if [[ -n "$otherInstances" ]]; then
    echo 'Other instances:'
    echo "$otherInstances"
    echo ''
    echo 'Nothing to do. Exiting'
    exit 0
fi

# Get node path
nodePath="$(command -v node)"

# Start the applications
# petty
doas "$pyPath" "$SCRIPT_ROOT/pytty/pytty.py" &  # "--port=$TERM_PORT" &
job1="$!"
# wetty
pushd "$reverseProxyDir" || exit 1
doas "$nodePath" "$reverseProxyDir/node_modules/wetty/index.js" --port 23822 --title LogMeIn --base /xterm/ --host 127.0.0.1 --forcessh &
job2="$!"
popd || exit 1
# reverse-proxy
pushd "$reverseProxyDir" || exit 1
doas "$nodePath" "$reverseProxyDir/app.js" &
job3="$!"
popd || exit 1
# Logmein host
doas "$pyPath" "$SCRIPT_ROOT/logmein_host/logmein_host.py" &
job4="$!"

# Create a command to stop
echo "doas kill -9 $job1 $job2 $job3 $job4" > "$stopScript"
chmod +x "$stopScript"
