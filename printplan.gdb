set print repeats 0
set $s=NewExplainState()
call ExplainBeginOutput($s)
call ExplainPrintPlan($s,$a)
call ExplainEndOutput($s)
set print elements  10240
p ((ExplainState *)$s)->str->data
