#!/bin/bash
# prompt-notify.sh — Plays a notification sound when Claude Code finishes
# its turn and needs user attention (permission prompt, question, etc.)
#
# How it works:
#   Attempts to play system notification sounds using various commands
#   depending on the platform (macOS, Linux, etc.)
#
# Hook event: Stop (fires when Claude's turn ends and user input is needed)

# Try different notification methods based on platform
if command -v osascript &> /dev/null; then
    # macOS: Use osascript to play system sound
    osascript -e 'beep 1' 2>/dev/null
elif command -v paplay &> /dev/null; then
    # Linux with PulseAudio: Play bell sound
    paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null
elif command -v aplay &> /dev/null; then
    # Linux with ALSA: Play bell sound
    aplay /usr/share/sounds/freedesktop/stereo/bell.wav 2>/dev/null
elif command -v speaker-test &> /dev/null; then
    # Fallback: Generate a tone using speaker-test
    speaker-test -t sine -f 800 -l 1 -P 1 2>/dev/null &
    sleep 0.2
    pkill speaker-test 2>/dev/null
else
    # Ultimate fallback: Terminal bell (BEL character)
    printf '\a'
fi

exit 0
