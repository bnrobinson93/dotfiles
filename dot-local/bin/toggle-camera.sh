#!/bin/bash

if lsmod | grep -q uvcvideo; then
    # Find and kill processes using the camera
    for video_dev in /dev/video*; do
        if [ -e "$video_dev" ]; then
            PIDS=$(sudo lsof -t "$video_dev" 2>/dev/null)
            if [ -n "$PIDS" ]; then
                echo "$PIDS" | xargs -r sudo kill -9
            fi
        fi
    done
    
    # Wait a moment for processes to die
    sleep 0.5
    
    # Disable camera
    sudo modprobe -r uvcvideo
    notify-send "Camera" "Camera disabled" -t 2000
else
    # Enable camera
    sudo modprobe uvcvideo
    notify-send "Camera" "Camera enabled" -t 2000
fi
