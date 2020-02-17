#!/bin/bash
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

abs() { 
    [[ $[ $@ ] -lt 0 ]] && echo "$[ ($@) * -1 ]" || echo "$[ $@ ]"
}

statePrev="stateprev":
state="state"
buffer=1000000
oldset=2;
#find touch id
touch=$(xinput | grep ELAN2514:00 |grep pointer|grep -v Pen)
id=`expr "$touch" : '.*id=\([0-9]*\)'`
echo "id touchscreen=$id"

while :
do
#-------------brightness
edp=$(xrandr |grep eDP)
edp=${edp% connected*}

Current=$(cat /sys/class/backlight/intel_backlight/device/intel_backlight/brightness)
set=$(bc -l <<< "1 / (120000 / $Current)")
if [ $oldset = $set ]; then 
    echo "">/dev/null
else

     xrandr --output $edp --brightness $set
#    xrandr --output eDP-1 --brightness $set
#    xrandr --output eDP-1-1 --brightness $set    
    oldset=$set
fi
#-------------orientation
angleX=$(cat /sys/bus/iio/devices/iio:device*/in_incli_x_raw)
angleY=$(cat /sys/bus/iio/devices/iio:device*/in_incli_y_raw)
ABSangleX=$(abs $angleX)
ABSangleY=$(abs $angleY)




#echo angleX $angleX
#echo angleY $angleY

tmpval=$((($ABSangleX + $buffer)))

if [ $ABSangleY -gt $tmpval ]; then
    if [ $angleY -gt 0 ]; then
        if [  $state != "left" ]; then
            state="left"
            xinput set-prop "ELAN2514:00 04F3:2975 Pen (0)" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
            xinput set-prop "SYNA327F:00 06CB:CD4F Touchpad" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
            xinput set-prop $id --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
        fi
    else
        if [  $state != "right" ]; then
            state="right"
            xinput set-prop "ELAN2514:00 04F3:2975 Pen (0)" --type=float "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
            xinput set-prop "SYNA327F:00 06CB:CD4F Touchpad" --type=float "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
            xinput set-prop $id --type=float "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1    
        fi
    fi
fi

tmpval=$((($ABSangleX - $buffer)))
if [  $ABSangleY -lt $tmpval ]; then
    if [ $angleX -gt 0 ]; then
        if [  $state != "normal" ]; then
            #echo "$ABSangleY > 0" 
            state="normal"    
            xinput set-prop "ELAN2514:00 04F3:2975 Pen (0)" --type=float "Coordinate Transformation Matrix" 0 0 0 0 0 0 0 0 0 
            xinput set-prop "SYNA327F:00 06CB:CD4F Touchpad" --type=float "Coordinate Transformation Matrix" 0 0 0 0 0 0 0 0 0 
            xinput set-prop $id --type=float "Coordinate Transformation Matrix" 0 0 0 0 0 0 0 0 0     
        fi
    else
        if [  $state != "inverted" ]; then
            state="inverted"
            xinput set-prop "ELAN2514:00 04F3:2975 Pen (0)" --type=float "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
            xinput set-prop "SYNA327F:00 06CB:CD4F Touchpad" --type=float "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
            xinput set-prop $id --type=float "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
        fi
    fi
fi

#echo "current $state prev $statePrev "
if [ $state = $statePrev ]; then 
        echo "">/dev/null
else
    echo "new state " $state;
    statePrev=$state
    xrandr -o $state
    xrandr  --output eDP-1-1 --rotate $state
fi

sleep 0.1
done



