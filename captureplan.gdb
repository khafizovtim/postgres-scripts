set pagination off
set confirm off
set breakpoint pending on
set print repeats 0
set print elements 10240
break standard_ExecutorRun if (unsigned long)queryDesc->plannedstmt->queryId == (unsigned long)$QUERYID
commands
  silent
  set $a=queryDesc
  set $s=NewExplainState()
  call ExplainBeginOutput($s)
  call ExplainPrintPlan($s,$a)
  call ExplainEndOutput($s)
  set print elements  10240
  p ((ExplainState *)$s)->str->data
  continue
end
continue
detach
quit
