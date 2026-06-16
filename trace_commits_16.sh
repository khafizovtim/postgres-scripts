#!/bin/bash

DURATION=$1

if [[ ! $DURATION =~ [0-9]+$ ]]; then
 echo "Usage ./trace.sh <trace duration in seconds>"
 exit 1
fi

POSTGRES_BINARY=$(readlink /proc/$(pgrep -f "postgres.*checkpointer")/exe)
POSTGRES_BINARY_DEBUG=$(file $POSTGRES_BINARY |  cut -d' ' -f15 | sed 's/.*=\(.\{2\}\)\(.*\),/\/usr\/lib\/debug\/\.build-id\/\1\/\2\.debug/')
SYNCREPWAITFORLSN_ADDR=$(nm $POSTGRES_BINARY_DEBUG | grep SyncRepWaitForLSN.part.0 | cut -d" " -f1)
echo $POSTGRES_BINARY
echo $SYNCREPWAITFORLSN_ADDR
#export BPFTRACE_STRLEN=200

trace_file_name=trace.commits.$(date +%Y%m%d%H%M%S)

timeout "${DURATION}s"  bpftrace -e'

uprobe:'$POSTGRES_BINARY':standard_ExecutorStart
{
        printf("%d query_id: %ld query: %s\n",pid,(uint64)(uptr(*(uptr(*(arg0+8))+8))),str(uptr(*(arg0+16)))  );
}

uprobe:'$POSTGRES_BINARY':CommitTransactionCommand
{
 @commit_time[pid]=nsecs;
 printf("%d %s : commit started in CommitTransactionCommand \n",pid, strftime("%H:%M:%S:%f",nsecs));
}


uprobe:'$POSTGRES_BINARY':CommitTransaction.lto_priv.0
{
 @commit_trans[pid]=nsecs;
 printf("%d %s : CommitTransaction started in CommitTransaction.lto_priv.0 \n",pid, strftime("%H:%M:%S:%f",nsecs));
}

uretprobe:'$POSTGRES_BINARY':CommitTransaction.lto_priv.0
{
 if(@commit_trans[pid]!=0){
  printf("%d %s : CommitTransaction time %lu ns\n",pid,strftime("%H:%M:%S:%f",nsecs),nsecs-@commit_trans[pid]);
  delete(@commit_trans[pid]);
 }
}

uretprobe:'$POSTGRES_BINARY':CommitTransactionCommand
{
 if(@commit_time[pid]!=0){
  printf("%d %s : commit time %lu ns\n",pid,strftime("%H:%M:%S:%f",nsecs),nsecs-@commit_time[pid]);
  delete(@commit_time[pid]);
 }
}


uprobe:'$POSTGRES_BINARY':PreCommit_on_commit_actions
{
 @precommit_time[pid]=nsecs;
 printf("%d %s : entered PreCommit_on_commit_actions\n",pid, strftime("%H:%M:%S:%f",nsecs));
}

uretprobe:'$POSTGRES_BINARY':PreCommit_on_commit_actions
{
 if(@precommit_time[pid]!=0){
     printf("%d %s : PreCommit_on_commit_actions time %lu ns\n",pid, strftime("%H:%M:%S:%f",nsecs),nsecs-@precommit_time[pid]);
     delete(@precommit_time[pid]);
 }
}


uprobe:'$POSTGRES_BINARY':LogLogicalInvalidations
{
  printf("%d %s : entered LogLogicalInvalidations\n",pid, strftime("%H:%M:%S:%f",nsecs));
}

uprobe:'$POSTGRES_BINARY':smgrGetPendingDeletes
{
 printf("%d %s : entered smgrGetPendingDeletes\n",pid, strftime("%H:%M:%S:%f",nsecs));
}

uprobe:'$POSTGRES_BINARY':XactLogCommitRecord
{
 printf("%d %s : entered XactLogCommitRecord\n",pid, strftime("%H:%M:%S:%f",nsecs));
}


uprobe:'$POSTGRES_BINARY':0x'$SYNCREPWAITFORLSN_ADDR'
{
 @syncrepwait[pid]=nsecs;
 printf("%d %s : entered SyncRepWaitForLSN.part.0 \n",pid, strftime("%H:%M:%S:%f",nsecs));
}

uretprobe:'$POSTGRES_BINARY':0x'$SYNCREPWAITFORLSN_ADDR'
{
 if(@syncrepwait[pid]!=0){
  printf("%d %s : exit from SyncRepWaitForLSN.part.0 %lu ns\n",pid,strftime("%H:%M:%S:%f",nsecs),nsecs-@syncrepwait[pid]);
  delete(@syncrepwait[pid]);
 }
}

uprobe:'$POSTGRES_BINARY':standard_ProcessUtility
{
 printf("%d Utility: %s\n",pid,str(uptr(arg1)));
}


uprobe:'$POSTGRES_BINARY':XLogFlush
{
 @xlogflushwait[pid]=nsecs;
}

uretprobe:'$POSTGRES_BINARY':XLogFlush
{
  if(@xlogflushwait[pid]!=0){
  printf("%d %s : XLogFlush ended in %lu ns\n",pid, strftime("%H:%M:%S:%f",nsecs), nsecs-@xlogflushwait[pid]);
  delete(@xlogflushwait[pid]);
 }
}

uprobe:'$POSTGRES_BINARY':XLogWrite
{
 @xlogwritewait[pid]=nsecs;
}

uretprobe:'$POSTGRES_BINARY':XLogWrite
{
  if(@xlogwritewait[pid]!=0){
  printf("%d %s : XLogWrite ended in %lu ns\n",pid, strftime("%H:%M:%S:%f",nsecs), nsecs-@xlogwritewait[pid]);
  delete(@xlogwritewait[pid]);
 }
}

uprobe:'$POSTGRES_BINARY':XLogBackgroundFlush
{
 @xlogbackgroundflush[pid]=nsecs;
}

uretprobe:'$POSTGRES_BINARY':XLogBackgroundFlush
{
  if(@xlogbackgroundflush[pid]!=0){
  printf("%d XLogBackgroundFlush ended in %lu ns\n",pid, nsecs-@xlogbackgroundflush[pid]);
  delete(@xlogbackgroundflush[pid]);
 }
}

END
{
 clear(@commit_time);
 clear(@commit_trans);
 clear(@xlogflushwait);
 clear(@xlogwritewait);
 clear(@xlogbackgroundflush);
 clear(@syncrepwait);
 clear(@precommit_time);
}' -o $trace_file_name  2>/dev/null
