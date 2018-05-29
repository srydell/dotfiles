#!/usr/bin/env bash

# If there is a video stream, kill it, otherwise start streaming to mpv
pkill -f /dev/video || mpv --geometry=-0-0 --autofit=30% /dev/video0
