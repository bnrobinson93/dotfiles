#!/bin/bash

if lsmod | grep -q uvcvideo; then
    fuser -sk /dev/video* 2>/dev/null
    sudo modprobe -r uvcvideo
    notify-send "Camera" "Camera disabled" -t 2000
else
    # Enable camera
    sudo modprobe uvcvideo
    notify-send "Camera" "Camera enabled" -t 2000
fi
