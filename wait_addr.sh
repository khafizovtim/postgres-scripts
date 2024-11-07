wa=$(gdb -p $1 <<EOF 2>/dev/null | grep uint | cut -d" " -f6
p my_wait_event_info
quit
EOF
)
echo $wa
