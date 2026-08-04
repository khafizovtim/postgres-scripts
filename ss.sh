walfile="$PGDATA/pg_wal/"$(psql -tAc "SELECT pg_walfile_name(pg_current_wal_lsn() - 16777216)")
pg_waldump $walfile > /tmp/wal
 awk '{print int(substr($8,1,length($8)-1)) " " int(substr($6,1,length($6)-1))}' /tmp/wal | sort -n | awk '{if ($1>0) transact_size[$1] += $2} END {for (xid in transact_size) print xid, transact_size[xid]}' > /tmp/tr.size
total=$(wc -l /tmp/tr.size | cut -d' ' -f1)
less_128=$(awk '$2<128' /tmp/tr.size | wc -l)
more_128_less_256=$(awk '$2>=128 && $2<256' /tmp/tr.size | wc -l)
more_256_less_512=$(awk '$2>=256 && $2<512' /tmp/tr.size | wc -l)
more_512_less_1024=$(awk '$2>=512 && $2<1024' /tmp/tr.size | wc -l)
more_1024_less_2048=$(awk '$2>=1024 && $2<2048' /tmp/tr.size | wc -l)
more_2048_less_4096=$(awk '$2>=2048 && $2<4096' /tmp/tr.size | wc -l)
more_4096=$(awk '$2>=4096' /tmp/tr.size | wc -l)

printf "%-20s %-10s %s\n" "<128" $less_128 $(awk -v a="$less_128" -v b="$total" 'BEGIN{ printf "%.2f%%",100*a/b}')
printf "%-20s %-10s %s\n" ">=128 and <256" $more_128_less_256 $(awk -v a="$more_128_less_256" -v b="$total" 'BEGIN{ printf "%.2f%%",100*a/b}')
printf "%-20s %-10s %s\n" ">=256 and <512" $more_256_less_512 $(awk -v a="$more_256_less_512" -v b="$total" 'BEGIN{ printf "%.2f%%",100*a/b}')
printf "%-20s %-10s %s\n" ">=512 and <1024" $more_512_less_1024 $(awk -v a=$more_512_less_1024 -v b="$total" 'BEGIN{ printf "%.2f%%",100*a/b}')
printf "%-20s %-10s %s\n" ">=1024 and <2048" $more_1024_less_2048 $(awk -v a=$more_1024_less_2048 -v b="$total" 'BEGIN{ printf "%.2f%%",100*a/b}')
printf "%-20s %-10s %s\n" ">=2048 and <4096" $more_2048_less_4096 $(awk -v a=$more_2048_less_4096 -v b="$total" 'BEGIN{ printf "%.2f%%",100*a/b}')
printf "%-20s %-10s %s\n" ">=4096" $more_4096 $(awk -v a=$more_4096 -v b="$total" 'BEGIN{ printf "%.2f%%",100*a/b}')
