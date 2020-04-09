#! /bin/bash

# configure GPS options
#
# with the help of : http://www.hhhh.org/wiml/proj/nmeaxor.html
#
# 2000 ms = $PMTK220,2000*1C
# 1500 ms = $PMTK220,1500*1A
# 1000 ms = $PMTK220,1000*1F
#  750 ms = $PMTK220,750*2C
#  500 ms = $PMTK220,500*2B
#  250 ms = $PMTK220,250*29
#  200 ms = $PMTK220,200*2C
#  100 ms = $PMTK220,100*2F

if [ $# -lt 2  ];then
echo "usage: $0 <update time [ms]> <device>"
exit
fi
time=$1;
device=$2
set -x
case $time in

"2000") 
echo \$PMTK220,2000\*1C$'\r' > $device
;;
"1500") 
echo \$PMTK220,1500\*1A$'\r' > $device
;;
"1000") 
echo \$PMTK220,1000\*1F$'\r' > $device
;;
"750")  
echo \$PMTK220,750\*2C$'\r' > $device
;;
"500")  
echo \$PMTK220,500\*2B$'\r' > $device
;;
"250")  
echo \$PMTK220,250\*29$'\r' > $device
;;
"200")  
echo \$PMTK220,200\*2C$'\r' > $device
#printf "\$PMTK220,200*2C$\r" > $device
;;
"100")  
echo \$PMTK220,100\*2F$'\r' > $device
;;
*)
echo "$timer not supported";
exit
;;
esac

#echo \$PMTK220,1000\*1F$'\r' > $device
set +x
