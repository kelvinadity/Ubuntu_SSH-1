#!/bin/bash

duration="7200";
start_time="$(date +%s)";
current_time="$(date +%s)";
elapsed_time="$((current_time - start_time))";

while true; do
    if [[ ${elapsed_time} -ge ${duration} ]]; then
        echo "-- Finished running!";
        exit 0;
    fi
    echo "-- Running ...";
    sleep 30;
done
