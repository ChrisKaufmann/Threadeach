#!/usr/bin/perl
use warnings;
use strict;
use Threadeach;

my $start=shift || usage();
my $end=shift || usage();
my $threads=shift || 10;
my $max_groupsize=shift || $end-$start;

print "Running with start=$start, end=$end, $threads threads\n";
if($end-$start > $max_groupsize)
{
	my $tmp_start=$start;
	while($tmp_start < $end)
	{
		my $tmp_end=$tmp_start+$max_groupsize > $end?$end:$tmp_start+$max_groupsize;
		system("./$0 $tmp_start $tmp_end $threads $max_groupsize");
		$tmp_start+=$max_groupsize;
	}
}
else
{
	my @lines=Threadeach::threadsome(\&run_bff,$threads,$start..$end);
}

sub run_bff
{
	my $id=shift;
	my $cookie=$id%$threads;
	my $cmd="bash bff.sh $id cookie$cookie.txt";
	print "$cmd\n";
	system($cmd);
	$id=undef;
	$cookie=undef;
	$cmd=undef;
}
`rm cookie*.txt`;

sub usage
{
	print "usage: $0 <startid> <endid> [Optional: # of threads] [optional: max groupsize]\n";
	exit();
}
