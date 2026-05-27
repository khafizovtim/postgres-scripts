#!/bin/bash
JOBIDFILTER=""
JOBID=$1
if [[ $JOBID =~ [0-9]+$ ]]; then
  JOBIDFILTER="/(int64)(uptr(*arg0)) == $JOBID/"
fi
PGCRON_SO=$(pldd $(pgrep -f "postgres.*checkpointer") | grep cron)
trace_file_name=/pgsys/trace/managecrontask.log
nohup stdbuf -oL bpftrace -e'
uprobe:'$PGCRON_SO':ManageCronTask '"${JOBIDFILTER}"'
 {
     printf("%d %ld %ld %u %u %s\n",
      pid,(int64)(uptr(*arg0)),(int64)(uptr(*(arg0+8))),(int32)(uptr(*(arg0+16))), (uint32)(uptr(*(arg0+20))), strftime("%H:%M:%S:%f",nsecs));
  }' 2>/dev/null | rotatelogs -l -L /pgsys/trace/managecrontask.log /pgsys/trace/managecrontask.log.%Y-%m-%d-%H_%M_%S 10M &
