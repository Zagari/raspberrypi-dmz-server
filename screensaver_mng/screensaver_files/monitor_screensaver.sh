#!/bin/bash
# monitor_screensaver.sh
# Monitora performance do screensaver

while true; do
    echo "=== $(date) ==="
    echo "CPU Temperature: $(vcgencmd measure_temp)"
    echo "Memory Usage:"
    free -h
    echo "GPU Memory Split:"
    vcgencmd get_mem arm
    vcgencmd get_mem gpu
    echo "Screensaver Process:"
    ps aux | grep screensaver | grep -v grep
    echo "------------------------"
    sleep 30
done
