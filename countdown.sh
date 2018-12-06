#!/usr/bin/env bash


# Uses GNU version of date
function countdown() {
    date1=$((`gdate +%s` + $1));
    while [ "$date1" -ge `gdate +%s` ]; do
        echo -ne "$(gdate -u --date @$(($date1 - `gdate +%s`)) +%H:%M:%S)\r";
        sleep 0.1
    done
}

function stopwatch(){
    date1=`gdate +%s`;
    while true; do
        echo -ne "$(gdate -u --date @$((`gdate +%s` - $date1)) +%H:%M:%S)\r";
        sleep 0.1
        done
}