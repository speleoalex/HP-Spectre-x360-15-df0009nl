#!/bin/bash
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

abs() { 
    [[ $[ $@ ] -lt 0 ]] && echo "$[ ($@) * -1 ]" || echo "$[ $@ ]"
}

statePrev="undefined":
state="normal"
buffer=1000000
oldset=2;
#find touch id
touch=$(xinput | grep ELAN2514:00 |grep pointer|grep -v Pen)
id=`expr "$touch" : '.*id=\([0-9]*\)'`
echo "id touchscreen=$id"

while :
do
#-------------brightness
Current=$(cat /sys/class/backlight/intel_backlight/device/intel_backlight/brightness)
set=$(bc -l <<< "1 / (120000 / $Current)")
if [ $oldset = $set ]; then 
    echo "">/dev/null
else
    xrandr --output eDP-1 --brightness $set
    oldset=$set
fi
#-------------orientation
angleX=$(cat /sys/bus/iio/devices/iio:device*/in_incli_x_raw)
angleY=$(cat /sys/bus/iio/devices/iio:device*/in_incli_y_raw)
ABSangleX=$(abs $angleX)
ABSangleY=$(abs $angleY)

#echo angleX $angleX
#echo angleY $angleY

#tmpval=$(bc -l <<< "$ABSangleX + $buffer")
tmpval=$((($ABSangleX + $buffer)))

if [ $ABSangleY -gt $tmpval ]; then
    #echo "$ABSangleY > $tmpval" 
    if [ $angleY -gt 0 ]; then
        state="left"
        xinput set-prop "ELAN2514:00 04F3:2975 Pen (0)" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
        xinput set-prop "SYNA327F:00 06CB:CD4F Touchpad" --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
        xinput set-prop $id --type=float "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
    else
        state="right"
        xinput set-prop "ELAN2514:00 04F3:2975 Pen (0)" --type=float "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
        xinput set-prop "SYNA327F:00 06CB:CD4F Touchpad" --type=float "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
        xinput set-prop $id --type=float "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1    
    fi
fi

#tmpval=$(bc -l <<< "$ABSangleX - $buffer")
tmpval=$((($ABSangleX - $buffer)))
if [  $ABSangleY -lt $tmpval ]; then
    #echo "$ABSangleY < $tmpval" 
    if [ $angleX -gt 0 ]; then
        #echo "$ABSangleY > 0" 
        state="normal"    
        xinput set-prop "ELAN2514:00 04F3:2975 Pen (0)" --type=float "Coordinate Transformation Matrix" 0 0 0 0 0 0 0 0 0 
        xinput set-prop "SYNA327F:00 06CB:CD4F Touchpad" --type=float "Coordinate Transformation Matrix" 0 0 0 0 0 0 0 0 0 
        xinput set-prop $id --type=float "Coordinate Transformation Matrix" 0 0 0 0 0 0 0 0 0     
    else
        state="inverted"
        xinput set-prop "ELAN2514:00 04F3:2975 Pen (0)" --type=float "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
        xinput set-prop "SYNA327F:00 06CB:CD4F Touchpad" --type=float "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
        xinput set-prop $id --type=float "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
    fi
fi

#echo "current $state prev $statePrev "
if [ $state = $statePrev ]; then 
        echo "">/dev/null
else
    statePrev=$state
    xrandr -o $state
    xrandr  --output eDP-1-1 --rotate $state
fi

sleep 0.5
done



