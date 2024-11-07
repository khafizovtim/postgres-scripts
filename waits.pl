#!/bin/perl
use strict;
use warnings;

my %wait_events;
my %wait_names;
if ($#ARGV+1!=1) {
 printf("Usage: waits.pl <trace file name>\n");
 exit(-1);
}

my $file = $ARGV[0];
my $fd;
open $fd,'<',$file or die "failed to open trace file";

my $need_print_stack=0;
my $stack="";

while( my $line = <$fd>)  {
    if ($line=~m/^#WAIT.*/){
      if ($need_print_stack){
	print substr($stack,0,-2)."\n";
	$stack="";
	$need_print_stack=0;
       }
      my @s = split(' ',$line);
      if (! exists $wait_events{$s[1]}){
	#print "DEBUG ".$s[1]."\n";
        $wait_events{$s[1]}=$s[2];
        my @out=split(' ',`su - postgres -c "psql -q -d testdb -t  -c \\"select $s[1]||' '||waitevent_by_number($s[1])\\""`);
        $wait_names{$s[1]}=$out[1];
       }
      else{
       $wait_events{$s[1]}+=$s[2]
      }
     print " ".$s[0]." ".$s[1]." ".$wait_names{$s[1]}." ".$s[2]."ns\n";
   }
   elsif ($line=~m/^\s{8}(.*)/){
     $need_print_stack=1;
     $stack=$stack.$1."<-";
   }
  else{
      if ($need_print_stack){
        print substr($stack,0,-2)."\n";
        $stack="";
        $need_print_stack=0;
       }
	  print $line if ! ($line =~m/^$/);
  }
}

close($fd);

printf("\n%s\n","*************************************\nWait events summary:");
my $i;
foreach $i (sort { $wait_events{$a} <=> $wait_events{$b} } keys %wait_events) {
   printf("%-24s %.2fms\n", $wait_names{$i},$wait_events{$i}/1e6);
}

my $t=0;
foreach $i ( keys %wait_events) {
  $t+=$wait_events{$i};
}
printf("%-24s %.2fms\n","Total wait time",$t/1e6)
