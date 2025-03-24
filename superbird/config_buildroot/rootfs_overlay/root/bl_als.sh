#!/bin/bash

STEPS=100           # Count of steps during smooth brightness change (more - smoother) 
STEP_DELAY=0.01     # Pause between steps
PAUSE=15            # Additional pause after brightess change

CHECK_SCREEN_STATE=1

# Note that overall pause between ambient measures will be 
# STEPS * STEP_DELAY + PAUSE

## Init ALS IIO
if [ -e "/sys/bus/iio/devices/iio:device0/in_intensity0_raw" ]
then
    echo 16 > /sys/bus/iio/devices/iio:device0/in_intensity0_calibscale
    ALS_IIO="/sys/bus/iio/devices/iio:device0/in_intensity0_raw"
else
    echo 16 > /sys/bus/iio/devices/iio:device1/in_intensity0_calibscale
    ALS_IIO="/sys/bus/iio/devices/iio:device1/in_intensity0_raw"
fi

## Init BL
BACKLIGHT="/sys/class/backlight/backlight"

OUT_BR="$BACKLIGHT/brightness"
ACTUAL_BR="$BACKLIGHT/actual_brightness"

MIN=64
MAX=$( cat "$BACKLIGHT/max_brightness" )

RANGE=$(( $MAX - $MIN ))

MIN_AMBIENT_DIFF=4

# Reset Brightness to min
echo $MIN > $OUT_BR
last_ambient=0

while true
do
    sleep $PAUSE

    if (( $CHECK_SCREEN_STATE )); then
        if ([ $( cat "$ACTUAL_BR" ) -eq 0 ]); then
            echo "Screen is off, skipping all work"
            continue
        fi
    fi

    ambient=$( cat "$ALS_IIO" )
    ambient_diff=$(( $last_ambient - $ambient ))

    echo "Ambient value: $ambient"
    echo "Ambient diff ${ambient_diff#-}"

    if ([ ${ambient_diff#-} -lt $MIN_AMBIENT_DIFF ]); then
        echo "Skiping change"
        continue
    fi

    last_ambient=$ambient

    curr_brightness=$( cat $ACTUAL_BR )

    new_brightness=$(( $MIN + $RANGE * $ambient / 1024 ))

    incr=$(( ($new_brightness - $curr_brightness) / $STEPS ))

    if ([ $incr -eq 0 ]); then
        incr=$(( $new_brightness > $curr_brightness ? 1 : -1 ))
    fi

    for br in $(seq $curr_brightness $incr $new_brightness)
    do  
        echo $br > $OUT_BR
        sleep $STEP_DELAY
    done

    echo $new_brightness > $OUT_BR
    echo "Brightness set: $new_brightness"

done