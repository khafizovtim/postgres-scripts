#!/bin/bash
set -u
echo "Longest commits"
trace_file=$1
grep "commit time" $trace_file | sort -n -k6 |tail -20
echo
ckpt_wri_pids=\"$(echo ^$(pgrep -f "[c]heckpointer|[b]ackground writer" -d"|^"))\"
#echo $ckpt_wri_pids
xlf_count=0
xlf_count_1ms=0
xlf_count1_2ms=0
xlf_count2_4ms=0
xlf_count4_8ms=0
xlf_count8_16ms=0
xlf_count16_128ms=0
xlf_count128_1s=0
xlf_count1s=0


syn_count=0
syn_count_1ms=0
syn_count1_2ms=0
syn_count2_4ms=0
syn_count4_8ms=0
syn_count8_16ms=0
syn_count16ms_=0
syn_count16_128ms=0
syn_count128_1s=0
syn_count1s=0

for d in `grep XLogFlush $trace_file | egrep -v $ckpt_wri_pids | cut -d' ' -f5`
do
 xlf_count=$(($xlf_count+1))
 if [ $d -le 1000000 ]; then
  xlf_count_1ms=$(($xlf_count_1ms+1))
  continue
 fi
 if [ $d -gt 1000000 -a $d -le 2000000 ]; then
  xlf_count1_2ms=$(($xlf_count1_2ms+1))
  continue
 fi
 if [ $d -gt 2000000 -a $d -le 4000000 ]; then
  xlf_count2_4ms=$(($xlf_count2_4ms+1))
  continue
 fi
 if [ $d -gt 4000000 -a $d -le 8000000 ]; then
  xlf_count4_8ms=$(($xlf_count4_8ms+1))
  continue
 fi
 if [ $d -gt 8000000 -a $d -le 16000000 ]; then
  xlf_count8_16ms=$(($xlf_count8_16ms+1))
  continue
 fi

 if [ $d -gt 16000000 -a $d -le 128000000 ]; then
  xlf_count16_128ms=$(($xlf_count16_128ms+1))
  continue
 fi
 if [ $d -gt 128000000 -a $d -le 1000000000 ]; then
  xlf_count128_1s=$(($xlf_count128_1s+1))
  continue
 fi
 if [ $d -gt 1000000000 ]; then
   xlf_count1s=$(($xlf_count1s+1))
  continue
 fi

done

echo "XLogFlush count total: "$xlf_count
echo "<1ms count: "$xlf_count_1ms
echo "1-2ms count: "$xlf_count1_2ms
echo "2-4ms count: "$xlf_count2_4ms
echo "4-8ms count: "$xlf_count4_8ms
echo "8-16ms count: "$xlf_count8_16ms
echo "16-128ms count: "$xlf_count16_128ms
echo "128ms-1s count: "$xlf_count128_1s
echo ">1s count:  "$xlf_count1s

echo
for d in `grep SyncRepWaitForLSN.part.0 $trace_file | egrep -v $ckpt_wri_pids | cut -d' ' -f7`
do
 syn_count=$(($syn_count+1))
 if [ $d -le 1000000 ]; then
  syn_count_1ms=$(($syn_count_1ms+1))
  continue
 fi
 if [ $d -gt 1000000 -a $d -le 2000000 ]; then
  syn_count1_2ms=$(($syn_count1_2ms+1))
  continue
 fi
 if [ $d -gt 2000000 -a $d -le 4000000 ]; then
  syn_count2_4ms=$(($syn_count2_4ms+1))
  continue
 fi
 if [ $d -gt 4000000 -a $d -le 8000000 ]; then
  syn_count4_8ms=$(($syn_count4_8ms+1))
  continue
 fi
 if [ $d -gt 8000000 -a $d -le 16000000 ]; then
  syn_count8_16ms=$(($syn_count8_16ms+1))
  continue
 fi
 if [ $d -gt 16000000 -a $d -le 128000000 ]; then
  syn_count16_128ms=$(($syn_count16_128ms+1))
  continue
 fi
 if [ $d -gt 128000000 -a $d -le 1000000000 ]; then
  syn_count128_1s=$(($syn_count128_1s+1))
  continue
 fi
 if [ $d -gt 1000000000 ]; then
   syn_count1s=$(($syn_count1s+1))
  continue
 fi
done

echo "SyncRepWaitForLSN count total: "$syn_count
echo "<1ms count: "$syn_count_1ms
echo "1-2ms count: "$syn_count1_2ms
echo "2-4ms count: "$syn_count2_4ms
echo "4-8ms count: "$syn_count4_8ms
echo "8-16ms count: "$syn_count8_16ms
echo "16-128ms count: "$syn_count16_128ms
echo "128ms-1s count: "$syn_count128_1s
echo ">1s count:  "$syn_count1s
