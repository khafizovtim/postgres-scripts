#!/bin/bash
if [ -z $1 ]; then
 echo "Usage: w.sh <filename - output of "perf trace -G system.slice/patroni.service -e syscalls:sys_enter_pwrite64 -a" >"
 exit -1
fi
fn=$1
seconds=$((`tail -1 $fn | sed 's/\([[:digit:]]\{1,\}\)\.\([[:digit:]]\{1,\}\).*/\1\2/'`/1000000))
read -r total8k totalother total <<< `grep pg_wal $fn | awk 'BEGIN {total8k=0; totalother=0}{ bs=int(substr($8,1,length($8)-1)); if (bs==8192) total8k+=bs; else totalother+=bs}END{print total8k" "totalother" "total8k+totalother}'`
read -r total8kuniq <<< `grep pg_wal $fn | awk '{print substr($6,1,length($6)-1)" "substr($8,1,length($8)-1)}' | uniq -c | awk 'BEGIN {total=0}{if($3==8192) total+=$3}END{print total}'`

printf "Wal stats:\n"
printf "total bytes:                          %20d\n" $total
printf "total bytes 8k:                       %20d\n" $total8k
printf "total bytes other:                    %20d\n" $totalother
printf "total bytes 8k uniq:                  %20d\n" $total8kuniq
printf "total bytes per sec                   %20d\n" $((total/$seconds))
printf "\n"
printf "total bytes with only uniq 8k writes: %20d\n" $(($totalother+$total8kuniq))
printf "ratio: %.2f\n" $(($total*100/($totalother+$total8kuniq)))e-2
