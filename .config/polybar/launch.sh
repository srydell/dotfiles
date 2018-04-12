#!/bin/bash
#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch bar $1 on each available monitor
for i in $(polybar -m | awk -F: '{print $1}'); do MONITOR=$i polybar $1 -c ~/.config/polybar/config & done

echo "Bars launched..."
