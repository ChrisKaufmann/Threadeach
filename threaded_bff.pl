#!/usr/bin/perl
use warnings;
use strict;
use Threadeach;

my $start=shift || usage();
my $end=shift || usage();
my $threads=shift || 10;

print "Running with start=$start, end=$end, $threads threads\n";
my @lines=Threadeach::threadsome(\&run_bff,$threads,$start..$end);


sub run_bff
{
	my $id=shift;
	my $cookie=$id%$threads;
	my $cmd="bash bff.sh $id cookie$cookie.txt";
	print "$cmd\n";
	system($cmd);
}

sub usage
{
	print "usage: $0 <startid> <endid> [Optional: # of threads]\n";
	exit();
}
