do $$
declare
 lsn1 pg_lsn;
 lsn2 pg_lsn;
begin
 lsn1:=pg_current_wal_flush_lsn();
 perform pg_sleep(10);
 lsn2:=pg_current_wal_flush_lsn();
 RAISE NOTICE 'Wal size: %',pg_size_pretty(lsn2-lsn1);
end;
$$;
